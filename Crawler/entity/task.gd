class Idle:
	var target
	var pilot

	func unserialize(_arg):
		pass

	func record():
		pilot.host.tags.remove('tgt')

	func perform():
		pass

	func on_set():
		pilot.priority = 5
		pilot.lifetime = 100

	func on_turn():
		if pilot.lifetime > 0:
			pilot.lifetime -= 1
		elif pilot.lifetime == 0:
			pilot.set_task(pilot.default)
			return false
		return true
	
	func get_class():
		return "idle"

class TileTask extends Idle:
	func on_turn():
		if .on_turn():
			if target == null:
				pilot.set_task(pilot.default)
				return false
			return true

class TargetTask extends Idle:
	func on_turn():
		if .on_turn():
			if target == null or !is_instance_valid(target):
				pilot.set_task(pilot.default)
				return false
			return true

class Pathing extends TileTask:
	class pathnode:
		var parent
		var pos
		var g = 0
		var h = 0
		var f = 0

		func _init(pparent, pnode):
			parent = pparent
			pos = pnode

		func set_h(destination):
			h = pos.difference_to(destination)

		func __str__():
			return pos.__str__()+'/'+str(f)
	var chase = 1
	var open = null
	var closed = []
	var closest = null
	var result = []
	var next_reset = 0
	var heuristic_threshold = 0
	var out_of_reach = false
	var fly = false

	func on_set():
		.on_set()
		out_of_reach = false

	func iterate(node):
		var index = 0
		for k in range(open.size()):
			var v = open[k]
			if v.f < node.f:
				index = k
				node = v
		open.pop_at(index)
		closed.append(node)
		var achieved = node.pos.difference_to(target)
		if achieved == 0:
			return node
		if achieved < closest.pos.difference_to(target):
			closest = node
		var options = node.pos.get_routes(pilot.host.col_mask)
		for route in options:
			var pos = node.pos.get_neighbor(route[0].x, route[0].y)
			var tile_yield = route[1] * 0.5
			if fly:
				tile_yield = 0
			var new = pathnode.new(node, pos)
			new.g = node.g + 1 + tile_yield
			new.set_h(target)
			new.f = new.h + new.g
			if new.h < heuristic_threshold:
				open.append(new)

	func check_loop(loop, pos):
		for i in loop:
			if i.pos == pos:
				return i

	func perform():
		if target == null or pilot.host.pos.difference_to(target) <= 1:
			return true
		if !result.empty():
			var direction = pilot.host.pos.direction_to(result.pop_front())
			pilot.host.action.next_action = ["slide", direction]
			result = []

	func on_turn():
		if .on_turn():
			if result.empty():
				var diff = pilot.host.pos.difference_to(target)
				if diff > 1:
					out_of_reach = false
					var done = null
					if next_reset == 0:
						reset()
						next_reset = 1
					else:
						next_reset += 1
					for _times in range(11):
						if open:
							done = iterate(open[0])
							if done != null:
								break
						else:
							break
#					debug_trace()
					if done == null and next_reset > chase:
						out_of_reach = true
						done = closest
					if done:
						next_reset = 0
						result = [done.pos]
						while done.parent:
							done = done.parent
							if done.pos == pilot.host.pos:
								break
							result.insert(0, done.pos)
				elif diff == 1:
					result = [target]
			return true
	
	func debug_trace():
		for draw in open:
			G.make_particle("Hit", draw.pos)

	func reset():
		var dist = pilot.host.pos.distance_to(target)
		if dist > G.C:
			out_of_reach = true
		heuristic_threshold = dist * 2 + 2
		open = [pathnode.new(null, pilot.host.pos)]
		closed = []
		closest = open[0]
	
	func get_class():
		return "pathing"

class Wander extends Idle:
	func on_set():
		.on_set()
		pilot.lifetime = 100
		pilot.priority = 4

	func random_state():
		pilot.lifetime = G.rng.ir(50, 200)
		pilot.host.action.next_action = ["slide", G.rng.ir(0, 3)*2]

	func on_turn():
		if .on_turn():
			random_state()
			return true
	
	func get_class():
		return "wander"


class Attack extends TargetTask:
	func on_set():
		.on_set()
		pilot.lifetime = -1
		pilot.priority = 1

	func on_turn():
		if .on_turn():
			pilot.move.target = target.pos
			pilot.move.on_turn()
			return true

	func perform():
		if target != null:
			var diff = target.pos.difference_to(pilot.host.pos)
			if diff == 0:
				pilot.host.action.next_action = ["slide", G.rng.ir(0, 3)*2]
			elif !pilot.perform_ability(target):
				if diff == 1:
					pilot.host.action.next_action = ["slide", pilot.host.pos.direction_to(target.pos)]
				else:
					var cards = pilot.host.pos.get_cardinals(1)
					for tile in cards:
						for item in tile.items:
							if item.team == pilot.host.team * -1:
								target = item
								pilot.host.action.next_action = ["slide", pilot.host.pos.direction_to(item.pos)]
					pilot.move.target = target.pos
					pilot.move.perform()

	func get_class():
		return "attack"


class Follow extends TargetTask:
	func on_set():
		.on_set()
		pilot.priority = 3
		target = G.you.host

	func on_turn():
		if .on_turn():
			pilot.move.target = target.pos
			var temp = pilot.move.chase
			pilot.move.chase = 4
			pilot.move.on_turn()
			pilot.move.chase = temp
			return true

	func perform():
		pilot.move.target = target.pos
		pilot.move.perform()
	
	func get_class():
		return "follow"


class Guard extends Pathing:
	func on_set():
		.on_set()
		pilot.lifetime = 50
		target = null

	func on_turn():
		if target == null:
			var host_ab_pos = pilot.host.pos.get_coordinates()
			var guard = pilot.host.dat.get("guard")
			var tile
			if guard:
				var pos = guard.split(',')
				tile = pilot.host.pos.get_neighbor(int(pos[0]) - host_ab_pos[0], int(pos[1]) - host_ab_pos[1])
			else:
				pilot.host.tags.set('guard', 'x' + str(host_ab_pos[0]) + 'y' + str(host_ab_pos[1]))
				tile = pilot.host.pos
			target = tile
		return .on_turn()
	
	func get_class():
		return "guard"

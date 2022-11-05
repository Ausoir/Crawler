var teams = [[], [], []]

func adjust_team(p):
	remove(p)
	add(p)

func get_all():
	return teams[0] + teams[1] + teams[2]

func get_teamed():
	return teams[1] + teams[2]

func get_foe(p):
	var team = p.team
	if team == 1:
		return teams[2]
	elif team == -1:
		return teams[1]
	else:
		return []

func get_ally(p):
	return teams[team_to_index(p.team)]

func remove(p):
	for team in teams:
		team.erase(p)

func add(p):
	teams[team_to_index(p.team)].append(p)

func team_to_index(p):
	if p == -1:
		return 2
	elif p == 1:
		return 1
	return 0

func get_item_by_seed(p):
	if p == -1:
		return G.you.host
	elif p > 0:
		for i in G.census:
			for unit in i:
				if unit.dat.get("seed", 0) == p:
					return unit

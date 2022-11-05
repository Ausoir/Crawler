var name #name of file
var data
var room
var terrainmap
var objectmap
var flip
var rot

func load_vault(p, tmap, objmap):
	name = p
	flip = 0
	rot = 0
	terrainmap = tmap
	objectmap = objmap
	data = G.data.get_json_data("vaults/" + p)
	return data != null

func make_vault(ssd, proom, crop=null):
	room = proom
	var fromx = room[0]
	var fromy = room[1]
	var width = room[2] - fromx
	var height = room[3] - fromy
	for vault_data in data:
		if ssd < vault_data[0]:
			var vault = vault_data[2]
			if crop != null:
				crop = rotcrop(vault, crop, rot)
				var newvault = []
				for y in range(crop[1], crop[1]+height+1):
					var row = ""
					for x in range(crop[0], crop[0]+width+1):
						row += vault[y][x]
					newvault.append(row)
				vault = newvault
			var rotvault = rotate(vault, rot)
			place_vault(rotvault, vault_data[3], fromx, fromy)
			return vault_data[1]

func place_vault(vault, palette, startX, startY):
	var sizeX = room[2]+1
	var sizeY = room[3]+1
	for y in range(sizeY):
		for x in range(sizeX):
			var sX = x
			var sY = y
			if flip == 1:
				sX = (sizeX-1 - x)
				sY = y
			elif flip == 2:
				sX = x
				sY = (sizeY-1 - y)
			elif flip == 3:
				sX = (sizeX-1 - x)
				sY = (sizeY-1 - y)
			var fX = startX + sX
			var fY = startY + sY
			var val = vault[y][x]
			var palet = palette.get(val)
			if palet != null:
				if palet[0] != ' ':
					terrainmap[fY][fX] = palet[0]
				if palet.size() > 1:
					objectmap[fY][fX] = palet[1]
			else:
				palet = G.data.palette_data.get(val)
				if palet != null:
					if palet[0] != ' ':
						terrainmap[fY][fX] = palet[0]
					if palet.size() > 1:
						objectmap[fY][fX] = palet[1]
				elif val != ' ':
					terrainmap[fY][fX] = val

func boundary_dist(vault, x, y):
	var xdist = min(x, len(vault[0])-1-x)
	var ydist = min(y, len(vault)-1-y)
	return min(xdist, ydist)

func rotcrop(vault, crop, dir):
	var sx = vault[0].length() / crop[2] - 1
	var sy = vault.size() / crop[3] - 1
	var r = crop
	if dir >= 6:
		r = [crop[1], sx - crop[0]]
	elif dir >= 4:
		r = [sx - crop[0], sy - crop[1]]
	elif dir >= 2:
		r = [sy - crop[1], crop[0]]
	return [r[0] * crop[2], r[1] * crop[3]]

func rotate(vault, dir):
	var rotvault = []
	var sx = vault[0].length()
	var sy = vault.size()
	if dir >= 6:
		for x in range(sx):
			var nrow = ""
			for y in range(sy):
				nrow += vault[sy-y-1][x]
			rotvault.append(nrow)
	elif dir >= 4:
		for y in range(sy):
			var nrow = ""
			for x in range(sx):
				nrow += vault[sy-y-1][sx-x-1]
			rotvault.append(nrow)
	elif dir >= 2:
		for x in range(sx):
			var nrow = ""
			for y in range(sy):
				nrow += vault[y][sx-x-1]
			rotvault.append(nrow)
	else:
		return vault
	return rotvault

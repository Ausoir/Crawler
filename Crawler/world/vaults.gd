var name #name of file
var palette
var data
var terrainmap
var objectmap
var flip
var rot

func load_vault(p, tmap, omap):
	name = p
	flip = 0
	rot = 0
	terrainmap = tmap
	objectmap = omap
	data = G.data.get_json_data("vaults/" + p)
	return data != null

func make_vault(ssd, room):
	var fromx = room[0]
	var fromy = room[1]
	for vault_data in data:
		if ssd < vault_data[0]:
			var vault = vault_data[2]
			var rotvault = rotate(vault, rot)
			var sx = rotvault[0].length()
			var sy = rotvault.size()
			place_vault(rotvault, fromx, fromy, sx, sy)
			return vault_data[1]

func place_vault(vault, startX, startY, sizeX, sizeY):
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
			if val != ' ':
				var pal = palette.get(val)
				if pal != null:
					if pal[0].length() > 1:
						terrainmap[fY][fX] = G.rng.r_arr(pal[0])
					else:
						terrainmap[fY][fX] = pal[0]
					if pal.size() > 1:
						objectmap[fY][fX] = pal[1]
				else:
					terrainmap[fY][fX] = val

func boundary_dist(vault, x, y):
	var xdist = min(x, len(vault[0])-1-x)
	var ydist = min(y, len(vault)-1-y)
	return min(xdist, ydist)

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

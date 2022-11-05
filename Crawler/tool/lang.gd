static func str_array(items):
	var r = ""
	if items != null:
		var size = items.size()
		for i in range(size):
			var item = items[i]
			var split = item.split(":")
			if split.size() > 1:
				r += split[1] + " ["+split[0].capitalize()
			else:
				r += "["+split[0].capitalize()
			if i == size-1:
				r += "]"
			else:
				r += "],"
	return r

static func str_signed_int(p):
	if p < 0:
		return "-" + str(-p)
	elif p > 0:
		return "+" + str(p)
	return "0"

static func str_percentage(p):
	return str(int(p * 10000)/100.0) + "%"

static func str_expire(time):
	var until = time - G.vars.time
	var hours = int(until / 60)
	var days = int(until / 1440)
	if days > 0:
		return str(days+1) + " days"
	else:
		return str(hours+1) + " hours"

static func str_money(p):
	var dollars = int(p / 100)
	var changes = int(p) % 100
	if changes == 0:
		return "$"+str(dollars)+".00"
	elif int(changes/10) == 0:
		return "$"+str(dollars)+"."+str(changes)+"0"
	return "$"+str(dollars)+"."+str(changes)

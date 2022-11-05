var skills = {}

func learn(skl):
	if !(skl in skills):
		skills[skl] = 0.0
		return true

func unserialize(data):
	for i in data:
		skills[i] = data[i]

func has_skills(list):
	if list != null:
		for i in list:
			var split = i.split(":")
			var skill = skills.get(split[0])
			if skill != null:
				var cap = 1
				if split.size() > 1:
					cap = int(split[1]) * .01
				if skill < cap:
					return false
			else:
				return false
	return true

func gain_xp(skill, p):
	var mood = G.vars.mood
	if skill in skills:
		var xp = p * G.data.vars.skills[skill].mult * mood
		if skill in G.vars.talent:
			var oldskill = skills[skill] 
			skills[skill] += xp * 1.5
			if oldskill < 0.5 != skills[skill] < 0.5:
				G.vars.talent.erase(skill)
		else:
			skills[skill] += xp
		mood = max(0, mood - xp)
	else:
		learn(skill)

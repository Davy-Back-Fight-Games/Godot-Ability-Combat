class_name TeamTargetFilter
extends SkillTargetFilter

@export var allowed_teams: Array[ScriptableEnum] = []
@export var team_property: StringName = &"team"

func accepts_target(_caster: Node, _skill: Resource, target: Node) -> bool:
	if allowed_teams.is_empty():
		return true
	if target == null:
		return false

	var target_team = target.get(team_property)
	if not target_team is ScriptableEnum:
		return false
	return allowed_teams.has(target_team)

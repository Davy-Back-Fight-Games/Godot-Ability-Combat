class_name TeamTargetFilter
extends SkillTargetFilter

const CombatIdentityComponentScript := preload("res://addons/ability_combat/runtime/combat/combat_identity_component.gd")

@export var allowed_teams: Array[ScriptableEnum] = []
@export var team_property: StringName = &"team"

func accepts_target(_caster: Node, _skill: Resource, target: Node) -> bool:
	if allowed_teams.is_empty():
		return true
	if target == null:
		return false

	var identity = CombatIdentityComponentScript.find_for_node(target)
	var target_team = identity.team if identity != null else target.get(team_property)
	if not target_team is ScriptableEnum:
		return false
	return allowed_teams.has(target_team)

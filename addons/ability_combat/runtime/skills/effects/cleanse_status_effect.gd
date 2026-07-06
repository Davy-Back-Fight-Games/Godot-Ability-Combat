class_name CleanseStatusEffect
extends SkillEffect

@export var cleanse_rule: Resource
@export var apply_to_caster: bool = true

func apply(caster: Node, skill: Resource, targets: Array[Node]) -> void:
	if cleanse_rule == null:
		push_warning("CleanseStatusEffect requires a CleanseRule.")
		_log("missing CleanseRule")
		return

	var removed_count := 0
	if apply_to_caster:
		removed_count += _cleanse_node(caster)
	else:
		for target in targets:
			removed_count += _cleanse_node(target)

	if _should_log():
		var skill_label := "<unknown skill>"
		if skill is SkillDefinition:
			skill_label = skill.get_label()
		print("[CleanseStatusEffect] %s removed %s status(es)" % [skill_label, removed_count])

func _cleanse_node(node: Node) -> int:
	var controller = StatusController.find_for_node(node)
	if controller == null:
		push_warning("CleanseStatusEffect could not find StatusController for target.")
		_log("missing StatusController")
		return 0
	return controller.remove_statuses_by_rule(cleanse_rule, StatusController.RemoveReason.CLEANSED).size()

func _log(message: String) -> void:
	if _should_log():
		print("[CleanseStatusEffect] %s" % message)

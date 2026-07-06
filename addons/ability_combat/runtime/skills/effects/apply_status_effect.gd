class_name ApplyStatusEffect
extends SkillEffect

@export var status_definition: StatusDefinition
@export var apply_to_caster: bool = false

func apply(caster: Node, skill: Resource, targets: Array[Node]) -> void:
	if status_definition == null:
		push_warning("ApplyStatusEffect requires a StatusDefinition.")
		_log("missing StatusDefinition")
		return

	var applied_count := 0
	if apply_to_caster:
		if _apply_to_node(caster, caster):
			applied_count += 1
	else:
		for target in targets:
			if _apply_to_node(target, caster):
				applied_count += 1

	if _should_log():
		var skill_label := "<unknown skill>"
		if skill is SkillDefinition:
			skill_label = skill.get_label()
		print("[ApplyStatusEffect] %s applied %s to %s target(s)" % [skill_label, status_definition.get_label(), applied_count])

func _apply_to_node(node: Node, source: Node) -> bool:
	var controller = StatusController.find_for_node(node)
	if controller == null:
		push_warning("ApplyStatusEffect could not find StatusController for target.")
		_log("missing StatusController")
		return false
	return controller.apply_status(status_definition, source) != null

func _log(message: String) -> void:
	if _should_log():
		print("[ApplyStatusEffect] %s" % message)

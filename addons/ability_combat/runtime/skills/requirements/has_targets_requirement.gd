class_name HasTargetsRequirement
extends SkillRequirement

@export var failure_reason: String = "no_targets"

func get_failure_reason(_caster: Node, skill: Resource, targets: Array[Node]) -> String:
	if not targets.is_empty():
		return ""

	if _should_log():
		var skill_label := "<unknown skill>"
		if skill is SkillDefinition:
			skill_label = skill.get_label()
		print("[HasTargetsRequirement] %s blocked: %s" % [skill_label, failure_reason])

	return failure_reason

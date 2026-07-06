class_name ApplyStatChangeEffect
extends SkillEffect

@export var stat: StatId
@export var resource_type: ResourceType
@export var amount: FloatReference
@export var apply_to_caster: bool = true

func apply(caster: Node, skill: Resource, targets: Array[Node]) -> void:
	if stat == null and resource_type == null:
		return

	var change := 0.0
	if amount != null:
		change = amount.get_value()

	var applied_count := 0
	if apply_to_caster:
		if _apply_to_node(caster, change):
			applied_count += 1
	else:
		for target in targets:
			if _apply_to_node(target, change):
				applied_count += 1

	if _should_log():
		var skill_label := "<unknown skill>"
		if skill is SkillDefinition:
			skill_label = skill.get_label()
		print("[ApplyStatChangeEffect] %s applied %s to %s stat target(s)" % [skill_label, change, applied_count])

func _apply_to_node(node: Node, change: float) -> bool:
	var stats_component := StatsComponent.find_for_node(node)
	if stats_component == null:
		return false
	if resource_type != null and stats_component.has_resource(resource_type):
		return stats_component.apply_resource_change(resource_type, change)
	if stat != null and stats_component.has_stat(stat):
		return stats_component.apply_stat_change(stat, change)
	return false

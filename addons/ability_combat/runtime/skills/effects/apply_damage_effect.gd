class_name ApplyDamageEffect
extends SkillEffect

@export var formula: DamageFormula
@export var target_resource: ResourceType
@export var apply_to_caster: bool = false

var _warned_invalid_configuration: bool = false

func apply(caster: Node, skill: Resource, targets: Array[Node]) -> void:
	if not _has_valid_configuration():
		return

	var caster_stats := StatsComponent.find_for_node(caster)
	var applied_count := 0
	if apply_to_caster:
		if _apply_to_node(caster, caster_stats, skill):
			applied_count += 1
	else:
		for target in targets:
			if _apply_to_node(target, caster_stats, skill):
				applied_count += 1

	if _should_log() or _formula_should_log():
		var skill_label := "<unknown skill>"
		if skill is SkillDefinition:
			skill_label = skill.get_label()
		print("[ApplyDamageEffect] %s applied damage to %s target(s)" % [skill_label, applied_count])

func _apply_to_node(node: Node, caster_stats: StatsComponent, skill: Resource) -> bool:
	var target_stats := StatsComponent.find_for_node(node)
	if target_stats == null or not target_stats.has_resource(target_resource):
		return false
	var breakdown := formula.evaluate(caster_stats, target_stats)
	var applied := target_stats.apply_resource_change(target_resource, -breakdown.final_damage)
	if applied and (_should_log() or _formula_should_log()):
		var skill_label := "<unknown skill>"
		if skill is SkillDefinition:
			skill_label = skill.get_label()
		print("[ApplyDamageEffect] %s -> %s %s\n%s" % [skill_label, node.name, breakdown.to_log_line(), breakdown.to_log_text()])
	return applied

func _formula_should_log() -> bool:
	return formula != null and formula.debug_log

func _has_valid_configuration() -> bool:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	if formula == null:
		errors.append("formula is required.")
	else:
		errors.append_array(formula.get_validation_errors())
		warnings.append_array(formula.get_validation_warnings())
	if target_resource == null:
		errors.append("target_resource is required.")

	var messages := PackedStringArray(errors)
	messages.append_array(warnings)
	if not messages.is_empty():
		_warn_invalid_configuration(messages)
	return errors.is_empty()

func _warn_invalid_configuration(errors: PackedStringArray) -> void:
	if _warned_invalid_configuration:
		return
	_warned_invalid_configuration = true
	push_warning("ApplyDamageEffect configuration is invalid: %s" % "; ".join(errors))

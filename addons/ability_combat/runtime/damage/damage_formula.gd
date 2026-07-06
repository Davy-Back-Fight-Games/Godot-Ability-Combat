class_name DamageFormula
extends Resource

@export var damage_type: DamageType
@export var debug_name: String = ""
@export var base_damage: FloatReference
@export var scaling_terms: Array[DamageScalingTerm] = []
@export var minimum_damage: float = 0.0
@export var debug_log: bool = false

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if damage_type == null:
		errors.append("damage_type is required.")
	else:
		for error in damage_type.get_validation_errors():
			errors.append("damage_type: %s" % error)

	var valid_scaling_terms := 0
	for index in scaling_terms.size():
		var term := scaling_terms[index]
		if term == null:
			errors.append("scaling_terms[%s] is null." % index)
			continue
		var term_errors := term.get_validation_errors()
		if term_errors.is_empty():
			valid_scaling_terms += 1
		for error in term_errors:
			errors.append("scaling_terms[%s]: %s" % [index, error])

	return errors

func get_validation_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var valid_scaling_terms := 0
	for term in scaling_terms:
		if term != null and term.get_validation_errors().is_empty():
			valid_scaling_terms += 1
	if base_damage == null and valid_scaling_terms == 0:
		warnings.append("formula has no base_damage and no valid scaling_terms; it will evaluate to zero damage before minimum_damage.")
	return warnings

func is_valid_formula() -> bool:
	return get_validation_errors().is_empty()

func evaluate(caster_stats: StatsComponent, target_stats: StatsComponent) -> DamageBreakdown:
	var breakdown: DamageBreakdown = DamageBreakdown.new()
	breakdown.formula_label = get_formula_label()
	breakdown.damage_type = damage_type
	breakdown.base_damage = _get_base_damage()

	for term in scaling_terms:
		if term == null:
			continue
		var term_damage := term.evaluate(caster_stats)
		breakdown.scaling_damage += term_damage
		breakdown.lines.append(term.get_log_text(caster_stats))

	breakdown.raw_damage = maxf(0.0, breakdown.base_damage + breakdown.scaling_damage)
	breakdown.mitigation_type = _get_mitigation_type()
	breakdown.mitigation_stat = _get_mitigation_stat(breakdown.mitigation_type)
	breakdown.mitigation_value = _get_mitigation_value(target_stats, breakdown.mitigation_stat)
	breakdown.mitigation_multiplier = _get_mitigation_multiplier(breakdown.mitigation_value, breakdown.mitigation_type)
	breakdown.final_damage = maxf(minimum_damage, breakdown.raw_damage * breakdown.mitigation_multiplier)
	breakdown.final_damage = maxf(0.0, breakdown.final_damage)
	return breakdown

func get_formula_label() -> String:
	if debug_name.strip_edges() != "":
		return debug_name.strip_edges()
	if resource_path != "":
		return resource_path.get_file().get_basename()
	return "<unnamed formula>"

func _get_base_damage() -> float:
	if base_damage == null:
		return 0.0
	return base_damage.get_value()

func _get_mitigation_type() -> MitigationType:
	if damage_type == null:
		return null
	return damage_type.mitigation_type

func _get_mitigation_stat(type: MitigationType) -> StatId:
	if type == null or type.ignores_mitigation:
		return null
	return type.mitigation_stat

func _get_mitigation_value(target_stats: StatsComponent, stat: StatId) -> float:
	if target_stats == null or stat == null:
		return 0.0
	return target_stats.get_stat_value(stat, 0.0)

func _get_mitigation_multiplier(resistance: float, type: MitigationType) -> float:
	if type != null and type.ignores_mitigation:
		return 1.0
	if resistance >= 0.0:
		return 100.0 / (100.0 + resistance)
	return 2.0 - (100.0 / (100.0 - resistance))

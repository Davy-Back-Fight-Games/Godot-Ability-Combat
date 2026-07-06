class_name DamageBreakdown
extends RefCounted

var damage_type: DamageType
var base_damage: float = 0.0
var scaling_damage: float = 0.0
var raw_damage: float = 0.0
var mitigation_type: MitigationType
var mitigation_stat: StatId
var mitigation_value: float = 0.0
var mitigation_multiplier: float = 1.0
var final_damage: float = 0.0
var lines: PackedStringArray = PackedStringArray()
var formula_label: String = ""

func get_formula_label() -> String:
	if formula_label.strip_edges() == "":
		return "<unknown formula>"
	return formula_label.strip_edges()

func to_log_line() -> String:
	return "formula=%s type=%s base=%s scaling=%s raw=%s mitigation=%s stat=%s value=%s multiplier=%s final=%s" % [
		get_formula_label(),
		_get_damage_type_label(),
		base_damage,
		scaling_damage,
		raw_damage,
		_get_mitigation_type_label(),
		_get_mitigation_stat_label(),
		mitigation_value,
		mitigation_multiplier,
		final_damage,
	]

func to_log_text() -> String:
	var output := PackedStringArray()
	output.append("formula=%s" % get_formula_label())
	output.append("damage: type=%s base=%s scaling=%s raw=%s" % [_get_damage_type_label(), base_damage, scaling_damage, raw_damage])
	output.append("mitigation: type=%s stat=%s value=%s multiplier=%s" % [_get_mitigation_type_label(), _get_mitigation_stat_label(), mitigation_value, mitigation_multiplier])
	output.append("final: damage=%s" % final_damage)
	for line in lines:
		output.append("scaling: %s" % line)
	return "\n".join(output)

func _get_damage_type_label() -> String:
	return _get_label(damage_type)

func _get_mitigation_type_label() -> String:
	return _get_label(mitigation_type)

func _get_mitigation_stat_label() -> String:
	if mitigation_stat == null:
		return "<none>"
	return mitigation_stat.get_label()

func _get_label(resource: ScriptableEnum) -> String:
	if resource == null:
		return "<none>"
	return resource.get_label()

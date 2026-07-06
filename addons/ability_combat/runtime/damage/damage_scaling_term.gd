class_name DamageScalingTerm
extends Resource

@export var source_stat: StatId
@export var ratio: float = 1.0
@export var label: String = ""

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if source_stat == null:
		errors.append("source_stat is required.")
	return errors

func evaluate(source_stats: StatsComponent) -> float:
	if source_stats == null or source_stat == null:
		return 0.0
	return source_stats.get_stat_value(source_stat, 0.0) * ratio

func get_log_text(source_stats: StatsComponent) -> String:
	var stat_label := "<no stat>"
	var stat_value := 0.0
	if source_stat != null:
		stat_label = source_stat.get_label()
	if source_stats != null and source_stat != null:
		stat_value = source_stats.get_stat_value(source_stat, 0.0)
	var term_label := label
	if term_label == "":
		term_label = stat_label
	return "%s: %s * %s = %s" % [term_label, stat_value, ratio, evaluate(source_stats)]

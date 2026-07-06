class_name SkillCost
extends Resource

@export var resource_type: ResourceType
@export var amount: FloatReference
@export var debug_log: bool = false

func can_pay() -> bool:
	var cost := get_amount()
	return cost <= 0.0

func can_pay_context(context: SkillCastContext) -> bool:
	var cost := get_amount()
	if cost <= 0.0:
		return true

	var stats_component := _get_stats_component(context)
	if stats_component != null and resource_type != null:
		if stats_component.has_resource(resource_type):
			return stats_component.can_pay_resource(resource_type, cost)
		if resource_type.has_current_stat() and stats_component.has_stat(resource_type.current_stat):
			return stats_component.get_stat_value(resource_type.current_stat) >= cost

	return false

func pay() -> bool:
	if not can_pay():
		_log("cannot pay")
		return false

	var cost := get_amount()
	_log("paid %s" % cost)
	return true

func pay_context(context: SkillCastContext) -> bool:
	if not can_pay_context(context):
		_log("cannot pay")
		return false

	var cost := get_amount()
	var stats_component := _get_stats_component(context)
	if cost > 0.0 and stats_component != null and resource_type != null:
		if stats_component.has_resource(resource_type):
			var paid := stats_component.try_pay_resource(resource_type, cost)
			if paid:
				_log("paid %s" % cost)
			return paid
		if resource_type.has_current_stat() and stats_component.has_stat(resource_type.current_stat):
			stats_component.apply_stat_change(resource_type.current_stat, -cost)
			_log("paid %s" % cost)
			return true

	if cost <= 0.0:
		return pay()

	_log("cannot pay")
	return false

func get_amount() -> float:
	if amount == null:
		return 0.0
	return amount.get_value()

func get_resource_label() -> String:
	if resource_type == null:
		return "Resource"
	return resource_type.get_label()

func _get_stats_component(context: SkillCastContext) -> StatsComponent:
	if context == null or context.caster == null:
		return null
	return StatsComponent.find_for_node(context.caster)

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillCost] %s" % message)

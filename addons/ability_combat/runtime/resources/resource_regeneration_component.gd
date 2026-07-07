class_name ResourceRegenerationComponent
extends Node

@export var stats_component_path: NodePath = NodePath("../StatsComponent")
@export var rules: Array[ResourceRegenerationRule] = []
@export var enabled: bool = true
@export var use_physics_process: bool = false
@export var debug_log: bool = false

var _stats_component: StatsComponent
var _rule_states: Array[Dictionary] = []

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	call_deferred("_initialize")

func _process(delta: float) -> void:
	_process_regeneration(delta)

func _physics_process(delta: float) -> void:
	_process_regeneration(delta)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if _get_stats_component() == null:
		errors.append("ResourceRegenerationComponent requires a StatsComponent.")
	for index in rules.size():
		var rule := rules[index]
		if rule == null:
			errors.append("ResourceRegenerationComponent rules[%s] is null." % index)
			continue
		for error in rule.get_validation_errors(_get_stats_component()):
			errors.append("ResourceRegenerationComponent rules[%s]: %s" % [index, error])
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

func reset_regeneration_state() -> void:
	_ensure_rule_states()
	for index in rules.size():
		var rule := rules[index]
		if rule != null and rule.strategy != null:
			rule.strategy.reset_regeneration_state(_rule_states[index])
		else:
			_rule_states[index].clear()

func _initialize() -> void:
	_stats_component = _resolve_stats_component()
	_ensure_rule_states()
	reset_regeneration_state()
	_warn_validation_errors()
	set_process(not use_physics_process)
	set_physics_process(use_physics_process)

func _process_regeneration(delta: float) -> void:
	if not enabled or delta <= 0.0:
		return

	var stats_component := _get_stats_component()
	if stats_component == null:
		return

	_ensure_rule_states()
	for index in rules.size():
		_apply_rule(index, delta, stats_component)

func _apply_rule(index: int, delta: float, stats_component: StatsComponent) -> void:
	var rule := rules[index]
	if rule == null or not rule.enabled:
		return
	if rule.resource_type == null or rule.strategy == null:
		return
	if not stats_component.has_resource(rule.resource_type):
		return
	if rule.only_when_below_max and _is_resource_full(stats_component, rule.resource_type):
		return

	var amount := rule.strategy.get_regeneration_amount(delta, stats_component, rule, _rule_states[index])
	if not is_finite(amount) or amount <= 0.0:
		return

	if stats_component.apply_resource_change(rule.resource_type, amount):
		_log("%s regenerated %s" % [rule.get_label(), amount])

func _is_resource_full(stats_component: StatsComponent, resource_type: ResourceType) -> bool:
	return stats_component.get_resource_current(resource_type) >= stats_component.get_resource_max(resource_type)

func _get_stats_component() -> StatsComponent:
	if _stats_component != null:
		return _stats_component
	_stats_component = _resolve_stats_component()
	return _stats_component

func _resolve_stats_component() -> StatsComponent:
	if not stats_component_path.is_empty():
		var stats_component := get_node_or_null(stats_component_path) as StatsComponent
		if stats_component != null:
			return stats_component
	return StatsComponent.find_for_node(self)

func _ensure_rule_states() -> void:
	while _rule_states.size() < rules.size():
		_rule_states.append({})
	while _rule_states.size() > rules.size():
		_rule_states.remove_at(_rule_states.size() - 1)

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("ResourceRegenerationComponent validation: %s" % error)

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[ResourceRegenerationComponent] %s" % message)

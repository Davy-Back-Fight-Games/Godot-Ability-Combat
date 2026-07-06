class_name StatsComponent
extends Node

@export var stat_block_template: StatBlock

var stat_block: StatBlock
var _warned_resource_types: Array[ResourceType] = []
var _warned_missing_resource_types: Array[ResourceType] = []

func _ready() -> void:
	if stat_block_template == null:
		push_warning("StatsComponent requires stat_block_template.")
		return
	_warn_template_validation_errors()
	stat_block = stat_block_template.duplicate_runtime()
	if stat_block == null:
		push_warning("StatsComponent failed to duplicate stat_block_template.")

func has_stat(id: StatId) -> bool:
	return stat_block != null and stat_block.has_stat(id)

func get_stat_value(id: StatId, default_value: float = 0.0) -> float:
	if stat_block == null:
		return default_value
	return stat_block.get_value(id, default_value)

func set_stat_value(id: StatId, value: float) -> bool:
	return stat_block != null and stat_block.set_value(id, value)

func apply_stat_change(id: StatId, amount: float) -> bool:
	return stat_block != null and stat_block.apply_change(id, amount)

func has_resource(resource_type: ResourceType) -> bool:
	if stat_block == null or resource_type == null:
		return false
	var errors := resource_type.get_validation_errors()
	if not errors.is_empty():
		_warn_invalid_resource_type(resource_type, errors)
		return false
	var has_current := stat_block.has_stat(resource_type.current_stat)
	var has_max := stat_block.has_stat(resource_type.max_stat)
	if not has_current or not has_max:
		_warn_missing_resource_stats(resource_type, has_current, has_max)
	return has_current and has_max

func get_resource_current(resource_type: ResourceType, default_value: float = 0.0) -> float:
	if not has_resource(resource_type):
		return default_value
	return stat_block.get_value(resource_type.current_stat, default_value)

func get_resource_max(resource_type: ResourceType, default_value: float = 0.0) -> float:
	if not has_resource(resource_type):
		return default_value
	return stat_block.get_value(resource_type.max_stat, default_value)

func set_resource_current(resource_type: ResourceType, value: float) -> bool:
	return has_resource(resource_type) and stat_block.set_resource_current(resource_type, value)

func apply_resource_change(resource_type: ResourceType, amount: float) -> bool:
	return has_resource(resource_type) and stat_block.apply_resource_change(resource_type, amount)

func can_pay_resource(resource_type: ResourceType, amount: float) -> bool:
	if stat_block == null:
		return false
	if amount <= 0.0:
		return true
	return has_resource(resource_type) and stat_block.get_resource_current(resource_type) >= amount

func try_pay_resource(resource_type: ResourceType, amount: float) -> bool:
	return stat_block != null and stat_block.try_pay_resource(resource_type, amount)

func reset_to_initial_values() -> void:
	if stat_block != null:
		stat_block.reset_to_initial_values()

static func find_for_node(node: Node) -> StatsComponent:
	if node == null:
		return null
	if node is StatsComponent:
		return node
	for child in node.get_children():
		if child is StatsComponent:
			return child
	var parent := node.get_parent()
	if parent != null:
		if parent is StatsComponent:
			return parent
		for child in parent.get_children():
			if child is StatsComponent:
				return child
	return null

func _warn_template_validation_errors() -> void:
	var errors := stat_block_template.get_validation_errors()
	for error in errors:
		push_warning("StatsComponent stat_block_template validation: %s" % error)

func _warn_invalid_resource_type(resource_type: ResourceType, errors: PackedStringArray) -> void:
	if not is_node_ready() or resource_type in _warned_resource_types:
		return
	_warned_resource_types.append(resource_type)
	push_warning("StatsComponent resource '%s' is invalid: %s" % [resource_type.get_label(), "; ".join(errors)])

func _warn_missing_resource_stats(resource_type: ResourceType, has_current: bool, has_max: bool) -> void:
	if not is_node_ready() or resource_type in _warned_missing_resource_types:
		return
	_warned_missing_resource_types.append(resource_type)
	var missing := PackedStringArray()
	if not has_current:
		missing.append(resource_type.current_stat.get_label())
	if not has_max:
		missing.append(resource_type.max_stat.get_label())
	push_warning("StatsComponent stat_block is missing stat(s) for resource '%s': %s" % [resource_type.get_label(), ", ".join(missing)])

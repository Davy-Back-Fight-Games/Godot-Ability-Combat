class_name LifeStateComponent
extends Node

signal health_changed(current: float, max: float)
signal died(owner: Node)
signal revived(owner: Node)
signal life_state_changed(alive: bool)

@export var stats_component_path: NodePath = NodePath("../StatsComponent")
@export var health_resource_type: ResourceType
@export var starts_alive: bool = true
@export var required_health_resource: bool = false
@export var debug_log: bool = false

@onready var _stats_component: StatsComponent = get_node_or_null(stats_component_path) as StatsComponent

var _current_health_stat: StatValue
var _alive: bool = true

func _ready() -> void:
	_alive = starts_alive
	call_deferred("_initialize")

func _exit_tree() -> void:
	_unbind_health_stat()

func _initialize() -> void:
	_warn_validation_errors()
	_bind_health_stat()
	if has_health_resource():
		_on_health_changed(get_current_health())
	else:
		_emit_life_state_if_changed(starts_alive)

func is_alive() -> bool:
	if not has_health_resource():
		return _alive
	return get_current_health() > 0.0

func is_dead() -> bool:
	return not is_alive()

func get_current_health() -> float:
	var stats_component := _get_stats_component()
	if health_resource_type == null or stats_component == null:
		return 0.0
	return stats_component.get_resource_current(health_resource_type)

func get_max_health() -> float:
	var stats_component := _get_stats_component()
	if health_resource_type == null or stats_component == null:
		return 0.0
	return stats_component.get_resource_max(health_resource_type)

func set_current_health(value: float) -> bool:
	var stats_component := _get_stats_component()
	if health_resource_type == null or stats_component == null:
		return false
	return stats_component.set_resource_current(health_resource_type, value)

func has_health_resource() -> bool:
	var stats_component := _get_stats_component()
	return health_resource_type != null and stats_component != null and stats_component.has_resource(health_resource_type)

func refresh_from_stats() -> void:
	if has_health_resource():
		_on_health_changed(get_current_health())

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if required_health_resource and health_resource_type == null:
		errors.append("LifeStateComponent requires health_resource_type.")
	if required_health_resource and _get_stats_component() == null:
		errors.append("LifeStateComponent requires a StatsComponent.")
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

static func find_for_node(node: Node):
	if node == null:
		return null
	if node is LifeStateComponent:
		return node

	for child in node.get_children():
		if child is LifeStateComponent:
			return child

	var parent := node.get_parent()
	if parent != null:
		if parent is LifeStateComponent:
			return parent
		for child in parent.get_children():
			if child is LifeStateComponent:
				return child

	return null

func _bind_health_stat() -> void:
	_unbind_health_stat()
	if health_resource_type == null:
		return
	_current_health_stat = _get_health_stat(health_resource_type.current_stat)
	if _current_health_stat != null and not _current_health_stat.value_changed.is_connected(_on_health_changed):
		_current_health_stat.value_changed.connect(_on_health_changed)

func _unbind_health_stat() -> void:
	if _current_health_stat != null and _current_health_stat.value_changed.is_connected(_on_health_changed):
		_current_health_stat.value_changed.disconnect(_on_health_changed)
	_current_health_stat = null

func _on_health_changed(value: float) -> void:
	if not has_health_resource():
		return
	var max_health := get_max_health()
	var clamped_value := clampf(value, 0.0, max_health)
	if not is_equal_approx(value, clamped_value):
		set_current_health(clamped_value)
		return

	health_changed.emit(clamped_value, max_health)
	_emit_life_state_if_changed(clamped_value > 0.0)

func _emit_life_state_if_changed(alive: bool) -> void:
	if _alive == alive:
		return
	_alive = alive
	life_state_changed.emit(_alive)
	if _alive:
		revived.emit(owner)
	else:
		died.emit(owner)

func _get_health_stat(id: StatId) -> StatValue:
	var stats_component := _get_stats_component()
	if stats_component == null or stats_component.stat_block == null:
		return null
	return stats_component.stat_block.get_stat(id)

func _get_stats_component() -> StatsComponent:
	if _stats_component != null:
		return _stats_component
	if not stats_component_path.is_empty():
		_stats_component = get_node_or_null(stats_component_path) as StatsComponent
	if _stats_component != null:
		return _stats_component
	return StatsComponent.find_for_node(self)

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("LifeStateComponent validation: %s" % error)

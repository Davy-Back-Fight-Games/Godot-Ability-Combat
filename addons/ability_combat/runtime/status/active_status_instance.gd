class_name ActiveStatusInstance
extends RefCounted

var id: int = 0
var definition: StatusDefinition
var source: Node
var target: Node
var controller: Node
var remaining_duration: float = 0.0
var initial_duration: float = 0.0
var stacks: int = 1
var applied_time_msec: int = 0
var last_refresh_time_msec: int = 0
var metadata: Dictionary = {}
var module_state: Dictionary = {}

func initialize(status_definition: StatusDefinition, source_node: Node, status_controller: Node, instance_id: int) -> void:
	id = instance_id
	definition = status_definition
	source = source_node
	controller = status_controller
	target = status_controller.get_parent() if status_controller != null else null
	initial_duration = definition.get_duration() if definition != null else 0.0
	remaining_duration = initial_duration
	stacks = 1
	applied_time_msec = Time.get_ticks_msec()
	last_refresh_time_msec = applied_time_msec

func tick(delta: float) -> void:
	if definition != null and definition.is_timed():
		remaining_duration = maxf(remaining_duration - delta, 0.0)

func is_expired() -> bool:
	return definition != null and definition.is_timed() and remaining_duration <= 0.0

func refresh(status_definition: StatusDefinition, source_node: Node) -> void:
	definition = status_definition
	source = source_node
	initial_duration = definition.get_duration() if definition != null else 0.0
	remaining_duration = initial_duration
	last_refresh_time_msec = Time.get_ticks_msec()

func refresh_duration(status_definition: StatusDefinition, source_node: Node) -> void:
	source = source_node
	initial_duration = status_definition.get_duration() if status_definition != null else 0.0
	remaining_duration = initial_duration
	last_refresh_time_msec = Time.get_ticks_msec()

func extend_duration(status_definition: StatusDefinition, source_node: Node) -> void:
	source = source_node
	var added_duration := status_definition.get_duration() if status_definition != null else 0.0
	initial_duration = remaining_duration + added_duration
	remaining_duration += added_duration
	last_refresh_time_msec = Time.get_ticks_msec()

func add_stack(amount := 1) -> int:
	return set_stacks(stacks + amount)

func set_stacks(value) -> int:
	var max_stacks := definition.max_stacks if definition != null else 1
	stacks = clampi(int(value), 0, max_stacks)
	last_refresh_time_msec = Time.get_ticks_msec()
	return stacks

func remove_stack(amount := 1) -> int:
	return set_stacks(stacks - amount)

func has_type(type) -> bool:
	return definition != null and type != null and definition.status_type == type

func has_category(category) -> bool:
	return definition != null and definition.has_category(category)

func has_tag(tag) -> bool:
	return definition != null and definition.has_tag(tag)

func get_label() -> String:
	if definition == null:
		return "<unknown status>"
	return definition.get_label()

func get_normalized_remaining() -> float:
	if definition == null or not definition.is_timed() or initial_duration <= 0.0:
		return 0.0
	return clampf(remaining_duration / initial_duration, 0.0, 1.0)

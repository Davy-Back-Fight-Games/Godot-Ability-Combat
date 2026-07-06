class_name StatusController
extends Node

enum RemoveReason { EXPIRED, REPLACED, CLEANSED, DISPELLED, MANUAL, DEATH }

signal status_applied(instance)
signal status_refreshed(instance)
signal status_stack_changed(instance, old_stacks, new_stacks)
signal status_removed(instance, reason)
signal status_changed

@export var debug_log: bool = false
@export var process_statuses: bool = true

var _active_instances: Array = []
var _next_instance_id: int = 1

func _process(delta: float) -> void:
	if not process_statuses:
		return
	for i in range(_active_instances.size() - 1, -1, -1):
		var instance = _active_instances[i]
		instance.tick(delta)
		_call_modules(instance, "on_tick", [delta])
		if instance.is_expired():
			_remove_instance_at(i, RemoveReason.EXPIRED)

func apply_status(definition: StatusDefinition, source: Node = null):
	if definition == null:
		push_warning("StatusController cannot apply null StatusDefinition.")
		return null

	if definition.is_instant():
		var instant = _create_instance(definition, source)
		remove_status(instant, RemoveReason.EXPIRED)
		return instant

	var existing = _find_matching_instance(definition)
	match definition.stacking_policy:
		StatusDefinition.StackingPolicy.STACK_INDEPENDENTLY:
			return _create_instance(definition, source)
		StatusDefinition.StackingPolicy.IGNORE_IF_MATCH:
			if existing != null:
				_log("ignore if match: ignored %s because %s is already active" % [definition.get_label(), existing.get_label()], definition)
				return null
			return _create_instance(definition, source)
		StatusDefinition.StackingPolicy.EXTEND_MATCH:
			if existing != null:
				_extend_instance(existing, definition, source)
				return existing
			return _create_instance(definition, source)
		StatusDefinition.StackingPolicy.REFRESH_MATCH:
			if existing != null:
				_refresh_instance_duration(existing, definition, source)
				return existing
			return _create_instance(definition, source)
		StatusDefinition.StackingPolicy.ADD_STACK:
			if existing != null:
				_add_stack_to_instance(existing, definition, source)
				return existing
			return _create_instance(definition, source)
		_:
			if existing != null:
				_replace_instance(existing, definition, source)
				return existing
			return _create_instance(definition, source)

func remove_status(instance, reason: RemoveReason = RemoveReason.MANUAL) -> bool:
	var index := _active_instances.find(instance)
	if index == -1:
		return false
	_remove_instance_at(index, reason)
	return true

func remove_statuses_by_rule(rule, reason: RemoveReason = RemoveReason.CLEANSED) -> Array:
	if rule == null:
		return []
	var matches := []
	for instance in _active_instances:
		if rule.matches(instance):
			matches.append(instance)
	matches = rule.sort_instances(matches)

	var removed := []
	var limit := matches.size() if rule.max_removed <= 0 else mini(rule.max_removed, matches.size())
	for i in range(limit):
		var instance = matches[i]
		if rule.stack_removal_mode == CleanseRule.StackRemovalMode.REMOVE_ONE_STACK and instance.stacks > 1:
			var old_stacks: int = instance.stacks
			instance.remove_stack(1)
			_emit_stack_changed(instance, old_stacks, instance.stacks)
		else:
			remove_status(instance, reason)
		removed.append(instance)
	return removed

func clear_all(reason: RemoveReason = RemoveReason.MANUAL) -> void:
	for i in range(_active_instances.size() - 1, -1, -1):
		_remove_instance_at(i, reason)

func get_active_statuses() -> Array:
	return _active_instances.duplicate()

func has_status_type(type: StatusType) -> bool:
	for instance in _active_instances:
		if instance.has_type(type):
			return true
	return false

func has_status_category(category: StatusCategory) -> bool:
	for instance in _active_instances:
		if instance.has_category(category):
			return true
	return false

func has_status_tag(tag: StatusTag) -> bool:
	for instance in _active_instances:
		if instance.has_tag(tag):
			return true
	return false

func get_statuses_by_type(type: StatusType) -> Array:
	return _filter_statuses(func(instance): return instance.has_type(type))

func get_statuses_by_category(category: StatusCategory) -> Array:
	return _filter_statuses(func(instance): return instance.has_category(category))

func get_statuses_by_tag(tag: StatusTag) -> Array:
	return _filter_statuses(func(instance): return instance.has_tag(tag))

func can_move() -> bool:
	for instance in _active_instances:
		if instance.definition == null:
			continue
		for module in instance.definition.modules:
			if module != null and not module.can_move(instance, self):
				return false
	return true

func get_movement_speed_multiplier() -> float:
	var multiplier := 1.0
	for instance in _active_instances:
		if instance.definition == null:
			continue
		for module in instance.definition.modules:
			if module != null:
				multiplier *= module.get_movement_speed_multiplier(instance, self)
	return multiplier

func can_cast_skill(context: Dictionary = {}) -> bool:
	for instance in _active_instances:
		if instance.definition == null:
			continue
		for module in instance.definition.modules:
			if module != null and not module.can_cast_skill(instance, self, context):
				return false
	return true

func get_cast_block_reason(context: Dictionary = {}) -> String:
	for instance in _active_instances:
		if instance.definition == null:
			continue
		for module in instance.definition.modules:
			if module == null or module.can_cast_skill(instance, self, context):
				continue
			var reason: String = module.get_cast_block_reason(instance, self, context)
			if reason != "":
				return reason
	return ""

static func find_for_node(node: Node, debug: bool = false) -> StatusController:
	if node == null:
		return null
	if node is StatusController:
		return node

	var current := node
	while current != null:
		var controller := _get_receiver_controller(current)
		if controller != null:
			_find_log(debug, node, "resolved through %s" % current.get_path())
			return controller

		for child in current.get_children():
			controller = _get_receiver_controller(child)
			if controller != null:
				_find_log(debug, node, "resolved through %s" % child.get_path())
				return controller

		current = current.get_parent()

	_find_log(debug, node, "no StatusReceiver found")
	return null

static func _get_receiver_controller(node: Node) -> StatusController:
	if node is StatusReceiver:
		return node.get_status_controller()
	return null

static func _find_log(enabled: bool, origin: Node, message: String) -> void:
	if not enabled and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	var origin_path := "<null>"
	if origin != null:
		origin_path = str(origin.get_path())
	print("[StatusController.find_for_node] %s: %s" % [origin_path, message])

func _find_matching_instance(definition: StatusDefinition):
	var stack_key = definition.get_stack_key()
	if stack_key == null:
		return null
	for instance in _active_instances:
		if instance.definition != null and instance.definition.get_stack_key() == stack_key:
			return instance
	return null

func _create_instance(definition: StatusDefinition, source: Node):
	var instance = ActiveStatusInstance.new()
	instance.initialize(definition, source, self, _next_instance_id)
	_next_instance_id += 1
	_active_instances.append(instance)
	_call_modules(instance, "on_apply")
	_log("applied %s for %.2fs" % [instance.get_label(), instance.remaining_duration], definition)
	status_applied.emit(instance)
	status_changed.emit()
	return instance

func _replace_instance(instance, definition: StatusDefinition, source: Node) -> void:
	_call_modules(instance, "on_remove", [RemoveReason.REPLACED])
	instance.refresh(definition, source)
	_call_modules(instance, "on_apply")
	_log("replace match: replaced %s for %.2fs" % [instance.get_label(), instance.remaining_duration], definition)
	status_refreshed.emit(instance)
	status_changed.emit()

func _refresh_instance_duration(instance, definition: StatusDefinition, source: Node) -> void:
	instance.refresh_duration(definition, source)
	_call_modules(instance, "on_refresh")
	_log("refresh match: refreshed %s duration to %.2fs" % [instance.get_label(), instance.remaining_duration], definition)
	status_refreshed.emit(instance)
	status_changed.emit()

func _extend_instance(instance, definition: StatusDefinition, source: Node) -> void:
	var added_duration := definition.get_duration()
	instance.extend_duration(definition, source)
	_call_modules(instance, "on_refresh")
	_log("extend match: extended %s by %.2fs to %.2fs" % [instance.get_label(), added_duration, instance.remaining_duration], definition)
	status_refreshed.emit(instance)
	status_changed.emit()

func _add_stack_to_instance(instance, definition: StatusDefinition, source: Node) -> void:
	instance.source = source
	if definition.refresh_duration_on_stack:
		instance.refresh_duration(definition, source)
	var old_stacks: int = instance.stacks
	instance.add_stack(1)
	_call_modules(instance, "on_refresh")
	if instance.stacks != old_stacks:
		_emit_stack_changed(instance, old_stacks, instance.stacks)
	_log("add stack: %s stacks %d/%d" % [instance.get_label(), instance.stacks, definition.max_stacks], definition)
	status_refreshed.emit(instance)
	status_changed.emit()

func _remove_instance_at(index: int, reason: RemoveReason) -> void:
	var instance = _active_instances[index]
	_active_instances.remove_at(index)
	_call_modules(instance, "on_remove", [reason])
	_log("removed %s" % instance.get_label(), instance.definition)
	status_removed.emit(instance, reason)
	status_changed.emit()

func _emit_stack_changed(instance, old_stacks: int, new_stacks: int) -> void:
	_call_modules(instance, "on_stack_changed", [old_stacks, new_stacks])
	status_stack_changed.emit(instance, old_stacks, new_stacks)
	status_changed.emit()

func _call_modules(instance, method: StringName, args: Array = []) -> void:
	if instance == null or instance.definition == null:
		return
	for module in instance.definition.modules:
		if module != null and module.has_method(method):
			module.callv(method, [instance, self] + args)

func _filter_statuses(predicate: Callable) -> Array:
	var results := []
	for instance in _active_instances:
		if predicate.call(instance):
			results.append(instance)
	return results

func _log(message: String, definition: StatusDefinition = null) -> void:
	var definition_debug := definition != null and definition.debug_log
	if not debug_log and not definition_debug and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[StatusController] %s" % message)

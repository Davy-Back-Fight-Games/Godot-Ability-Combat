class_name SkillCaster
extends Node

signal skill_started(skill: SkillDefinition, slot_index: int)
signal skill_failed(skill: SkillDefinition, slot_index: int, reason: String)
signal skill_finished(skill: SkillDefinition, slot_index: int)
signal cooldown_started(skill: SkillDefinition, slot_index: int, seconds: float)
signal slot_assignment_changed(slot_index: int, assignment: SkillSlotAssignment)
signal slot_layout_changed(layout: SkillSlotLayout)
signal slot_validation_failed(slot_index: int, reason: String)

@export var slot_layout: SkillSlotLayout
@export var assignments: Array[SkillSlotAssignment] = []
@export var initialize_defaults_on_ready: bool = true
@export var auto_cast_on_input: bool = true
@export var debug_log: bool = false
@export_group("Lifecycle Events")
@export var skill_started_event: Resource
@export var skill_failed_event: Resource
@export var skill_finished_event: Resource
@export var cooldown_started_event: Resource

var _cooldowns: Dictionary = {}

func _ready() -> void:
	if initialize_defaults_on_ready:
		rebuild_assignments_from_layout()
	for error in validate_configuration():
		_log(error)
	if auto_cast_on_input:
		_setup_input_listeners()

func _process(delta: float) -> void:
	for skill in _cooldowns.keys():
		var remaining: float = _cooldowns[skill] - delta
		if remaining <= 0.0:
			_cooldowns.erase(skill)
		else:
			_cooldowns[skill] = remaining

func get_slot_count() -> int:
	if slot_layout == null:
		return 0
	return slot_layout.get_slot_count()

func get_slot_definition(slot_index: int) -> SkillSlotDefinition:
	if slot_layout == null:
		return null
	return slot_layout.get_slot_definition(slot_index)

func get_assignment(slot_index: int) -> SkillSlotAssignment:
	if slot_index < 0 or slot_index >= assignments.size():
		return null
	return assignments[slot_index]

func get_skill(slot_index: int) -> SkillDefinition:
	var assignment := get_assignment(slot_index)
	if assignment == null:
		return null
	return assignment.skill

func get_input_event(slot_index: int) -> InputEventChannel:
	var assignment := get_assignment(slot_index)
	if assignment != null:
		return assignment.get_input_event()
	return slot_layout.get_input_event(slot_index) if slot_layout != null else null

func is_slot_locked(slot_index: int) -> bool:
	var slot_definition := get_slot_definition(slot_index)
	return slot_definition != null and slot_definition.locked

func can_assign_skill(slot_index: int, skill: SkillDefinition) -> bool:
	var slot_definition := get_slot_definition(slot_index)
	if slot_definition == null:
		return false
	return slot_definition.can_assign_skill(skill)

func assign_skill(slot_index: int, skill: SkillDefinition) -> bool:
	if skill == null:
		return clear_skill(slot_index)
	if not can_assign_skill(slot_index, skill):
		var reason := "cannot assign %s to slot %s" % [skill.get_label(), slot_index]
		_log(reason)
		slot_validation_failed.emit(slot_index, reason)
		return false
	var assignment := _ensure_assignment(slot_index)
	if assignment == null:
		return false
	if not assignment.set_skill(skill):
		return false
	return true

func clear_skill(slot_index: int) -> bool:
	if is_slot_locked(slot_index):
		return false
	var assignment := _ensure_assignment(slot_index)
	if assignment == null:
		return false
	if not assignment.clear_skill():
		return false
	return true

func cast_slot(slot_index: int) -> bool:
	var skill := get_skill(slot_index)
	if skill == null:
		_log("slot %s has no skill" % slot_index)
		_emit_skill_failed(null, slot_index, "missing_skill")
		return false

	return cast_skill_with_context(_build_context(slot_index, skill))

func cast_skill(skill: SkillDefinition, slot_index: int = -1) -> bool:
	if slot_index >= 0:
		return cast_skill_with_context(_build_context(slot_index, skill))
	return cast_skill_with_context(SkillCastContext.new(self, skill, slot_index))

func cast_skill_with_context(context: SkillCastContext) -> bool:
	if context == null:
		context = SkillCastContext.new(self, null)
	if context.caster == null:
		context.caster = self
	if context.slot_index >= 0:
		_populate_slot_context(context)
	var skill: SkillDefinition = context.skill as SkillDefinition
	var slot_index := context.slot_index
	if skill == null:
		_emit_skill_failed(skill, slot_index, "missing_skill")
		return false

	var status_controller = StatusController.find_for_node(self)
	if status_controller != null:
		var status_context := _get_status_context(context)
		if not status_controller.can_cast_skill(status_context):
			var reason: String = status_controller.get_cast_block_reason(status_context)
			if reason == "":
				reason = "status_blocked"
			_log("%s blocked by status: %s" % [skill.get_label(), reason])
			_emit_skill_failed(skill, slot_index, reason)
			return false

	if is_on_cooldown(skill):
		_log("%s blocked by cooldown %.2fs" % [skill.get_label(), get_cooldown_remaining(skill)])
		_emit_skill_failed(skill, slot_index, "cooldown", get_cooldown_remaining(skill))
		return false

	var activation = skill.check_activation_context(context)
	var target_count: int = activation.targets.size()
	if not activation.success:
		_log("%s blocked: %s" % [skill.get_label(), activation.reason])
		_emit_skill_failed(skill, slot_index, activation.reason, 0.0, target_count)
		return false

	_emit_skill_started(skill, slot_index, target_count)
	if not skill.activate_context(context, activation):
		_emit_skill_failed(skill, slot_index, "activation", 0.0, target_count)
		return false

	var cooldown := skill.get_cooldown_seconds()
	if cooldown > 0.0:
		_cooldowns[skill] = cooldown
		_emit_cooldown_started(skill, slot_index, cooldown, target_count)

	_emit_skill_finished(skill, slot_index, target_count)
	_log("%s cast" % skill.get_label())
	return true

func rebuild_assignments_from_layout() -> void:
	var slot_count := get_slot_count()
	assignments.resize(slot_count)
	for i in slot_count:
		var slot_definition := get_slot_definition(i)
		var assignment := assignments[i]
		if assignment == null:
			assignment = SkillSlotAssignment.new()
			assignments[i] = assignment
		assignment.slot = slot_definition
		if not assignment.skill_changed.is_connected(_on_assignment_skill_changed):
			assignment.skill_changed.connect(_on_assignment_skill_changed)
		if assignment.skill == null and slot_definition != null:
			assignment.set_skill(slot_definition.default_skill, true)
	slot_layout_changed.emit(slot_layout)

func validate_configuration() -> PackedStringArray:
	var errors := PackedStringArray()
	if slot_layout == null:
		errors.append("SkillCaster is missing slot_layout")
		return errors
	for error in slot_layout.get_validation_errors():
		errors.append(error)
	if assignments.size() != get_slot_count():
		errors.append("SkillCaster assignments count does not match slot layout")
	for i in mini(assignments.size(), get_slot_count()):
		var assignment := assignments[i]
		if assignment == null:
			errors.append("SkillCaster assignment %s is null" % i)
			continue
		for assignment_error in assignment.get_validation_errors():
			errors.append(assignment_error)
		if assignment.skill == null:
			continue
		if not assignment.skill.can_assign_to_slot(get_slot_definition(i)):
			errors.append("%s cannot be assigned to slot %s (%s)" % [assignment.skill.get_label(), i, get_slot_definition(i).get_label()])
		for skill_error in assignment.skill.get_validation_errors():
			errors.append(skill_error)
	return errors

func is_on_cooldown(skill: SkillDefinition) -> bool:
	return skill != null and _cooldowns.has(skill)

func get_cooldown_remaining(skill: SkillDefinition) -> float:
	if not is_on_cooldown(skill):
		return 0.0
	return _cooldowns[skill]

func _ensure_assignment(slot_index: int) -> SkillSlotAssignment:
	if slot_index < 0 or slot_index >= get_slot_count():
		return null
	if assignments.size() != get_slot_count():
		rebuild_assignments_from_layout()
	if assignments[slot_index] == null:
		assignments[slot_index] = SkillSlotAssignment.new()
	assignments[slot_index].slot = get_slot_definition(slot_index)
	if not assignments[slot_index].skill_changed.is_connected(_on_assignment_skill_changed):
		assignments[slot_index].skill_changed.connect(_on_assignment_skill_changed)
	return assignments[slot_index]

func _on_assignment_skill_changed(assignment: SkillSlotAssignment, _old_skill: SkillDefinition, _new_skill: SkillDefinition) -> void:
	var slot_index := assignments.find(assignment)
	if slot_index != -1:
		slot_assignment_changed.emit(slot_index, assignment)

func _build_context(slot_index: int, skill: SkillDefinition) -> SkillCastContext:
	var context := SkillCastContext.new(self, skill, slot_index)
	_populate_slot_context(context)
	return context

func _populate_slot_context(context: SkillCastContext) -> void:
	context.slot_definition = get_slot_definition(context.slot_index)
	context.slot_assignment = get_assignment(context.slot_index)
	if context.skill == null and context.slot_assignment != null:
		context.skill = context.slot_assignment.skill

func _setup_input_listeners() -> void:
	for i in get_slot_count():
		var input_event := get_input_event(i)
		if input_event == null:
			continue

		var listener: InputEventListenerNode = InputEventListenerNode.new()
		listener.name = "SkillInput%s" % (i + 1)
		listener.input_event = input_event
		listener.triggered.connect(_on_skill_input_triggered.bind(i))
		add_child(listener)

func _on_skill_input_triggered(slot_index: int) -> void:
	cast_slot(slot_index)

func _emit_skill_started(skill: SkillDefinition, slot_index: int, target_count: int = 0) -> void:
	skill_started.emit(skill, slot_index)
	_emit_lifecycle_event(skill_started_event, skill, slot_index, "", 0.0, target_count)

func _emit_skill_failed(skill: SkillDefinition, slot_index: int, reason: String, cooldown_seconds: float = 0.0, target_count: int = 0) -> void:
	skill_failed.emit(skill, slot_index, reason)
	_emit_lifecycle_event(skill_failed_event, skill, slot_index, reason, cooldown_seconds, target_count)

func _emit_skill_finished(skill: SkillDefinition, slot_index: int, target_count: int = 0) -> void:
	skill_finished.emit(skill, slot_index)
	_emit_lifecycle_event(skill_finished_event, skill, slot_index, "", 0.0, target_count)

func _emit_cooldown_started(skill: SkillDefinition, slot_index: int, seconds: float, target_count: int = 0) -> void:
	cooldown_started.emit(skill, slot_index, seconds)
	_emit_lifecycle_event(cooldown_started_event, skill, slot_index, "", seconds, target_count)

func _emit_lifecycle_event(event: Resource, skill: SkillDefinition, slot_index: int, reason: String, cooldown_seconds: float, target_count: int) -> void:
	if event == null or not event.has_method("emit"):
		return
	event.emit(SkillLifecyclePayload.new(self, skill, slot_index, reason, cooldown_seconds, target_count, get_slot_definition(slot_index), get_assignment(slot_index)), self)

func _get_status_context(context: SkillCastContext) -> Dictionary:
	return {
		"cast_context": context,
		"caster": context.caster,
		"skill": context.skill,
		"slot_index": context.slot_index,
		"slot_definition": context.slot_definition,
		"slot_assignment": context.slot_assignment,
	}

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillCaster] %s" % message)

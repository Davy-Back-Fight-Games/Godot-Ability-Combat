class_name SkillCaster
extends Node

const SkillCastInstanceScript := preload("res://addons/ability_combat/runtime/skills/runtime/skill_cast_instance.gd")
const TimedSkillEffectScript := preload("res://addons/ability_combat/runtime/skills/effects/timed_skill_effect.gd")
const SkillSlotStateScript := preload("res://addons/ability_combat/runtime/skills/slots/skill_slot_state.gd")

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
@export var movement_state_path: NodePath = NodePath("../CharacterMovementState2D")
@export var debug_log: bool = false
@export_group("Lifecycle Events")
@export var skill_started_event: Resource
@export var skill_failed_event: Resource
@export var skill_finished_event: Resource
@export var cooldown_started_event: Resource
@export var cast_point_reached_event: Resource
@export var channel_started_event: Resource
@export var channel_tick_event: Resource
@export var skill_cancelled_event: Resource
@export var skill_interrupted_event: Resource

var _cooldowns: Dictionary = {}
var _slot_states: Dictionary = {}
var _cooldown_groups: Dictionary = {}
var _active_cast_instance: RefCounted
@onready var _movement_state: CharacterMovementState2D = get_node_or_null(movement_state_path) as CharacterMovementState2D

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
	for group in _cooldown_groups.keys():
		var group_remaining: float = _cooldown_groups[group] - delta
		if group_remaining <= 0.0:
			_cooldown_groups.erase(group)
		else:
			_cooldown_groups[group] = group_remaining
	for state in _slot_states.values():
		if state != null:
			state.tick(delta)
	_check_active_cast_status_interruption()
	_check_active_cast_movement_interruption()
	_tick_active_cast(delta)

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
	if _active_cast_instance != null:
		_emit_skill_failed(skill, slot_index, "already_casting")
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

	if _is_context_on_cooldown(context):
		var cooldown_remaining := _get_context_cooldown_remaining(context)
		_log("%s blocked by cooldown %.2fs" % [skill.get_label(), cooldown_remaining])
		_emit_skill_failed(skill, slot_index, "cooldown", cooldown_remaining)
		return false

	var activation = skill.check_activation_context(context)
	var target_count: int = activation.targets.size()
	if not activation.success:
		_log("%s blocked: %s" % [skill.get_label(), activation.reason])
		_emit_skill_failed(skill, slot_index, activation.reason, 0.0, target_count)
		return false

	var cast_instance := SkillCastInstanceScript.new(self, context, activation)
	_active_cast_instance = cast_instance
	_emit_skill_started(skill, slot_index, target_count, cast_instance)
	if cast_instance.duration > 0.0:
		_log("%s cast started (%.2fs)" % [skill.get_label(), cast_instance.duration])
		return true
	return _fire_cast_point(cast_instance)

func cancel_active_cast(reason: String = "cancelled", interrupted: bool = false) -> bool:
	var cast_instance := _get_cancellable_active_cast_instance()
	if cast_instance == null:
		return false
	if reason == "":
		reason = "cancelled"
	cast_instance.cancel(reason)
	_active_cast_instance = null
	_fire_timed_effects_once(cast_instance, TimedSkillEffectScript.TRIGGER_INTERRUPT)
	_emit_skill_cancelled(cast_instance.skill, cast_instance.slot_index, reason, cast_instance.target_count, cast_instance, interrupted)
	_emit_skill_failed(cast_instance.skill, cast_instance.slot_index, reason, 0.0, cast_instance.target_count, cast_instance)
	_log("%s cast cancelled: %s" % [cast_instance.skill.get_label(), reason])
	return true

func cancel_active_channel_on_input_release(slot_index: int = -1) -> bool:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null:
		return false
	var can_cancel_hold := cast_instance.phase == SkillCastInstanceScript.PHASE_CHANNELING \
		or (cast_instance.phase == SkillCastInstanceScript.PHASE_STARTED and not cast_instance.cast_point_fired)
	if not can_cancel_hold:
		return false
	if slot_index >= 0 and cast_instance.slot_index != slot_index:
		return false
	if cast_instance.skill == null or not cast_instance.skill.should_cancel_channel_on_input_release():
		return false
	return cancel_active_cast("channel_input_released")

func interrupt_active_cast(reason: String = "interrupted") -> bool:
	if reason == "":
		reason = "interrupted"
	return cancel_active_cast(reason, true)

func _tick_active_cast(delta: float) -> void:
	if _active_cast_instance == null:
		return
	var cast_instance: SkillCastInstance = _active_cast_instance as SkillCastInstance
	if cast_instance == null:
		_active_cast_instance = null
		return
	cast_instance.tick(delta)
	if cast_instance.phase == SkillCastInstanceScript.PHASE_CHANNELING:
		_fire_new_channel_tick_effects(cast_instance)
		if cast_instance.is_channel_finished():
			_finish_active_cast(cast_instance)
		return
	if not cast_instance.cast_point_fired and cast_instance.elapsed >= cast_instance.cast_point:
		_fire_cast_point(cast_instance)

func _get_cancellable_active_cast_instance() -> SkillCastInstance:
	if _active_cast_instance == null:
		return null
	var cast_instance: SkillCastInstance = _active_cast_instance as SkillCastInstance
	if cast_instance == null:
		_active_cast_instance = null
		return null
	if cast_instance.phase == SkillCastInstanceScript.PHASE_STARTED:
		if cast_instance.cast_point_fired:
			return null
		return cast_instance
	if cast_instance.phase == SkillCastInstanceScript.PHASE_CHANNELING:
		return cast_instance
	return null

func _get_interruptible_active_cast_instance() -> SkillCastInstance:
	if _active_cast_instance == null:
		return null
	var cast_instance: SkillCastInstance = _active_cast_instance as SkillCastInstance
	if cast_instance == null:
		_active_cast_instance = null
		return null
	if cast_instance.phase == SkillCastInstanceScript.PHASE_STARTED and not cast_instance.cast_point_fired:
		return cast_instance
	if cast_instance.phase == SkillCastInstanceScript.PHASE_CHANNELING:
		return cast_instance
	return null

func _check_active_cast_status_interruption() -> void:
	var cast_instance := _get_interruptible_active_cast_instance()
	if cast_instance == null:
		return
	var skill := cast_instance.skill
	if skill == null or not skill.is_interruptible_by_status():
		return
	var status_controller = StatusController.find_for_node(self)
	if status_controller == null:
		return
	var status_context := _get_status_context(cast_instance.context, cast_instance)
	if status_controller.can_cast_skill(status_context):
		return
	var reason: String = status_controller.get_cast_block_reason(status_context)
	if reason == "":
		reason = "interrupted"
	interrupt_active_cast(reason)

func _check_active_cast_movement_interruption() -> void:
	var cast_instance := _get_interruptible_active_cast_instance()
	if cast_instance == null:
		return
	var skill := cast_instance.skill
	if skill == null or not skill.is_interruptible_by_movement():
		return
	if _movement_state == null or not _movement_state.wants_to_move:
		return
	interrupt_active_cast("movement_interrupted")

func _fire_cast_point(cast_instance: SkillCastInstance) -> bool:
	var skill: SkillDefinition = cast_instance.skill
	var context := cast_instance.context
	var slot_index := cast_instance.slot_index
	var activation := cast_instance.activation_result
	var target_count := cast_instance.target_count
	cast_instance.advance_to(SkillCastInstanceScript.PHASE_CAST_POINT)
	if cast_instance.duration > 0.0:
		_log("%s cast point reached" % skill.get_label())
	_emit_cast_point_reached(skill, slot_index, target_count, cast_instance)
	if not skill.activate_context(context, activation):
		cast_instance.fail("activation")
		_emit_skill_failed(skill, slot_index, "activation", 0.0, target_count, cast_instance)
		_active_cast_instance = null
		return false
	_fire_timed_effects_once(cast_instance, TimedSkillEffectScript.TRIGGER_CAST_POINT)

	var cooldown := skill.get_cooldown_seconds()
	if cooldown > 0.0:
		_begin_cooldown(context, cooldown)
		_emit_cooldown_started(skill, slot_index, cooldown, target_count, cast_instance)

	if cast_instance.has_channel():
		cast_instance.begin_channel()
		_emit_channel_started(skill, slot_index, target_count, cast_instance)
		_log("%s channel started (%.2fs)" % [skill.get_label(), cast_instance.channel_duration])
		return true

	_finish_active_cast(cast_instance)
	return true

func _finish_active_cast(cast_instance: SkillCastInstance) -> void:
	cast_instance.finish()
	_fire_timed_effects_once(cast_instance, TimedSkillEffectScript.TRIGGER_FINISH)
	_emit_skill_finished(cast_instance.skill, cast_instance.slot_index, cast_instance.target_count, cast_instance)
	_active_cast_instance = null
	_log("%s cast finished" % cast_instance.skill.get_label())

func _fire_new_channel_tick_effects(cast_instance: SkillCastInstance) -> void:
	while cast_instance.consumed_channel_tick_count < cast_instance.channel_tick_count:
		cast_instance.consumed_channel_tick_count += 1
		_emit_channel_tick(cast_instance.skill, cast_instance.slot_index, cast_instance.target_count, cast_instance)
		_fire_timed_effects(cast_instance, TimedSkillEffectScript.TRIGGER_CHANNEL_TICK)

func _fire_timed_effects_once(cast_instance: SkillCastInstance, trigger_name: String) -> void:
	if trigger_name == TimedSkillEffectScript.TRIGGER_CAST_POINT:
		if cast_instance.cast_point_timed_effects_triggered:
			return
		cast_instance.cast_point_timed_effects_triggered = true
	elif trigger_name == TimedSkillEffectScript.TRIGGER_FINISH:
		if cast_instance.finish_timed_effects_triggered:
			return
		cast_instance.finish_timed_effects_triggered = true
	elif trigger_name == TimedSkillEffectScript.TRIGGER_INTERRUPT:
		if cast_instance.interrupt_timed_effects_triggered:
			return
		cast_instance.interrupt_timed_effects_triggered = true
	_fire_timed_effects(cast_instance, trigger_name)

func _fire_timed_effects(cast_instance: SkillCastInstance, trigger_name: String) -> void:
	if cast_instance == null or cast_instance.skill == null:
		return
	for timed_effect in cast_instance.skill.timed_effects:
		if timed_effect == null or not timed_effect.has_method("should_trigger") or not timed_effect.has_method("apply_context"):
			continue
		if not timed_effect.should_trigger(trigger_name, cast_instance):
			continue
		timed_effect.apply_context(cast_instance.context)

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
		_ensure_slot_state(i).configure(i, assignment.skill)
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
	if skill == null:
		return false
	if _cooldowns.has(skill):
		return true
	if _get_cooldown_group_remaining(skill) > 0.0:
		return true
	for state in _slot_states.values():
		if state != null and state.skill == skill and state.is_on_cooldown():
			return true
	return false

func get_cooldown_remaining(skill: SkillDefinition) -> float:
	if skill == null:
		return 0.0
	var remaining: float = 0.0
	if _cooldowns.has(skill):
		remaining = maxf(remaining, _cooldowns[skill])
	remaining = maxf(remaining, _get_cooldown_group_remaining(skill))
	for state in _slot_states.values():
		if state != null and state.skill == skill:
			remaining = maxf(remaining, state.get_cooldown_remaining())
	return remaining

func is_slot_on_cooldown(slot_index: int) -> bool:
	var state: Variant = _get_slot_state(slot_index)
	if state == null:
		return false
	return state.is_on_cooldown() or _get_cooldown_group_remaining(state.skill) > 0.0

func get_slot_cooldown_remaining(slot_index: int) -> float:
	var state: Variant = _get_slot_state(slot_index)
	if state == null:
		return 0.0
	return maxf(state.get_cooldown_remaining(), _get_cooldown_group_remaining(state.skill))

func get_slot_cooldown_total(slot_index: int) -> float:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_cooldown_total() if state != null else 0.0

func get_slot_charges_current(slot_index: int) -> int:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_charges_current() if state != null else 1

func get_slot_charges_max(slot_index: int) -> int:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_charges_max() if state != null else 1

func get_slot_recharge_remaining(slot_index: int) -> float:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_recharge_remaining() if state != null else 0.0

func get_slot_recharge_total(slot_index: int) -> float:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_recharge_total() if state != null else 0.0

func get_slot_recast_window_remaining(slot_index: int) -> float:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_recast_window_remaining() if state != null else 0.0

func get_slot_recast_window_total(slot_index: int) -> float:
	var state: Variant = _get_slot_state(slot_index)
	return state.get_recast_window_total() if state != null else 0.0

func get_active_cast_instance() -> RefCounted:
	return _active_cast_instance

func has_active_cast_instance() -> bool:
	return _active_cast_instance != null

func get_active_cast_progress() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null:
		return 0.0
	return cast_instance.get_progress()

func get_active_cast_slot_index() -> int:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	return cast_instance.slot_index if cast_instance != null else -1

func get_active_cast_elapsed_time() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null or cast_instance.cast_point_fired:
		return 0.0
	return cast_instance.elapsed

func get_active_cast_total_time() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null or cast_instance.cast_point_fired:
		return 0.0
	return cast_instance.cast_point if cast_instance.cast_point > 0.0 else cast_instance.duration

func get_active_cast_remaining_time() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null:
		return 0.0
	return cast_instance.get_remaining_time()

func get_active_channel_progress() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null or not cast_instance.has_channel():
		return 0.0
	return cast_instance.get_channel_progress()

func get_active_channel_elapsed_time() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null or cast_instance.phase != SkillCastInstanceScript.PHASE_CHANNELING:
		return 0.0
	return cast_instance.channel_elapsed

func get_active_channel_total_time() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null or cast_instance.phase != SkillCastInstanceScript.PHASE_CHANNELING:
		return 0.0
	return cast_instance.channel_duration

func get_active_channel_remaining_time() -> float:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null or not cast_instance.has_channel():
		return 0.0
	return cast_instance.get_channel_remaining_time()

func get_active_cast_phase() -> String:
	var cast_instance := get_active_cast_instance() as SkillCastInstance
	if cast_instance == null:
		return ""
	return cast_instance.phase

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
	_ensure_slot_state(slot_index).configure(slot_index, assignments[slot_index].skill)
	return assignments[slot_index]

func _on_assignment_skill_changed(assignment: SkillSlotAssignment, _old_skill: SkillDefinition, _new_skill: SkillDefinition) -> void:
	var slot_index := assignments.find(assignment)
	if slot_index != -1:
		_ensure_slot_state(slot_index).configure(slot_index, _new_skill)
		slot_assignment_changed.emit(slot_index, assignment)

func _get_slot_state(slot_index: int) -> Variant:
	if slot_index < 0:
		return null
	return _slot_states.get(slot_index)

func _ensure_slot_state(slot_index: int) -> Variant:
	var state: Variant = _get_slot_state(slot_index)
	if state == null:
		state = SkillSlotStateScript.new()
		_slot_states[slot_index] = state
	return state

func _is_context_on_cooldown(context: SkillCastContext) -> bool:
	if context == null or context.skill == null:
		return false
	if context.slot_index >= 0:
		var state: Variant = _ensure_slot_state(context.slot_index)
		state.configure(context.slot_index, context.skill)
		return state.is_on_cooldown() or _get_cooldown_group_remaining(context.skill) > 0.0
	return is_on_cooldown(context.skill)

func _get_context_cooldown_remaining(context: SkillCastContext) -> float:
	if context == null or context.skill == null:
		return 0.0
	if context.slot_index >= 0:
		return get_slot_cooldown_remaining(context.slot_index)
	return get_cooldown_remaining(context.skill)

func _begin_cooldown(context: SkillCastContext, seconds: float) -> void:
	if context != null and context.slot_index >= 0:
		var state: Variant = _ensure_slot_state(context.slot_index)
		state.configure(context.slot_index, context.skill)
		state.begin_cooldown(seconds)
	else:
		if context != null and context.skill != null:
			_cooldowns[context.skill] = seconds
	var skill: SkillDefinition = context.skill if context != null else null
	if skill == null:
		return
	var group: StringName = skill.get_cooldown_group()
	var group_seconds: float = skill.get_cooldown_group_seconds()
	if group != &"" and group_seconds > 0.0:
		_cooldown_groups[group] = maxf(float(_cooldown_groups.get(group, 0.0)), group_seconds)

func _get_cooldown_group_remaining(skill: SkillDefinition) -> float:
	if skill == null or skill.get_cooldown_group() == &"":
		return 0.0
	return maxf(float(_cooldown_groups.get(skill.get_cooldown_group(), 0.0)), 0.0)

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

func _emit_skill_started(skill: SkillDefinition, slot_index: int, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	skill_started.emit(skill, slot_index)
	_emit_lifecycle_event(skill_started_event, skill, slot_index, "", 0.0, target_count, cast_instance)

func _emit_skill_failed(skill: SkillDefinition, slot_index: int, reason: String, cooldown_seconds: float = 0.0, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	skill_failed.emit(skill, slot_index, reason)
	_emit_lifecycle_event(skill_failed_event, skill, slot_index, reason, cooldown_seconds, target_count, cast_instance)

func _emit_skill_finished(skill: SkillDefinition, slot_index: int, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	skill_finished.emit(skill, slot_index)
	_emit_lifecycle_event(skill_finished_event, skill, slot_index, "", 0.0, target_count, cast_instance)

func _emit_cooldown_started(skill: SkillDefinition, slot_index: int, seconds: float, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	cooldown_started.emit(skill, slot_index, seconds)
	_emit_lifecycle_event(cooldown_started_event, skill, slot_index, "", seconds, target_count, cast_instance)

func _emit_cast_point_reached(skill: SkillDefinition, slot_index: int, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	_emit_lifecycle_event(cast_point_reached_event, skill, slot_index, "", 0.0, target_count, cast_instance)

func _emit_channel_started(skill: SkillDefinition, slot_index: int, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	_emit_lifecycle_event(channel_started_event, skill, slot_index, "", 0.0, target_count, cast_instance)

func _emit_channel_tick(skill: SkillDefinition, slot_index: int, target_count: int = 0, cast_instance: RefCounted = null) -> void:
	_emit_lifecycle_event(channel_tick_event, skill, slot_index, "", 0.0, target_count, cast_instance)

func _emit_skill_cancelled(skill: SkillDefinition, slot_index: int, reason: String, target_count: int = 0, cast_instance: RefCounted = null, interrupted: bool = false) -> void:
	_emit_lifecycle_event(skill_cancelled_event, skill, slot_index, reason, 0.0, target_count, cast_instance)
	if interrupted or reason.begins_with("interrupt") or reason.ends_with("interrupted") or reason.contains("interrupted"):
		_emit_lifecycle_event(skill_interrupted_event, skill, slot_index, reason, 0.0, target_count, cast_instance)

func _emit_lifecycle_event(event: Resource, skill: SkillDefinition, slot_index: int, reason: String, cooldown_seconds: float, target_count: int, cast_instance: RefCounted = null) -> void:
	if event == null or not event.has_method("emit"):
		return
	var cast_instance_id: int = 0
	var phase: String = ""
	var elapsed: float = 0.0
	var duration: float = 0.0
	var channel_tick_count: int = 0
	var channel_elapsed: float = 0.0
	var channel_duration: float = 0.0
	if cast_instance != null:
		cast_instance_id = cast_instance.get_id()
		phase = cast_instance.phase
		elapsed = cast_instance.elapsed
		duration = cast_instance.duration
		channel_tick_count = cast_instance.consumed_channel_tick_count
		channel_elapsed = cast_instance.channel_elapsed
		channel_duration = cast_instance.channel_duration
	event.emit(SkillLifecyclePayload.new(self, skill, slot_index, reason, cooldown_seconds, target_count, get_slot_definition(slot_index), get_assignment(slot_index), cast_instance_id, phase, elapsed, duration, channel_tick_count, channel_elapsed, channel_duration), self)

func _get_status_context(context: SkillCastContext, cast_instance: RefCounted = null) -> Dictionary:
	var status_context := {
		"cast_context": context,
		"caster": context.caster if context != null else self,
		"skill": context.skill if context != null else null,
		"slot_index": context.slot_index if context != null else -1,
		"slot_definition": context.slot_definition if context != null else null,
		"slot_assignment": context.slot_assignment if context != null else null,
	}
	if cast_instance != null:
		status_context["cast_instance"] = cast_instance
		if cast_instance.has_method("get_id"):
			status_context["cast_instance_id"] = cast_instance.get_id()
	return status_context

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillCaster] %s" % message)

class_name SkillCastInstance
extends RefCounted

const TimeIntervalPattern = preload("res://addons/ability_combat/runtime/time/time_interval_pattern.gd")

const PHASE_STARTED := "started"
const PHASE_CAST_POINT := "cast_point"
const PHASE_CHANNELING := "channeling"
const PHASE_FINISHED := "finished"
const PHASE_CANCELLED := "cancelled"

static var _next_id: int = 1

var id: int = 0
var caster: Node
var context: SkillCastContext
var skill: SkillDefinition
var slot_index: int = -1
var phase: String = ""
var duration: float = 0.0
var cast_point: float = 0.0
var elapsed: float = 0.0
var phase_elapsed: float = 0.0
var channel_duration: float = 0.0
var channel_elapsed: float = 0.0
var channel_tick_interval_pattern: TimeIntervalPattern
var channel_tick_interval_state: Dictionary = {}
var channel_tick_count: int = 0
var consumed_channel_tick_count: int = 0
var activation_result: SkillActivationResult
var target_count: int = 0
var cast_point_fired: bool = false
var cast_point_timed_effects_triggered: bool = false
var finish_timed_effects_triggered: bool = false
var interrupt_timed_effects_triggered: bool = false
var result: bool = false
var failure_reason: String = ""

func _init(p_caster: Node = null, p_context: SkillCastContext = null, p_activation_result: SkillActivationResult = null) -> void:
	id = _next_id
	_next_id += 1
	caster = p_caster
	context = p_context
	activation_result = p_activation_result
	if context != null:
		if caster == null:
			caster = context.caster
		skill = context.skill as SkillDefinition
		slot_index = context.slot_index
	if skill != null:
		duration = skill.get_cast_time_seconds()
		cast_point = skill.get_cast_point_seconds()
		channel_duration = skill.get_channel_duration_seconds()
		channel_tick_interval_pattern = skill.get_channel_tick_interval_pattern()
		if channel_tick_interval_pattern != null:
			channel_tick_interval_state = channel_tick_interval_pattern.create_state()
	if activation_result != null:
		target_count = activation_result.targets.size()
	phase = PHASE_STARTED

func tick(delta: float) -> void:
	elapsed += delta
	phase_elapsed += delta
	if phase == PHASE_CHANNELING:
		channel_elapsed += delta
		_advance_channel_ticks(delta)

func advance_to(p_phase: String) -> void:
	phase = p_phase
	phase_elapsed = 0.0
	if p_phase == PHASE_CAST_POINT:
		cast_point_fired = true
	elif p_phase == PHASE_CHANNELING:
		channel_elapsed = 0.0
		channel_tick_count = 0
		consumed_channel_tick_count = 0
		if channel_tick_interval_pattern != null:
			channel_tick_interval_pattern.reset_interval_state(channel_tick_interval_state)

func begin_channel() -> void:
	advance_to(PHASE_CHANNELING)

func finish() -> void:
	result = true
	failure_reason = ""
	advance_to(PHASE_FINISHED)

func cancel(reason: String = "cancelled") -> void:
	result = false
	failure_reason = reason
	advance_to(PHASE_CANCELLED)

func fail(reason: String) -> void:
	result = false
	failure_reason = reason
	advance_to(PHASE_CANCELLED)

func get_id() -> int:
	return id

func get_progress() -> float:
	if cast_point_fired:
		return 1.0
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed / duration, 0.0, 1.0)

func get_cast_point_progress() -> float:
	if cast_point <= 0.0:
		return 1.0
	return clampf(elapsed / cast_point, 0.0, 1.0)

func get_remaining_time() -> float:
	if cast_point_fired:
		return 0.0
	return maxf(duration - elapsed, 0.0)

func is_before_cast_point() -> bool:
	return not cast_point_fired and elapsed < cast_point

func has_channel() -> bool:
	return channel_duration > 0.0

func get_channel_progress() -> float:
	if channel_duration <= 0.0:
		return 1.0
	return clampf(channel_elapsed / channel_duration, 0.0, 1.0)

func get_channel_remaining_time() -> float:
	return maxf(channel_duration - channel_elapsed, 0.0)

func is_channel_finished() -> bool:
	return has_channel() and channel_elapsed >= channel_duration

func _advance_channel_ticks(delta: float) -> void:
	if channel_tick_interval_pattern != null:
		channel_tick_count += channel_tick_interval_pattern.advance(delta, channel_tick_interval_state)

@tool
class_name SkillLifecyclePayload
extends GameEventPayload

var caster: Node
var skill: SkillDefinition
var slot_index: int
var reason: String
var cooldown_seconds: float
var target_count: int
var slot_definition: SkillSlotDefinition
var slot_assignment: SkillSlotAssignment
var cast_instance_id: int
var phase: String
var elapsed: float
var duration: float
var channel_tick_count: int
var channel_elapsed: float
var channel_duration: float

func _init(
	p_caster: Node = null,
	p_skill: SkillDefinition = null,
	p_slot_index: int = -1,
	p_reason: String = "",
	p_cooldown_seconds: float = 0.0,
	p_target_count: int = 0,
	p_slot_definition: SkillSlotDefinition = null,
	p_slot_assignment: SkillSlotAssignment = null,
	p_cast_instance_id: int = 0,
	p_phase: String = "",
	p_elapsed: float = 0.0,
	p_duration: float = 0.0,
	p_channel_tick_count: int = 0,
	p_channel_elapsed: float = 0.0,
	p_channel_duration: float = 0.0
) -> void:
	caster = p_caster
	skill = p_skill
	slot_index = p_slot_index
	reason = p_reason
	cooldown_seconds = p_cooldown_seconds
	target_count = p_target_count
	slot_definition = p_slot_definition
	slot_assignment = p_slot_assignment
	cast_instance_id = p_cast_instance_id
	phase = p_phase
	elapsed = p_elapsed
	duration = p_duration
	channel_tick_count = p_channel_tick_count
	channel_elapsed = p_channel_elapsed
	channel_duration = p_channel_duration

func to_log_text() -> String:
	return "caster=%s skill=%s slot_index=%s slot=%s reason=%s cooldown_seconds=%.2f target_count=%s cast_instance_id=%s phase=%s elapsed=%.2f duration=%.2f channel_tick_count=%s channel_elapsed=%.2f channel_duration=%.2f" % [
		caster,
		skill,
		slot_index,
		slot_definition.get_label() if slot_definition != null else "<none>",
		reason,
		cooldown_seconds,
		target_count,
		cast_instance_id,
		phase,
		elapsed,
		duration,
		channel_tick_count,
		channel_elapsed,
		channel_duration,
	]

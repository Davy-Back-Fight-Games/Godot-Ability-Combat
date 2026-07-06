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

func _init(
	p_caster: Node = null,
	p_skill: SkillDefinition = null,
	p_slot_index: int = -1,
	p_reason: String = "",
	p_cooldown_seconds: float = 0.0,
	p_target_count: int = 0,
	p_slot_definition: SkillSlotDefinition = null,
	p_slot_assignment: SkillSlotAssignment = null
) -> void:
	caster = p_caster
	skill = p_skill
	slot_index = p_slot_index
	reason = p_reason
	cooldown_seconds = p_cooldown_seconds
	target_count = p_target_count
	slot_definition = p_slot_definition
	slot_assignment = p_slot_assignment

func to_log_text() -> String:
	return "caster=%s skill=%s slot_index=%s slot=%s reason=%s cooldown_seconds=%.2f target_count=%s" % [
		caster,
		skill,
		slot_index,
		slot_definition.get_label() if slot_definition != null else "<none>",
		reason,
		cooldown_seconds,
		target_count,
	]

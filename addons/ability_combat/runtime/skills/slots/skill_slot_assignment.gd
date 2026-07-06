class_name SkillSlotAssignment
extends Resource

signal skill_changed(assignment: SkillSlotAssignment, old_skill: SkillDefinition, new_skill: SkillDefinition)

@export var slot: SkillSlotDefinition
@export var skill: SkillDefinition
@export var debug_log: bool = false

func set_skill(value: SkillDefinition, ignore_lock: bool = false) -> bool:
	if not can_assign(value, ignore_lock):
		_log("cannot assign %s to %s" % [_get_skill_label(value), get_label()])
		return false
	if skill == value:
		return true
	var old_skill := skill
	skill = value
	skill_changed.emit(self, old_skill, skill)
	return true

func clear_skill(ignore_lock: bool = false) -> bool:
	return set_skill(null, ignore_lock)

func can_assign(value: SkillDefinition, ignore_lock: bool = false) -> bool:
	if slot == null:
		return false
	if slot.locked and not ignore_lock:
		return false
	if value == null:
		return true
	return value.can_assign_to_slot(slot)

func get_slot_type() -> SkillSlotType:
	return slot.slot_type if slot != null else null

func get_input_event() -> InputEventChannel:
	return slot.input_event if slot != null else null

func is_locked() -> bool:
	return slot != null and slot.locked

func get_label() -> String:
	if slot != null:
		return slot.get_label()
	if skill == null:
		return "<empty assignment>"
	return skill.get_label()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if slot == null:
		errors.append("SkillSlotAssignment is missing slot")
		return errors
	if skill != null and not skill.can_assign_to_slot(slot):
		errors.append("%s cannot be assigned to %s" % [skill.get_label(), slot.get_label()])
	return errors

func _get_skill_label(value: SkillDefinition) -> String:
	return value.get_label() if value != null else "<empty>"

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillSlotAssignment] %s" % message)

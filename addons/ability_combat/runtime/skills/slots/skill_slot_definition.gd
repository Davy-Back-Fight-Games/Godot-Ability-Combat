@tool
class_name SkillSlotDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var slot_type: SkillSlotType
@export var input_event: InputEventChannel
@export var default_skill: SkillDefinition
@export var visible: bool = true
@export var locked: bool = false
@export var debug_log: bool = false

func get_label() -> String:
	if display_name != "":
		return display_name
	if id != &"":
		return String(id).capitalize()
	if resource_path != "":
		return resource_path.get_file().get_basename().capitalize()
	return "<unnamed skill slot>"

func get_slot_type_label() -> String:
	if slot_type == null:
		return "<unset slot type>"
	return slot_type.get_label()

func can_assign_skill(skill: SkillDefinition) -> bool:
	if locked:
		return false
	if skill == null:
		return true
	return skill.can_assign_to_slot(self)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("%s is missing id" % get_label())
	if slot_type == null:
		errors.append("%s is missing slot_type" % get_label())
	if input_event == null:
		errors.append("%s is missing input_event" % get_label())
	if default_skill != null and not default_skill.can_assign_to_slot(self):
		errors.append("%s default skill %s is not allowed for %s" % [get_label(), default_skill.get_label(), get_slot_type_label()])
	return errors

func is_valid_definition() -> bool:
	return get_validation_errors().is_empty()

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillSlotDefinition] %s %s" % [get_label(), message])

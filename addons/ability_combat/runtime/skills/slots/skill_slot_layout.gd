@tool
class_name SkillSlotLayout
extends Resource

@export var display_name: String = ""
@export var slots: Array[SkillSlotDefinition] = []
@export var debug_log: bool = false

func get_slot_count() -> int:
	return slots.size()

func get_slot_definition(slot_index: int) -> SkillSlotDefinition:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index]

func get_slot_index(slot: SkillSlotDefinition) -> int:
	return slots.find(slot)

func get_slot_by_id(id: StringName) -> SkillSlotDefinition:
	for slot in slots:
		if slot != null and slot.id == id:
			return slot
	return null

func get_input_event(slot_index: int) -> InputEventChannel:
	var slot := get_slot_definition(slot_index)
	if slot == null:
		return null
	return slot.input_event

func get_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path.get_file().get_basename().capitalize()
	return "<unnamed skill slot layout>"

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	var input_events := {}
	if slots.is_empty():
		errors.append("%s has no slots" % get_label())
	for i in slots.size():
		var slot := slots[i]
		if slot == null:
			errors.append("%s slot %s is null" % [get_label(), i])
			continue
		if slot.id != &"":
			if ids.has(slot.id):
				errors.append("%s has duplicate slot id %s" % [get_label(), slot.id])
			ids[slot.id] = true
		if slot.input_event != null:
			if input_events.has(slot.input_event):
				errors.append("%s has duplicate input event on %s" % [get_label(), slot.get_label()])
			input_events[slot.input_event] = true
		for error in slot.get_validation_errors():
			errors.append(error)
	return errors

func is_valid_layout() -> bool:
	return get_validation_errors().is_empty()

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillSlotLayout] %s %s" % [get_label(), message])

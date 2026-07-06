@tool
class_name InputEventChannel
extends Resource

enum Trigger {
	JUST_PRESSED,
	PRESSED,
	JUST_RELEASED,
}

@export var display_name: String = ""
@export_multiline var description: String = ""
var action_name: StringName = &""
@export var trigger: Trigger = Trigger.JUST_PRESSED
@export var debug_log: bool = false

func _get_property_list() -> Array[Dictionary]:
	return [{
		"name": "action_name",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _get_input_action_hint_string(),
		"usage": PROPERTY_USAGE_DEFAULT,
	}]

func _get_input_action_hint_string() -> String:
	var action_names := {}

	for action in InputMap.get_actions():
		action_names[String(action)] = true

	for property in ProjectSettings.get_property_list():
		var property_name: String = property["name"]
		if property_name.begins_with("input/"):
			action_names[property_name.trim_prefix("input/")] = true

	var actions := PackedStringArray()
	for action_name in action_names.keys():
		actions.append(action_name)

	actions.sort()
	return ",".join(actions)

func is_triggered() -> bool:
	if action_name == &"":
		return false

	match trigger:
		Trigger.JUST_PRESSED:
			return Input.is_action_just_pressed(action_name)
		Trigger.PRESSED:
			return Input.is_action_pressed(action_name)
		Trigger.JUST_RELEASED:
			return Input.is_action_just_released(action_name)

	return false

func log_trigger(listener: Object = null) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return

	var listener_text := "<unknown>"
	if listener != null:
		listener_text = str(listener)

	print("[InputEventChannel] %s triggered by %s action=%s trigger=%s" % [_event_label(), listener_text, action_name, _trigger_label()])

func _event_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path
	return "<unnamed input event>"

func _trigger_label() -> String:
	match trigger:
		Trigger.JUST_PRESSED:
			return "JUST_PRESSED"
		Trigger.PRESSED:
			return "PRESSED (continuous while held)"
		Trigger.JUST_RELEASED:
			return "JUST_RELEASED"

	return "<unknown>"

@tool
class_name StringVariable
extends Resource

signal value_changed(value: String)

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var debug_log: bool = false
@export var initial_value: String = ""
@export var value: String = "":
	set(new_value):
		if value == new_value:
			return
		value = new_value
		value_changed.emit(value)
		_log_value_changed()

func reset_to_initial_value() -> void:
	set_value(initial_value)

func set_value(new_value: String) -> void:
	value = new_value

func set_value_from(variable: StringVariable) -> void:
	if variable == null:
		return
	set_value(variable.value)

func _log_value_changed() -> void:
	if not debug_log and not ProjectSettings.get_setting("modular_data/debug_log_events", false):
		return
	print("[StringVariable] %s value=%s" % [_data_label(), value])

func _data_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path
	return "<unnamed string variable>"

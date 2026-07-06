@tool
class_name FloatVariable
extends Resource

signal value_changed(value: float)

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var debug_log: bool = false
@export var initial_value: float = 0.0
@export var value: float = 0.0:
	set(new_value):
		if is_equal_approx(value, new_value):
			return
		value = new_value
		value_changed.emit(value)
		_log_value_changed()

func reset_to_initial_value() -> void:
	set_value(initial_value)

func set_value(new_value: float) -> void:
	value = new_value

func set_value_from(variable: FloatVariable) -> void:
	if variable == null:
		return
	set_value(variable.value)

func apply_change(amount: float) -> void:
	set_value(value + amount)

func apply_change_from(variable: FloatVariable) -> void:
	if variable == null:
		return
	apply_change(variable.value)

func _log_value_changed() -> void:
	if not debug_log and not ProjectSettings.get_setting("modular_data/debug_log_events", false):
		return
	print("[FloatVariable] %s value=%s" % [_data_label(), value])

func _data_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path
	return "<unnamed float variable>"

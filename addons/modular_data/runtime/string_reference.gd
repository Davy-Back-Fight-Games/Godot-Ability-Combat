@tool
class_name StringReference
extends Resource

@export var use_constant: bool = true
@export var constant_value: String = ""
@export var variable: StringVariable

func get_value() -> String:
	if use_constant or variable == null:
		return constant_value
	return variable.value

func set_value(new_value: String) -> void:
	if use_constant or variable == null:
		constant_value = new_value
		return
	variable.set_value(new_value)

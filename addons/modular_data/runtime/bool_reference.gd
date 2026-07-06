@tool
class_name BoolReference
extends Resource

@export var use_constant: bool = true
@export var constant_value: bool = false
@export var variable: BoolVariable

func get_value() -> bool:
	if use_constant or variable == null:
		return constant_value
	return variable.value

func set_value(new_value: bool) -> void:
	if use_constant or variable == null:
		constant_value = new_value
		return
	variable.set_value(new_value)

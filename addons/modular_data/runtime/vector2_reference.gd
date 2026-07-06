@tool
class_name Vector2Reference
extends Resource

@export var use_constant: bool = true
@export var constant_value: Vector2 = Vector2.ZERO
@export var variable: Vector2Variable

func get_value() -> Vector2:
	if use_constant or variable == null:
		return constant_value
	return variable.value

func set_value(new_value: Vector2) -> void:
	if use_constant or variable == null:
		constant_value = new_value
		return
	variable.set_value(new_value)

func apply_change(amount: Vector2) -> void:
	set_value(get_value() + amount)

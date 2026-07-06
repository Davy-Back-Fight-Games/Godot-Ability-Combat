class_name StatusEffectModule
extends Resource

func on_apply(_instance, _controller) -> void:
	pass

func on_refresh(_instance, _controller) -> void:
	pass

func on_stack_changed(_instance, _controller, _old_stacks: int, _new_stacks: int) -> void:
	pass

func on_tick(_instance, _controller, _delta: float) -> void:
	pass

func on_remove(_instance, _controller, _reason: int) -> void:
	pass

func can_move(_instance, _controller) -> bool:
	return true

func get_movement_speed_multiplier(_instance, _controller) -> float:
	return 1.0

func can_cast_skill(_instance, _controller, _context: Dictionary = {}) -> bool:
	return true

func get_cast_block_reason(_instance, _controller, _context: Dictionary = {}) -> String:
	return ""

class_name PreventSkillCastStatusModule
extends StatusEffectModule

@export var reason := "status_blocked"

func can_cast_skill(_instance, _controller, _context: Dictionary = {}) -> bool:
	return false

func get_cast_block_reason(_instance, _controller, _context: Dictionary = {}) -> String:
	return reason

@tool
class_name ResourceType
extends ScriptableEnum

@export var current_stat: StatId
@export var max_stat: StatId

func has_current_stat() -> bool:
	return current_stat != null

func has_max_stat() -> bool:
	return max_stat != null

func is_valid_resource() -> bool:
	return has_current_stat() and has_max_stat()

func is_configured() -> bool:
	return has_current_stat()

func is_bounded() -> bool:
	return has_current_stat() and has_max_stat()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if current_stat == null:
		errors.append("ResourceType requires current_stat.")
	if max_stat == null:
		errors.append("ResourceType requires max_stat.")
	if current_stat != null and current_stat == max_stat:
		errors.append("current_stat and max_stat should be different.")
	return errors

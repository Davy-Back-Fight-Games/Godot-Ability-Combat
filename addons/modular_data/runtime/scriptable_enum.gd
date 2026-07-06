@tool
class_name ScriptableEnum
extends Resource

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var debug_log: bool = false

func get_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path.get_file().get_basename().capitalize()
	return "<unnamed enum>"

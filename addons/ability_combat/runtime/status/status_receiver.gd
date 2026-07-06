class_name StatusReceiver
extends Node

@export var status_controller_path: NodePath = NodePath("../StatusController")
@export var required: bool = true
@export var debug_log: bool = false

func get_status_controller():
	if status_controller_path.is_empty():
		_warn("status_controller_path is empty.")
		return null

	var controller := get_node_or_null(status_controller_path)
	if controller == null:
		_warn("could not resolve StatusController at %s." % status_controller_path)
		return null

	_log("resolved %s" % controller.get_path())
	return controller

func _warn(message: String) -> void:
	if required:
		push_warning("[StatusReceiver] %s %s" % [get_path(), message])
	_log(message)

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[StatusReceiver] %s %s" % [get_path(), message])

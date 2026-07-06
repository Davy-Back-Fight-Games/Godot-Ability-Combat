@tool
extends EditorPlugin

var _dock: Control

func _enter_tree() -> void:
	_dock = EventChannelsPanel.new()
	_dock.name = "Events"
	_dock.editor_interface = get_editor_interface()
	add_control_to_bottom_panel(_dock, "Events")

func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null

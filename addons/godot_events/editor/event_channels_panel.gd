@tool
class_name EventChannelsPanel
extends VBoxContainer

var editor_interface: EditorInterface:
	set(value):
		_editor_interface = value
		if _registry_panel != null:
			_registry_panel.editor_interface = value
		if _builder_panel != null:
			_builder_panel.editor_interface = value
	get:
		return _editor_interface

var _editor_interface: EditorInterface
var _registry_panel: Control
var _builder_panel: Control

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var tabs := TabContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	_registry_panel = EventRegistryDock.new()
	_registry_panel.name = "Registry"
	_registry_panel.editor_interface = _editor_interface
	tabs.add_child(_registry_panel)

	_builder_panel = EventBuilderPanel.new()
	_builder_panel.name = "Builder"
	_builder_panel.editor_interface = _editor_interface
	_builder_panel.event_generated.connect(_on_builder_event_generated)
	tabs.add_child(_builder_panel)

func _on_builder_event_generated(_resource_path: String) -> void:
	if _registry_panel != null:
		_registry_panel.scan()

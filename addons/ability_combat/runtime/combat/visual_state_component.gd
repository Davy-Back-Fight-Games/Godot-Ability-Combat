class_name VisualStateComponent
extends Node

@export var life_state_component_path: NodePath = NodePath("../LifeStateComponent")
@export var modulate_target_path: NodePath = NodePath("..")
@export var body_path: NodePath = NodePath("../Visuals/Body")
@export var face_path: NodePath = NodePath("../Visuals/Face")
@export var dead_body_color: Color = Color(0.32, 0.32, 0.36, 1.0)
@export var dead_face_color: Color = Color(0.18, 0.18, 0.2, 1.0)
@export var dead_modulate: Color = Color(1.0, 1.0, 1.0, 0.55)
@export var debug_log: bool = false

@onready var _life_state_component: Node = get_node_or_null(life_state_component_path)
@onready var _modulate_target: CanvasItem = get_node_or_null(modulate_target_path) as CanvasItem
@onready var _body: Polygon2D = get_node_or_null(body_path) as Polygon2D
@onready var _face: Polygon2D = get_node_or_null(face_path) as Polygon2D

var _alive_body_color := Color.WHITE
var _alive_face_color := Color.WHITE
var _alive_modulate := Color.WHITE

func _ready() -> void:
	_capture_alive_visuals()
	_warn_validation_errors()
	_bind_life_state_component()
	_apply_current_life_state()

func apply_alive_visuals() -> void:
	_apply_visuals(false)

func apply_dead_visuals() -> void:
	_apply_visuals(true)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if _modulate_target == null:
		errors.append("VisualStateComponent requires a CanvasItem modulate target.")
	if _body == null:
		errors.append("VisualStateComponent requires a body Polygon2D.")
	if _face == null:
		errors.append("VisualStateComponent requires a face Polygon2D.")
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

func _capture_alive_visuals() -> void:
	if _body != null:
		_alive_body_color = _body.color
	if _face != null:
		_alive_face_color = _face.color
	if _modulate_target != null:
		_alive_modulate = _modulate_target.modulate

func _bind_life_state_component() -> void:
	var life_state := _get_life_state_component()
	if life_state == null:
		return
	if life_state.has_signal("life_state_changed"):
		var callback := Callable(self, "_on_life_state_changed")
		if not life_state.is_connected("life_state_changed", callback):
			life_state.connect("life_state_changed", callback)

func _apply_current_life_state() -> void:
	var life_state := _get_life_state_component()
	if life_state != null and life_state.has_method(&"is_dead"):
		_apply_visuals(life_state.call(&"is_dead"))
		return
	_apply_visuals(false)

func _on_life_state_changed(alive: bool) -> void:
	_apply_visuals(not alive)

func _apply_visuals(dead: bool) -> void:
	if _body != null:
		_body.color = dead_body_color if dead else _alive_body_color
	if _face != null:
		_face.color = dead_face_color if dead else _alive_face_color
	if _modulate_target != null:
		_modulate_target.modulate = dead_modulate if dead else _alive_modulate
	_log("applied %s visuals" % ("dead" if dead else "alive"))

func _get_life_state_component() -> Node:
	if _life_state_component != null:
		return _life_state_component
	if not life_state_component_path.is_empty():
		_life_state_component = get_node_or_null(life_state_component_path)
	return _life_state_component

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("VisualStateComponent validation: %s" % error)

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[VisualStateComponent] %s" % message)

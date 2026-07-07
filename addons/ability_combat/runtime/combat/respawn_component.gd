class_name RespawnComponent
extends Node

signal respawn_scheduled(seconds: float)
signal respawn_started(target: Node)
signal respawn_finished(target: Node)

@export var respawn_enabled: bool = true
@export_range(0.0, 30.0, 0.1, "suffix:s") var respawn_delay: float = 4.0
@export var life_state_component_path: NodePath = NodePath("../LifeStateComponent")
@export var respawn_target_path: NodePath = NodePath("..")
@export var respawn_method: StringName = &"_respawn"
@export var debug_log: bool = false

@onready var _life_state_component: Node = get_node_or_null(life_state_component_path)
@onready var _respawn_target: Node = get_node_or_null(respawn_target_path)

var _respawn_timer: SceneTreeTimer

func _ready() -> void:
	_warn_validation_errors()
	_bind_life_state_component()

func start_respawn_timer() -> bool:
	if not respawn_enabled or respawn_delay <= 0.0 or _respawn_timer != null:
		return false
	_respawn_timer = get_tree().create_timer(respawn_delay)
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	respawn_scheduled.emit(respawn_delay)
	_log("scheduled respawn in %.2fs" % respawn_delay)
	return true

func cancel_respawn_timer() -> void:
	_respawn_timer = null

func is_respawn_scheduled() -> bool:
	return _respawn_timer != null

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var target := _get_respawn_target()
	if target == null:
		errors.append("RespawnComponent requires a respawn target.")
	elif not target.has_method(respawn_method):
		errors.append("RespawnComponent target is missing respawn method '%s'." % respawn_method)
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

func _bind_life_state_component() -> void:
	var life_state := _get_life_state_component()
	if life_state == null or not life_state.has_signal("died"):
		return
	var callback := Callable(self, "_on_life_died")
	if not life_state.is_connected("died", callback):
		life_state.connect("died", callback)

func _on_life_died(_owner: Node) -> void:
	start_respawn_timer()

func _on_respawn_timer_timeout() -> void:
	_respawn_timer = null
	var target := _get_respawn_target()
	if target == null or not target.has_method(respawn_method):
		return
	respawn_started.emit(target)
	target.call(respawn_method)
	respawn_finished.emit(target)
	_log("respawned %s" % target.name)

func _get_life_state_component() -> Node:
	if _life_state_component != null:
		return _life_state_component
	if not life_state_component_path.is_empty():
		_life_state_component = get_node_or_null(life_state_component_path)
	return _life_state_component

func _get_respawn_target() -> Node:
	if _respawn_target != null:
		return _respawn_target
	if not respawn_target_path.is_empty():
		_respawn_target = get_node_or_null(respawn_target_path)
	return _respawn_target

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("RespawnComponent validation: %s" % error)

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[RespawnComponent] %s" % message)

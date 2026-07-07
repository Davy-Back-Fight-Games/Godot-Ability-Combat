class_name CharacterMotor2D
extends Node

@export var body_path: NodePath = NodePath("..")
@export var movement_state_path: NodePath = NodePath("../CharacterMovementState2D")
@export var forced_motion_path: NodePath = NodePath("../ForcedMotionQueue2D")
@export var stats_component_path: NodePath = NodePath("../StatsComponent")
@export var status_controller_path: NodePath = NodePath("../StatusController")
@export var life_state_component_path: NodePath = NodePath("../LifeStateComponent")
@export var config: CharacterControllerConfig2D

@onready var _body: CharacterBody2D = get_node_or_null(body_path) as CharacterBody2D
@onready var _movement_state: CharacterMovementState2D = get_node_or_null(movement_state_path) as CharacterMovementState2D
@onready var _forced_motion: ForcedMotionQueue2D = get_node_or_null(forced_motion_path) as ForcedMotionQueue2D
@onready var _stats_component: StatsComponent = get_node_or_null(stats_component_path) as StatsComponent
@onready var _status_controller: Node = get_node_or_null(status_controller_path)
@onready var _life_state_component: Node = get_node_or_null(life_state_component_path)

func _ready() -> void:
	_warn_validation_errors()

func _physics_process(delta: float) -> void:
	if _body == null:
		return

	var forced_velocity := Vector2.ZERO
	if _forced_motion != null:
		forced_velocity = _forced_motion.consume_velocity(delta)

	var voluntary_velocity := Vector2.ZERO
	if not _is_dead() and not _is_forced_motion_blocking() and _can_move_voluntarily():
		voluntary_velocity = _get_voluntary_velocity()

	_body.velocity = voluntary_velocity + forced_velocity
	_body.move_and_slide()
	if _forced_motion != null and not forced_velocity.is_zero_approx() and _body.get_slide_collision_count() > 0:
		_forced_motion.notify_collision()

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if _body == null:
		errors.append("CharacterMotor2D requires a CharacterBody2D body.")
	if _movement_state == null:
		errors.append("CharacterMotor2D requires a CharacterMovementState2D.")
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

func _get_voluntary_velocity() -> Vector2:
	if _movement_state == null or not _movement_state.wants_to_move:
		return Vector2.ZERO
	return _movement_state.move_direction * _get_movement_speed()

func _get_movement_speed() -> float:
	var base_speed := 220.0
	var movement_speed_stat: StatId = null
	if config != null:
		base_speed = config.default_movement_speed
		movement_speed_stat = config.movement_speed_stat

	var speed := base_speed
	if _stats_component != null and movement_speed_stat != null:
		speed = _stats_component.get_stat_value(movement_speed_stat, base_speed)

	return speed * _get_status_movement_multiplier()

func _get_status_movement_multiplier() -> float:
	if _status_controller != null and _status_controller.has_method(&"get_movement_speed_multiplier"):
		return _status_controller.call(&"get_movement_speed_multiplier")
	return 1.0

func _can_move_voluntarily() -> bool:
	if _status_controller != null and _status_controller.has_method(&"can_move"):
		return _status_controller.call(&"can_move")
	return true

func _is_dead() -> bool:
	if _life_state_component != null and _life_state_component.has_method(&"is_dead"):
		return _life_state_component.call(&"is_dead")
	return false

func _is_forced_motion_blocking() -> bool:
	return _forced_motion != null and _forced_motion.is_blocking()

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("CharacterMotor2D validation: %s" % error)

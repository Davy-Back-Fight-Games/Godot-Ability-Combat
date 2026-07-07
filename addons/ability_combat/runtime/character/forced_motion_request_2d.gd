class_name ForcedMotionRequest2D
extends Resource

enum MotionKind { DASH, CHARGE, LEAP, KNOCKBACK, PULL, CUSTOM }
enum CollisionPolicy { SLIDE, STOP_ON_COLLISION }
enum OffsetPolicy { FIXED_DISTANCE, TO_DESTINATION, TO_DESTINATION_MAX_DISTANCE, TO_DESTINATION_STOP_SHORT }

const TimeDurationPattern = preload("res://addons/ability_combat/runtime/time/time_duration_pattern.gd")

@export var motion_kind: MotionKind = MotionKind.DASH
@export var distance: FloatReference
@export var duration_pattern: TimeDurationPattern
@export var blocking: bool = true
@export var collision_policy: CollisionPolicy = CollisionPolicy.SLIDE
@export var offset_policy: OffsetPolicy = OffsetPolicy.FIXED_DISTANCE
@export var stop_distance: FloatReference
@export var minimum_distance: FloatReference

func get_distance() -> float:
	if distance == null:
		return 0.0
	return maxf(distance.get_value(), 0.0)

func get_duration() -> float:
	if duration_pattern == null:
		return 0.0
	return duration_pattern.get_duration_seconds()

func get_stop_distance() -> float:
	if stop_distance == null:
		return 0.0
	return maxf(stop_distance.get_value(), 0.0)

func get_minimum_distance() -> float:
	if minimum_distance == null:
		return 0.0
	return maxf(minimum_distance.get_value(), 0.0)

func is_destination_based() -> bool:
	return offset_policy != OffsetPolicy.FIXED_DISTANCE

func get_offset_for_direction(direction: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return Vector2.ZERO
	return direction.normalized() * get_distance()

func get_offset_for_destination(from_position: Vector2, destination: Vector2, fallback_direction: Vector2 = Vector2.ZERO) -> Vector2:
	var offset := destination - from_position
	var direction := offset.normalized() if not offset.is_zero_approx() else fallback_direction.normalized()
	if direction.is_zero_approx():
		return Vector2.ZERO

	var length := offset.length()
	match offset_policy:
		OffsetPolicy.FIXED_DISTANCE:
			length = get_distance()
		OffsetPolicy.TO_DESTINATION:
			pass
		OffsetPolicy.TO_DESTINATION_MAX_DISTANCE:
			var max_distance := get_distance()
			if max_distance > 0.0:
				length = minf(length, max_distance)
		OffsetPolicy.TO_DESTINATION_STOP_SHORT:
			length = maxf(length - get_stop_distance(), 0.0)
			var max_distance := get_distance()
			if max_distance > 0.0:
				length = minf(length, max_distance)

	if length < get_minimum_distance():
		return Vector2.ZERO
	return direction * length

func get_debug_description() -> String:
	var motion_keys := MotionKind.keys()
	var motion_label := "CUSTOM"
	if motion_kind >= 0 and motion_kind < motion_keys.size():
		motion_label = motion_keys[motion_kind]
	return "%s %.1fpx over %.2fs" % [motion_label, get_distance(), get_duration()]

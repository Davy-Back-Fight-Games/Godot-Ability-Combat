class_name SkillCastContext
extends RefCounted

var caster: Node
var skill: Resource
var slot_index: int = -1
var slot_definition: SkillSlotDefinition
var slot_assignment: SkillSlotAssignment
var aim_direction: Vector2 = Vector2.RIGHT
var has_aim_direction: bool = false
var target_position: Vector2 = Vector2.ZERO
var has_target_position: bool = false
var targets: Array[Node] = []

func _init(p_caster: Node = null, p_skill: Resource = null, p_slot_index: int = -1) -> void:
	caster = p_caster
	skill = p_skill
	slot_index = p_slot_index

func set_aim_direction(value: Vector2) -> void:
	if value.is_zero_approx():
		has_aim_direction = false
		return
	aim_direction = value.normalized()
	has_aim_direction = true

func set_target_position(value: Vector2) -> void:
	target_position = value
	has_target_position = true

func get_aim_direction_or_default(default_value: Vector2 = Vector2.RIGHT) -> Vector2:
	if has_aim_direction and not aim_direction.is_zero_approx():
		return aim_direction.normalized()
	if default_value.is_zero_approx():
		return Vector2.RIGHT
	return default_value.normalized()

func get_target_position_or_default(default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if has_target_position:
		return target_position
	return default_value

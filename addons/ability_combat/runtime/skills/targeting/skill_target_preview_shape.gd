class_name SkillTargetPreviewShape
extends Resource

enum ShapeType {
	NONE,
	SELF,
	CIRCLE,
	CONE,
	LINE,
}

@export var shape_type: ShapeType = ShapeType.NONE
@export var origin: Vector2 = Vector2.ZERO
@export var direction: Vector2 = Vector2.RIGHT
@export var radius: float = 0.0
@export_range(0.0, 360.0, 1.0, "degrees") var angle_degrees: float = 0.0
@export var length: float = 0.0
@export var width: float = 0.0

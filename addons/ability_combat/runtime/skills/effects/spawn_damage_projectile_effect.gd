class_name SpawnDamageProjectileEffect
extends SkillEffect

@export var projectile_scene: PackedScene
@export var projectile_script: GDScript
@export var runtime_set: RuntimeSet
@export var formula: DamageFormula
@export var target_resource: ResourceType
@export var speed: FloatReference
@export var max_range: FloatReference
@export var hit_radius: FloatReference
@export var lifetime: FloatReference
@export var filters: Array[Resource] = []

var _warned_invalid_configuration: bool = false

func apply_context(context: SkillCastContext) -> void:
	if not _has_valid_configuration():
		return

	if context == null or context.caster == null:
		return

	var caster_2d := SkillTargetingGeometry.get_node2d(context.caster)
	if caster_2d == null:
		return

	var projectile: Node = _create_projectile()
	if projectile == null:
		return

	var direction := context.get_aim_direction_or_default(SkillTargetingGeometry.get_forward(context.caster))
	if not _configure_projectile(projectile, context, direction):
		projectile.queue_free()
		return

	var parent := caster_2d.get_parent()
	if parent == null:
		parent = caster_2d.get_tree().current_scene
	if parent == null:
		parent = caster_2d.get_tree().root
	if projectile is Node2D:
		projectile.global_position = caster_2d.global_position
	parent.add_child(projectile)
	if projectile is Node2D:
		projectile.global_position = caster_2d.global_position

	if _should_log() or _formula_should_log():
		print("[SpawnDamageProjectileEffect] spawned projectile direction=%s" % direction)

func _create_projectile() -> Node:
	if projectile_scene != null:
		var scene_instance := projectile_scene.instantiate()
		if scene_instance is Node:
			return scene_instance
		push_warning("SpawnDamageProjectileEffect projectile_scene must instantiate a Node.")
		return null

	if projectile_script != null:
		if not projectile_script.can_instantiate():
			push_warning("SpawnDamageProjectileEffect projectile_script cannot be instantiated.")
			return null
		var script_instance = projectile_script.new()
		if script_instance is Node:
			return script_instance
		push_warning("SpawnDamageProjectileEffect projectile_script must instantiate a Node.")
		return null

	push_warning("SpawnDamageProjectileEffect requires projectile_scene or projectile_script.")
	return null

func _configure_projectile(projectile: Node, context: SkillCastContext, direction: Vector2) -> bool:
	if projectile.has_method(&"initialize_damage_skill_projectile"):
		var config := {
			&"caster": context.caster,
			&"skill": context.skill,
			&"runtime_set": runtime_set,
			&"formula": formula,
			&"target_resource": target_resource,
			&"direction": direction,
			&"speed": _get_float(speed, 420.0),
			&"max_range": _get_float(max_range, 320.0),
			&"hit_radius": _get_float(hit_radius, 14.0),
			&"lifetime": _get_float(lifetime, 1.25),
			&"filters": filters.duplicate(),
			&"debug_log": _should_log(),
		}
		projectile.call(&"initialize_damage_skill_projectile", context, config)
		return true

	push_warning("SpawnDamageProjectileEffect projectile must be DamageSkillProjectile2D or implement initialize_damage_skill_projectile(context, config).")
	return false

func _get_float(reference: FloatReference, default_value: float) -> float:
	if reference == null:
		return default_value
	return reference.get_value()

func _formula_should_log() -> bool:
	return formula != null and formula.debug_log

func _has_valid_configuration() -> bool:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	if formula == null:
		errors.append("formula is required.")
	else:
		errors.append_array(formula.get_validation_errors())
		warnings.append_array(formula.get_validation_warnings())
	if target_resource == null:
		errors.append("target_resource is required.")
	if projectile_scene == null and projectile_script == null:
		errors.append("projectile_scene or projectile_script is required.")
	if projectile_scene != null and projectile_script != null:
		errors.append("only one of projectile_scene or projectile_script should be set.")
	if projectile_script != null and not projectile_script.can_instantiate():
		errors.append("projectile_script cannot be instantiated.")

	var messages := PackedStringArray(errors)
	messages.append_array(warnings)
	if not messages.is_empty():
		_warn_invalid_configuration(messages)
	return errors.is_empty()

func _warn_invalid_configuration(errors: PackedStringArray) -> void:
	if _warned_invalid_configuration:
		return
	_warned_invalid_configuration = true
	push_warning("SpawnDamageProjectileEffect configuration is invalid: %s" % "; ".join(errors))

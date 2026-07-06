class_name SkillAimController
extends Node

const SKILL_CONFIRM_ACTION := &"SkillConfirm"
const SKILL_CANCEL_ACTION := &"SkillCancel"

@export var skill_caster_path: NodePath
@export var indicator_path: NodePath
@export var aim_with_mouse: bool = true
@export var debug_log: bool = false

@onready var _skill_caster: SkillCaster = get_node_or_null(skill_caster_path)
@onready var _indicator: Node = get_node_or_null(indicator_path)

var _preview_slot := -1
var _preview_context: SkillCastContext
var _preview_cast_mode := SkillDefinition.CastMode.INSTANT

func _process(_delta: float) -> void:
	if _skill_caster == null:
		return

	_update_mouse_aim_direction()

	for slot_index in _skill_caster.get_slot_count():
		var input_event := _skill_caster.get_input_event(slot_index)
		var skill := _get_skill(slot_index)
		if input_event == null or skill == null:
			continue

		if skill.cast_mode == SkillDefinition.CastMode.PRESS_PREVIEW_RELEASE_CAST:
			_poll_preview_release_slot(slot_index, input_event, skill)
		elif skill.cast_mode == SkillDefinition.CastMode.PRESS_PREVIEW_CONFIRM_CAST:
			_poll_preview_confirm_slot(slot_index, input_event)
		elif input_event.is_triggered():
			if _is_confirm_preview_active():
				cancel_preview()
			_skill_caster.cast_skill_with_context(_build_context(slot_index, skill))

	if _preview_slot != -1:
		_update_preview(_preview_slot)

func _input(event: InputEvent) -> void:
	if not _is_confirm_preview_active():
		return
	if _event_is_action_pressed(event, SKILL_CANCEL_ACTION):
		cancel_preview()
		get_viewport().set_input_as_handled()
	elif _event_is_action_pressed(event, SKILL_CONFIRM_ACTION) and not _is_mouse_event_over_interactive_gui(event):
		confirm_preview()
		get_viewport().set_input_as_handled()

func _poll_preview_release_slot(slot_index: int, input_event: InputEventChannel, skill: SkillDefinition) -> void:
	if _is_just_pressed(input_event):
		start_preview(slot_index)

	if _preview_slot == slot_index and _preview_cast_mode == SkillDefinition.CastMode.PRESS_PREVIEW_RELEASE_CAST and _is_just_released(input_event):
		var context := _get_preview_context(slot_index, skill)
		_hide_preview()
		_skill_caster.cast_skill_with_context(context)

func _poll_preview_confirm_slot(slot_index: int, input_event: InputEventChannel) -> void:
	if _is_just_pressed(input_event):
		start_preview(slot_index)

func start_preview(slot_index: int) -> bool:
	var skill := _get_skill(slot_index)
	if skill == null:
		return false
	if skill.cast_mode != SkillDefinition.CastMode.PRESS_PREVIEW_RELEASE_CAST and skill.cast_mode != SkillDefinition.CastMode.PRESS_PREVIEW_CONFIRM_CAST:
		return false

	_preview_slot = slot_index
	_preview_cast_mode = skill.cast_mode
	_preview_context = _build_context(slot_index, skill)
	_update_preview(slot_index)
	return true

func cancel_preview() -> bool:
	if _preview_slot == -1:
		return false
	_hide_preview()
	return true

func confirm_preview() -> bool:
	if not _is_confirm_preview_active():
		return false
	var slot_index := _preview_slot
	var skill := _get_skill(slot_index)
	if skill == null:
		_hide_preview()
		return false

	var context := _get_preview_context(slot_index, skill)
	_hide_preview()
	return _skill_caster.cast_skill_with_context(context)

func _update_preview(slot_index: int) -> void:
	if _indicator == null:
		return

	var skill := _get_skill(slot_index)
	if skill == null:
		_hide_preview()
		return
	_get_preview_context(slot_index, skill)

	var shape := _get_preview_shape(skill, _preview_context)
	_indicator.show_shape(shape, _is_preview_valid(skill, _preview_context))

func _hide_preview() -> void:
	_preview_slot = -1
	_preview_context = null
	_preview_cast_mode = SkillDefinition.CastMode.INSTANT
	if _indicator != null:
		_indicator.hide_shape()

func _is_confirm_preview_active() -> bool:
	return _preview_slot != -1 and _preview_cast_mode == SkillDefinition.CastMode.PRESS_PREVIEW_CONFIRM_CAST

func _get_skill(slot_index: int) -> SkillDefinition:
	if _skill_caster == null:
		return null
	return _skill_caster.get_skill(slot_index)

func _get_preview_shape(skill: SkillDefinition, context: SkillCastContext) -> Resource:
	if skill.targeting != null and skill.targeting.has_method("get_preview_shape_for_context"):
		return skill.targeting.get_preview_shape_for_context(context)
	if skill.targeting != null and skill.targeting.has_method("get_preview_shape"):
		return skill.targeting.get_preview_shape(_skill_caster, skill)

	var position := SkillTargetingGeometry.try_get_position(_skill_caster)
	if not position.found:
		return null

	var shape := SkillTargetPreviewShape.new()
	shape.shape_type = SkillTargetPreviewShape.ShapeType.SELF
	shape.origin = position.position
	shape.direction = SkillTargetingGeometry.get_forward_for_context(context)
	shape.radius = 32.0
	return shape

func _is_preview_valid(skill: SkillDefinition, context: SkillCastContext) -> bool:
	if _skill_caster != null and _skill_caster.is_on_cooldown(skill):
		return false

	var targets := _resolve_preview_targets(skill, context)
	if _requires_targets(skill) and targets.is_empty():
		return false

	var activation = skill.check_activation_context(context)
	return activation.success

func _resolve_preview_targets(skill: SkillDefinition, context: SkillCastContext) -> Array[Node]:
	if skill.targeting == null:
		return [_skill_caster]
	if skill.targeting.has_method("resolve_preview_targets_for_context"):
		return skill.targeting.resolve_preview_targets_for_context(context)
	if skill.targeting.has_method("resolve_preview_targets"):
		return skill.targeting.resolve_preview_targets(_skill_caster, skill)
	if skill.targeting.has_method("resolve_targets"):
		return skill.targeting.resolve_targets(_skill_caster, skill)
	return []

func _requires_targets(skill: SkillDefinition) -> bool:
	for requirement in skill.requirements:
		if requirement is HasTargetsRequirement:
			return true
	return false

func _is_just_pressed(input_event: InputEventChannel) -> bool:
	# Preview modes always begin on press; instant slots use InputEventChannel.trigger in _process.
	if input_event.action_name != &"":
		return Input.is_action_just_pressed(input_event.action_name)
	return input_event.is_triggered()

func _is_just_released(input_event: InputEventChannel) -> bool:
	if input_event.action_name == &"":
		return false
	return Input.is_action_just_released(input_event.action_name)

func _event_is_action_pressed(event: InputEvent, action_name: StringName) -> bool:
	return InputMap.has_action(action_name) and event.is_action_pressed(action_name)

func _is_mouse_event_over_interactive_gui(event: InputEvent) -> bool:
	if not event is InputEventMouseButton:
		return false

	var hovered := get_viewport().gui_get_hovered_control()
	while hovered != null:
		if hovered is Button or hovered.name == "SkillSelectionPanel":
			return true
		hovered = hovered.get_parent() as Control
	return false

func _get_preview_context(slot_index: int, skill: SkillDefinition) -> SkillCastContext:
	if _preview_context == null or _preview_context.slot_index != slot_index or _preview_context.skill != skill:
		_preview_context = _build_context(slot_index, skill)
	else:
		_update_context_from_mouse(_preview_context)
	return _preview_context

func _build_context(slot_index: int, skill: SkillDefinition) -> SkillCastContext:
	var context := SkillCastContext.new(_skill_caster, skill, slot_index)
	context.slot_definition = _skill_caster.get_slot_definition(slot_index)
	context.slot_assignment = _skill_caster.get_assignment(slot_index)
	_update_context_from_mouse(context)
	return context

func _update_context_from_mouse(context: SkillCastContext) -> void:
	if context == null or not aim_with_mouse:
		return

	var caster_position := SkillTargetingGeometry.try_get_position(_skill_caster)
	if not caster_position.found:
		return

	var caster_node_2d := SkillTargetingGeometry.get_node2d(_skill_caster)
	if caster_node_2d == null:
		return

	var target_position := caster_node_2d.get_global_mouse_position()
	context.set_target_position(target_position)

	var direction: Vector2 = target_position - caster_position.position
	if not direction.is_zero_approx():
		context.set_aim_direction(direction)

func _update_mouse_aim_direction() -> void:
	if not aim_with_mouse:
		return

	var caster_position := SkillTargetingGeometry.try_get_position(_skill_caster)
	if not caster_position.found:
		return

	var caster_node_2d := SkillTargetingGeometry.get_node2d(_skill_caster)
	if caster_node_2d == null:
		return

	var direction: Vector2 = caster_node_2d.get_global_mouse_position() - caster_position.position
	_skill_caster.set_meta(&"skill_target_position", caster_node_2d.get_global_mouse_position())
	if direction.is_zero_approx():
		return

	_skill_caster.set_meta(&"skill_aim_direction", direction.normalized())

func _log(message: String) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[SkillAimController] %s" % message)

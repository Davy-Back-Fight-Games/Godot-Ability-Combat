class_name SkillAimController
extends Node

const SKILL_CONFIRM_ACTION := &"SkillConfirm"
const SKILL_CANCEL_ACTION := &"SkillCancel"
const SkillMouseAimContextProviderScript := preload("res://addons/ability_combat/runtime/skills/aiming/skill_mouse_aim_context_provider.gd")

@export var skill_caster_path: NodePath
@export var indicator_path: NodePath
@export var aim_state_path: NodePath
@export var aim_with_mouse: bool = true
@export var debug_log: bool = false

@onready var _skill_caster: SkillCaster = get_node_or_null(skill_caster_path)
@onready var _indicator: Node = get_node_or_null(indicator_path)
@onready var _aim_state: CharacterAimState2D = get_node_or_null(aim_state_path) as CharacterAimState2D

var _preview_slot := -1
var _preview_context: SkillCastContext
var _preview_aim_mode: Resource

func _process(_delta: float) -> void:
	if _skill_caster == null:
		return

	_update_mouse_aim_direction()

	for slot_index in _skill_caster.get_slot_count():
		var input_event := _skill_caster.get_input_event(slot_index)
		var skill := _get_skill(slot_index)
		if input_event == null or skill == null:
			continue
		if _is_just_released(input_event) and _skill_caster.cancel_active_channel_on_input_release(slot_index):
			_log("release cancelled active channel skill=%s slot=%d" % [skill.get_label(), slot_index])
			continue

		var aim_mode := skill.get_aim_mode()
		if not _is_aim_mode_valid(aim_mode):
			continue

		if aim_mode.casts_on_release():
			_poll_preview_release_slot(slot_index, input_event, skill)
		elif aim_mode.casts_on_confirm():
			_poll_preview_confirm_slot(slot_index, input_event)
		elif aim_mode.casts_on_press() and input_event.is_triggered():
			if _is_confirm_preview_active():
				cancel_preview()
			var context := _build_context(slot_index, skill)
			_log("instant cast skill=%s slot=%d aim=%s provider=%s target=%s" % [skill.get_label(), slot_index, _get_debug_label(aim_mode, "<unknown aim>"), _get_provider_label(aim_mode), _context_target_label(context)])
			_skill_caster.cast_skill_with_context(context)

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

	if _preview_slot == slot_index and _preview_aim_mode != null and _preview_aim_mode.casts_on_release() and _is_just_released(input_event):
		var context := _get_preview_context(slot_index, skill)
		_log("release preview skill=%s slot=%d aim=%s provider=%s target=%s" % [skill.get_label(), slot_index, _get_debug_label(_preview_aim_mode, "<unknown aim>"), _get_provider_label(_preview_aim_mode), _context_target_label(context)])
		_hide_preview()
		_skill_caster.cast_skill_with_context(context)

func _poll_preview_confirm_slot(slot_index: int, input_event: InputEventChannel) -> void:
	if _is_just_pressed(input_event):
		start_preview(slot_index)

func start_preview(slot_index: int) -> bool:
	var skill := _get_skill(slot_index)
	if skill == null:
		return false
	var aim_mode := skill.get_aim_mode()
	if not _is_aim_mode_valid(aim_mode) or not aim_mode.uses_preview():
		return false

	_preview_slot = slot_index
	_preview_aim_mode = aim_mode
	_preview_context = _build_context(slot_index, skill)
	_log("start preview skill=%s slot=%d aim=%s provider=%s target=%s" % [skill.get_label(), slot_index, _get_debug_label(aim_mode, "<unknown aim>"), _get_provider_label(aim_mode), _context_target_label(_preview_context)])
	_update_preview(slot_index)
	return true

func cancel_preview() -> bool:
	if _preview_slot == -1:
		return false
	var skill := _get_skill(_preview_slot)
	var skill_label := skill.get_label() if skill != null else "<missing skill>"
	_log("cancel preview skill=%s slot=%d aim=%s provider=%s target=%s" % [skill_label, _preview_slot, _get_debug_label(_preview_aim_mode, "<unknown aim>"), _get_provider_label(_preview_aim_mode), _context_target_label(_preview_context)])
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
	_log("confirm preview skill=%s slot=%d aim=%s provider=%s target=%s" % [skill.get_label(), slot_index, _get_debug_label(_preview_aim_mode, "<unknown aim>"), _get_provider_label(_preview_aim_mode), _context_target_label(context)])
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
	var is_valid := _is_preview_valid(skill, _preview_context)
	_indicator.show_shape(shape, is_valid)
	if _indicator.has_method(&"show_target"):
		_indicator.call(&"show_target", _preview_context.get_target_node_or_null(), is_valid, _preview_context)

func _hide_preview() -> void:
	_preview_slot = -1
	_preview_context = null
	_preview_aim_mode = null
	if _indicator != null:
		if _indicator.has_method(&"hide_target"):
			_indicator.call(&"hide_target")
		_indicator.hide_shape()

func is_preview_active() -> bool:
	return _preview_slot != -1

func _is_confirm_preview_active() -> bool:
	return _preview_slot != -1 and _preview_aim_mode != null and _preview_aim_mode.casts_on_confirm()

func _get_skill(slot_index: int) -> SkillDefinition:
	if _skill_caster == null:
		return null
	return _skill_caster.get_skill(slot_index)

func _is_aim_mode_valid(value: Resource) -> bool:
	return value != null \
		and value.has_method("casts_on_press") \
		and value.has_method("uses_preview") \
		and value.has_method("casts_on_release") \
		and value.has_method("casts_on_confirm")

func _get_debug_label(value: Resource, fallback: String) -> String:
	if value != null and value.has_method("get_debug_label"):
		return value.get_debug_label()
	if value != null:
		if value.resource_path != "":
			return value.resource_path
		return value.get_class()
	return fallback

func _get_provider_label(aim_mode: Resource) -> String:
	if aim_mode != null and aim_mode.has_method("get_context_provider"):
		var provider: Resource = aim_mode.get_context_provider()
		return _get_debug_label(provider, "<no provider>")
	return "<no provider>"

func _context_target_label(context: SkillCastContext) -> String:
	if context == null:
		return "<none>"
	var target := context.get_target_node_or_null()
	if target == null:
		return "<none>"
	return target.name

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
		_prepare_context(_preview_context, skill)
	return _preview_context

func _build_context(slot_index: int, skill: SkillDefinition) -> SkillCastContext:
	var context := SkillCastContext.new(_skill_caster, skill, slot_index)
	context.slot_definition = _skill_caster.get_slot_definition(slot_index)
	context.slot_assignment = _skill_caster.get_assignment(slot_index)
	_prepare_context(context, skill)
	return context

func _prepare_context(context: SkillCastContext, skill: SkillDefinition) -> void:
	if context == null or skill == null:
		return
	var aim_mode := skill.get_aim_mode()
	if aim_mode != null and aim_mode.has_method("prepare_context"):
		aim_mode.prepare_context(context, self)
	else:
		SkillMouseAimContextProviderScript.new().prepare_context(context, self)

func get_aim_state() -> CharacterAimState2D:
	return _aim_state

func _update_mouse_aim_direction() -> void:
	if not aim_with_mouse:
		return
	if _aim_state != null:
		if _aim_state.has_target_position:
			_skill_caster.set_meta(&"skill_target_position", _aim_state.target_position)
		_skill_caster.set_meta(&"skill_aim_direction", _aim_state.aim_direction)
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

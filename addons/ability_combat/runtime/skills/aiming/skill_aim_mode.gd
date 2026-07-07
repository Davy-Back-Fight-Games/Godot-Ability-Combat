class_name SkillAimMode
extends Resource

const SkillMouseAimContextProviderScript := preload("res://addons/ability_combat/runtime/skills/aiming/skill_mouse_aim_context_provider.gd")

@export var context_provider: Resource

func casts_on_press() -> bool:
	return false

func uses_preview() -> bool:
	return false

func casts_on_release() -> bool:
	return false

func casts_on_confirm() -> bool:
	return false

func get_debug_label() -> String:
	return "Aim Mode"

func get_context_provider() -> Resource:
	if context_provider != null:
		return context_provider
	return SkillMouseAimContextProviderScript.new()

func prepare_context(context: SkillCastContext, controller: SkillAimController) -> void:
	var provider := get_context_provider()
	if _can_prepare_context_provider(provider):
		provider.prepare_context(context, controller)

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	if context_provider != null:
		var provider_errors := _get_context_provider_interface_errors(context_provider)
		if not provider_errors.is_empty():
			var skill_label := skill.get_label() if skill != null else "<unnamed skill>"
			var provider_label := _get_context_provider_label(context_provider)
			for provider_error in provider_errors:
				errors.append("%s aim context_provider %s %s" % [skill_label, provider_label, provider_error])
		if context_provider.has_method("get_validation_errors"):
			for error in context_provider.get_validation_errors(skill):
				errors.append("%s: %s" % [_get_context_provider_label(context_provider), error])
	return errors

func _is_context_provider_valid(value: Resource) -> bool:
	return _get_context_provider_interface_errors(value).is_empty()

func _get_context_provider_interface_errors(value: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if value == null:
		errors.append("is null")
		return errors
	if not value.has_method("prepare_context"):
		errors.append("is missing prepare_context")
	if not value.has_method("get_validation_errors"):
		errors.append("is missing get_validation_errors")
	if not value.has_method("get_debug_label"):
		errors.append("is missing get_debug_label")
	return errors

func _get_context_provider_label(value: Resource) -> String:
	if value != null and value.has_method("get_debug_label"):
		return value.get_debug_label()
	if value != null:
		if value.resource_path != "":
			return value.resource_path
		return value.get_class()
	return "<null provider>"

func _can_prepare_context_provider(value: Resource) -> bool:
	return value != null \
		and value.has_method("prepare_context")

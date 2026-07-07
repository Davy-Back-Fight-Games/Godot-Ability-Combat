class_name ShapeRuntimeSetTargeting
extends FilteredRuntimeSetTargeting

@export var shape: Resource

func get_debug_label() -> String:
	return "Shape Runtime Set Targeting"

func resolve_targets(caster: Node, skill: Resource) -> Array[Node]:
	return _resolve_targets(caster, skill, SkillCastContext.new(caster, skill))

func get_preview_shape(caster: Node, skill: Resource) -> Resource:
	return get_preview_shape_for_context(SkillCastContext.new(caster, skill))

func get_preview_shape_for_context(context: SkillCastContext) -> Resource:
	if context == null or shape == null or not shape.has_method(&"get_preview_shape_for_context"):
		return null
	return shape.get_preview_shape_for_context(context)

func get_validation_errors(skill: SkillDefinition) -> PackedStringArray:
	var errors := PackedStringArray()
	var skill_label := skill.get_label() if skill != null else "<unnamed skill>"
	if runtime_set == null:
		errors.append("%s shape runtime set targeting runtime_set is required" % skill_label)
	if max_targets < 0:
		errors.append("%s shape runtime set targeting max_targets cannot be negative" % skill_label)
	if shape == null:
		errors.append("%s shape runtime set targeting shape is required" % skill_label)
	else:
		for method_name in [&"contains_target", &"get_preview_shape_for_context", &"get_validation_errors", &"get_debug_label"]:
			if not shape.has_method(method_name):
				errors.append("%s shape runtime set targeting shape %s is missing %s" % [skill_label, _resource_label(shape), method_name])
		if shape.has_method(&"get_validation_errors"):
			for error in shape.get_validation_errors(skill):
				errors.append(error)
	for filter in filters:
		if filter == null:
			continue
		if not filter.has_method(&"accepts_target"):
			errors.append("%s shape runtime set targeting filter %s is missing accepts_target" % [skill_label, _resource_label(filter)])
	return errors

func _accepts_shape(_caster: Node, target: Node, context: SkillCastContext = null) -> bool:
	if shape == null or not shape.has_method(&"contains_target"):
		return false
	return shape.contains_target(context, target)

func _resource_label(value: Resource) -> String:
	if value.resource_path != "":
		return value.resource_path
	if value.has_method(&"get_debug_label"):
		return value.get_debug_label()
	return value.get_class()

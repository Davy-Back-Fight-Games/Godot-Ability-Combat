class_name ResourceRegenerationRule
extends Resource

@export var enabled: bool = true
@export var resource_type: ResourceType
@export var strategy: ResourceRegenerationStrategy
@export var only_when_below_max: bool = true
@export var debug_name: String = ""

func get_validation_errors(stats_component: StatsComponent = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if resource_type == null:
		errors.append("ResourceRegenerationRule requires resource_type.")
	else:
		errors.append_array(resource_type.get_validation_errors())
		if stats_component != null and not stats_component.has_resource(resource_type):
			errors.append("StatsComponent is missing resource '%s'." % resource_type.get_label())
	if strategy == null:
		errors.append("ResourceRegenerationRule requires strategy.")
	else:
		errors.append_array(strategy.get_validation_errors())
	return errors

func is_valid_rule(stats_component: StatsComponent = null) -> bool:
	return get_validation_errors(stats_component).is_empty()

func get_label() -> String:
	if debug_name != "":
		return debug_name
	if resource_type != null:
		return resource_type.get_label()
	return "Resource Regeneration"

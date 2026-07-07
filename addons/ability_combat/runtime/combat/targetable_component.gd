class_name TargetableComponent
extends Node

const LifeStateComponentScript := preload("res://addons/ability_combat/runtime/combat/life_state_component.gd")

@export var targetable: bool = true
@export var health_resource_type: ResourceType
@export var stats_component_path: NodePath = NodePath("../StatsComponent")
@export var required_stats_for_health: bool = false
@export var debug_log: bool = false

@onready var _stats_component: StatsComponent = get_node_or_null(stats_component_path) as StatsComponent

func _ready() -> void:
	_warn_validation_errors()

func is_skill_targetable() -> bool:
	if not targetable:
		return false
	var life_state = LifeStateComponentScript.find_for_node(self)
	if life_state != null:
		return life_state.is_alive()
	if health_resource_type == null:
		return true
	var stats_component := _get_stats_component()
	if stats_component == null or not stats_component.has_resource(health_resource_type):
		return not required_stats_for_health
	return stats_component.get_resource_current(health_resource_type) > 0.0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if required_stats_for_health and health_resource_type != null and _get_stats_component() == null:
		errors.append("TargetableComponent requires a StatsComponent for health targetability.")
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

static func find_for_node(node: Node) -> TargetableComponent:
	if node == null:
		return null
	if node is TargetableComponent:
		return node

	for child in node.get_children():
		if child is TargetableComponent:
			return child

	var parent := node.get_parent()
	if parent != null:
		if parent is TargetableComponent:
			return parent
		for child in parent.get_children():
			if child is TargetableComponent:
				return child

	return null

func _get_stats_component() -> StatsComponent:
	if _stats_component != null:
		return _stats_component
	if not stats_component_path.is_empty():
		_stats_component = get_node_or_null(stats_component_path) as StatsComponent
	if _stats_component != null:
		return _stats_component
	return StatsComponent.find_for_node(self)

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("TargetableComponent validation: %s" % error)

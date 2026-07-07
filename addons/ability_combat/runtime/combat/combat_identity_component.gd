class_name CombatIdentityComponent
extends Node

@export var team: ScriptableEnum
@export var display_name: String = ""
@export var required_team: bool = false
@export var debug_log: bool = false

func _ready() -> void:
	_warn_validation_errors()

func get_label() -> String:
	if display_name != "":
		return display_name
	if team != null:
		return team.get_label()
	return name

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if required_team and team == null:
		errors.append("CombatIdentityComponent requires team.")
	return errors

func is_valid_component() -> bool:
	return get_validation_errors().is_empty()

static func find_for_node(node: Node) -> CombatIdentityComponent:
	if node == null:
		return null
	if node is CombatIdentityComponent:
		return node

	for child in node.get_children():
		if child is CombatIdentityComponent:
			return child

	var parent := node.get_parent()
	if parent != null:
		if parent is CombatIdentityComponent:
			return parent
		for child in parent.get_children():
			if child is CombatIdentityComponent:
				return child

	return null

func _warn_validation_errors() -> void:
	for error in get_validation_errors():
		push_warning("CombatIdentityComponent validation: %s" % error)

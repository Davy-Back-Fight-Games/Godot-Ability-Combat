class_name RuntimeSetMember
extends Node

@export var auto_register: bool = true:
	set(new_value):
		if auto_register == new_value:
			return
		auto_register = new_value
		if not is_inside_tree():
			return
		if auto_register:
			_register()
		else:
			_unregister()

@export var runtime_set: RuntimeSet:
	set(new_value):
		if runtime_set == new_value:
			return
		if is_inside_tree() and auto_register:
			_unregister()
		runtime_set = new_value
		if is_inside_tree() and auto_register:
			_register()

func _enter_tree() -> void:
	if auto_register:
		_register()

func _exit_tree() -> void:
	if auto_register:
		_unregister()

func _register() -> void:
	if runtime_set == null:
		return
	runtime_set.add_item(self)

func _unregister() -> void:
	if runtime_set == null:
		return
	runtime_set.remove_item(self)

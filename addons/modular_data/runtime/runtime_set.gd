@tool
class_name RuntimeSet
extends Resource

signal item_added(item: Node)
signal item_removed(item: Node)

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var debug_log: bool = false

var _items: Array[Node] = []

func add_item(item: Node) -> void:
	if item == null:
		return
	_prune_invalid_items()
	if _items.has(item):
		return
	_items.append(item)
	item_added.emit(item)
	changed.emit()
	_log_changed("added", item)

func remove_item(item: Node) -> void:
	if item == null:
		return
	_prune_invalid_items()
	var index := _items.find(item)
	if index == -1:
		return
	_items.remove_at(index)
	item_removed.emit(item)
	changed.emit()
	_log_changed("removed", item)

func has_item(item: Node) -> bool:
	if item == null:
		return false
	_prune_invalid_items()
	return _items.has(item)

func clear() -> void:
	_prune_invalid_items()
	if _items.is_empty():
		return
	var removed_items := _items.duplicate()
	_items.clear()
	for item in removed_items:
		item_removed.emit(item)
	changed.emit()
	_log_changed("cleared", null)

func get_items() -> Array[Node]:
	_prune_invalid_items()
	return _items.duplicate()

func size() -> int:
	_prune_invalid_items()
	return _items.size()

func is_empty() -> bool:
	_prune_invalid_items()
	return _items.is_empty()

func _prune_invalid_items() -> void:
	var removed_items: Array[Node] = []
	for index in range(_items.size() - 1, -1, -1):
		var item := _items[index]
		if not is_instance_valid(item):
			removed_items.append(item)
			_items.remove_at(index)
	if removed_items.is_empty():
		return
	for item in removed_items:
		item_removed.emit(item)
	changed.emit()
	_log_changed("pruned", null)

func _log_changed(action: String, item: Node) -> void:
	if not debug_log and not ProjectSettings.get_setting("modular_data/debug_log_events", false):
		return
	if item == null:
		print("[RuntimeSet] %s %s size=%s" % [_data_label(), action, _items.size()])
		return
	print("[RuntimeSet] %s %s item=%s size=%s" % [_data_label(), action, item.name, _items.size()])

func _data_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path
	return "<unnamed runtime set>"

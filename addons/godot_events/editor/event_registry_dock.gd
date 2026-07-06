@tool
class_name EventRegistryDock
extends VBoxContainer

var editor_interface: EditorInterface

var _tree: Tree
var _status: Label

func _ready() -> void:
	_build_ui()
	scan()

func _build_ui() -> void:
	if _tree != null:
		return

	var toolbar := HBoxContainer.new()
	add_child(toolbar)

	var rescan_button := Button.new()
	rescan_button.text = "Rescan"
	rescan_button.pressed.connect(scan)
	toolbar.add_child(rescan_button)

	_status = Label.new()
	_status.text = ""
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(_status)

	_tree = Tree.new()
	_tree.columns = 3
	_tree.column_titles_visible = true
	_tree.set_column_title(0, "Event")
	_tree.set_column_title(1, "Role")
	_tree.set_column_title(2, "Reference")
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_activated.connect(_on_item_activated)
	add_child(_tree)

func scan() -> void:
	if _tree == null:
		return

	_tree.clear()
	var root := _tree.create_item()
	root.set_text(0, "TypedGameEvent resources")

	var event_paths := _find_event_resources()
	var usage := {}
	for event_path in event_paths:
		usage[event_path] = {
			"emitters": [],
			"listeners": [],
			"unknown": []
		}

	var files_to_scan := _walk_files("res://", PackedStringArray(["tscn", "tres"]))
	for file_path in files_to_scan:
		_scan_file_for_event_references(file_path, usage)

	event_paths.sort()
	for event_path in event_paths:
		_add_event_item(root, event_path, usage[event_path])

	_status.text = "Found %d event resource(s). Double-click rows to open files." % event_paths.size()

func _add_event_item(root: TreeItem, event_path: String, data: Dictionary) -> void:
	var emitters: Array = data["emitters"]
	var listeners: Array = data["listeners"]
	var unknown: Array = data["unknown"]

	var emitter_count: int = emitters.size()
	var listener_count: int = listeners.size()
	var unknown_count: int = unknown.size()

	var event_item := _tree.create_item(root)
	event_item.set_text(0, event_path.get_file())
	event_item.set_text(1, "%d out / %d in / %d ?" % [emitter_count, listener_count, unknown_count])
	event_item.set_text(2, event_path)
	event_item.set_metadata(0, {"path": event_path})

	if not emitters.is_empty():
		_add_usage_group(event_item, "Emitters", "emitter", emitters)

	if not listeners.is_empty():
		_add_usage_group(event_item, "Listeners", "listener", listeners)

	if not unknown.is_empty():
		_add_usage_group(event_item, "Unknown", "unknown", unknown)

func _add_usage_group(parent: TreeItem, label: String, role: String, rows: Array) -> void:
	var group := _tree.create_item(parent)
	group.set_text(0, label)
	group.set_text(1, str(rows.size()))

	for row in rows:
		var item := _tree.create_item(group)
		item.set_text(0, row["file"].get_file())
		item.set_text(1, role)
		item.set_text(2, "%s :: %s" % [row["file"], row["property"]])
		item.set_metadata(0, {"path": row["file"]})

func _find_event_resources() -> PackedStringArray:
	var result := PackedStringArray()
	var resource_files := _walk_files("res://", PackedStringArray(["tres", "res"]))

	for path in resource_files:
		if _is_game_event_resource(path):
			result.append(path)

	return result

func _is_game_event_resource(path: String) -> bool:
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null:
		return false

	var typed_game_event_script_path := _get_global_script_path(&"TypedGameEvent")
	var script := res.get_script()
	while script != null:
		if script.resource_path == typed_game_event_script_path:
			return true
		script = script.get_base_script()

	return false

func _scan_file_for_event_references(file_path: String, usage: Dictionary) -> void:
	var text := FileAccess.get_file_as_string(file_path)
	if text == "":
		return

	var ext_resource_paths := _parse_ext_resource_paths(text)
	if ext_resource_paths.is_empty():
		return

	var prop_re := RegEx.new()
	prop_re.compile("(?m)^\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*ExtResource\\(\"([^\"]+)\"\\)")
	var script_re := RegEx.new()
	script_re.compile("^\\s*script\\s*=\\s*ExtResource\\(\"([^\"]+)\"\\)")

	var script_extends_listener_cache := {}
	if file_path.ends_with(".tscn"):
		var in_node := false
		var current_node_script_path := ""
		var current_node_references := []

		for line in text.split("\n"):
			if line.begins_with("["):
				_record_node_event_references(file_path, usage, ext_resource_paths, current_node_references, current_node_script_path, script_extends_listener_cache)
				in_node = line.begins_with("[node")
				current_node_script_path = ""
				current_node_references = []
				continue

			if in_node:
				var script_match := script_re.search(line)
				if script_match != null:
					var script_ext_id := script_match.get_string(1)
					if ext_resource_paths.has(script_ext_id):
						current_node_script_path = ext_resource_paths[script_ext_id]
					continue

				var node_prop_match := prop_re.search(line)
				if node_prop_match != null:
					current_node_references.append({
						"property": node_prop_match.get_string(1),
						"ext_id": node_prop_match.get_string(2)
					})
			else:
				var prop_match := prop_re.search(line)
				if prop_match != null:
					_record_event_reference(file_path, usage, ext_resource_paths, prop_match.get_string(1), prop_match.get_string(2), "", script_extends_listener_cache)

		_record_node_event_references(file_path, usage, ext_resource_paths, current_node_references, current_node_script_path, script_extends_listener_cache)
		return

	for match in prop_re.search_all(text):
		_record_event_reference(file_path, usage, ext_resource_paths, match.get_string(1), match.get_string(2), "", script_extends_listener_cache)

func _record_node_event_references(file_path: String, usage: Dictionary, ext_resource_paths: Dictionary, references: Array, node_script_path: String, script_extends_listener_cache: Dictionary) -> void:
	for reference in references:
		_record_event_reference(file_path, usage, ext_resource_paths, reference["property"], reference["ext_id"], node_script_path, script_extends_listener_cache)

func _record_event_reference(file_path: String, usage: Dictionary, ext_resource_paths: Dictionary, property_name: String, ext_id: String, node_script_path: String, script_extends_listener_cache: Dictionary) -> void:
	if not ext_resource_paths.has(ext_id):
		return

	var referenced_path: String = ext_resource_paths[ext_id]
	if not usage.has(referenced_path):
		return

	var role := _classify_property_name(property_name)
	if role == "unknown" and property_name.to_lower() == "event" and _script_extends_event_listener_node(node_script_path, script_extends_listener_cache):
		role = "listeners"

	usage[referenced_path][role].append({
		"file": file_path,
		"property": property_name
	})

func _parse_ext_resource_paths(text: String) -> Dictionary:
	var result := {}
	var ext_re := RegEx.new()
	ext_re.compile("(?m)^\\[ext_resource([^\\]]*)\\]")

	for match in ext_re.search_all(text):
		var attributes := _parse_resource_attributes(match.get_string(1))
		if attributes.has("path") and attributes.has("id"):
			result[attributes["id"]] = attributes["path"]

	return result

func _parse_resource_attributes(text: String) -> Dictionary:
	var result := {}
	var attr_re := RegEx.new()
	attr_re.compile("([A-Za-z_][A-Za-z0-9_]*)=\"([^\"]*)\"")

	for match in attr_re.search_all(text):
		result[match.get_string(1)] = match.get_string(2)

	return result

func _script_extends_event_listener_node(script_path: String, cache: Dictionary) -> bool:
	if script_path == "":
		return false
	if cache.has(script_path):
		return cache[script_path]

	var extends_listener := false
	var event_listener_node_script_path := _get_global_script_path(&"EventListenerNode")
	var script := ResourceLoader.load(script_path, "Script", ResourceLoader.CACHE_MODE_REUSE) as Script
	while script != null:
		if script.resource_path == event_listener_node_script_path:
			extends_listener = true
			break
		script = script.get_base_script()

	cache[script_path] = extends_listener
	return extends_listener

func _get_global_script_path(class_name_value: StringName) -> String:
	for global_class in ProjectSettings.get_global_class_list():
		if StringName(global_class.get("class", "")) == class_name_value:
			return global_class.get("path", "")
	return ""

func _classify_property_name(property_name: String) -> String:
	var p := property_name.to_lower()

	if p.begins_with("emits_") or p.begins_with("emit_") or p.ends_with("_out") or p.contains("events_out"):
		return "emitters"

	if p.begins_with("listens_") or p.begins_with("listen_") or p.ends_with("_in") or p.contains("events_in"):
		return "listeners"

	return "unknown"

func _walk_files(dir_path: String, extensions: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	_walk_files_inner(dir_path, extensions, result)
	return result

func _walk_files_inner(dir_path: String, extensions: PackedStringArray, result: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := dir_path.path_join(file_name)
		if dir.current_is_dir():
			_walk_files_inner(full_path, extensions, result)
		else:
			var ext := file_name.get_extension().to_lower()
			if extensions.has(ext):
				result.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _on_item_activated() -> void:
	var selected := _tree.get_selected()
	if selected == null:
		return

	var metadata = selected.get_metadata(0)
	if typeof(metadata) != TYPE_DICTIONARY or not metadata.has("path"):
		return

	_open_path(str(metadata["path"]))

func _open_path(path: String) -> void:
	if editor_interface == null:
		return

	if path.ends_with(".tscn"):
		editor_interface.open_scene_from_path(path)
		return

	var res := ResourceLoader.load(path)
	if res == null:
		return

	if path.ends_with(".gd"):
		editor_interface.edit_script(res)
	else:
		editor_interface.edit_resource(res)

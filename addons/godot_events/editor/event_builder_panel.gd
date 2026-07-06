@tool
class_name EventBuilderPanel
extends VBoxContainer

const GENERATED_SCRIPTS_DEFAULT := "res://events"
const EVENT_RESOURCES_DEFAULT := "res://events"

signal event_generated(resource_path: String)

var editor_interface: EditorInterface

var _display_name_edit: LineEdit
var _description_edit: LineEdit
var _category_edit: LineEdit
var _debug_log_check: CheckBox
var _event_id_edit: LineEdit
var _payload_class_edit: LineEdit
var _payload_script_edit: LineEdit
var _payload_script_dialog: EditorFileDialog
var _event_class_edit: LineEdit
var _listener_class_edit: LineEdit
var _generated_scripts_folder_edit: LineEdit
var _event_resources_folder_edit: LineEdit
var _event_path_preview: LineEdit
var _listener_path_preview: LineEdit
var _resource_path_preview: LineEdit
var _validation_list: ItemList
var _generate_button: Button
var _status_label: Label

var _event_id_edited := false
var _payload_class_edited := false
var _payload_script_edited := false
var _event_class_edited := false
var _listener_class_edited := false
var _updating_from_code := false
var _built := false

func _ready() -> void:
	_build_ui()
	_refresh_validation()

func _build_ui() -> void:
	if _built:
		return
	_built = true

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(toolbar)

	var title := Label.new()
	title.text = "Typed Event Builder"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title)

	_status_label = Label.new()
	_status_label.text = "Fill required fields to enable Generate."
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(_status_label)

	_generate_button = Button.new()
	_generate_button.text = "Generate"
	_generate_button.disabled = true
	_generate_button.pressed.connect(_on_generate_pressed)
	toolbar.add_child(_generate_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_build_metadata_section(content)
	_build_payload_section(content)
	_build_names_section(content)
	_build_folders_section(content)
	_build_preview_section(content)
	_build_validation_section(content)

func _build_metadata_section(parent: Control) -> void:
	var section := _add_section(parent, "Event Metadata")
	var grid := _add_grid(section)

	_display_name_edit = _add_line_edit_row(grid, "Display Name", "Player Died")
	_display_name_edit.text_changed.connect(_on_display_name_changed)

	_description_edit = _add_line_edit_row(grid, "Description", "Raised when something important happens.")
	_description_edit.text_changed.connect(_on_any_text_changed)

	_category_edit = _add_line_edit_row(grid, "Category", "General")
	_category_edit.text = "General"
	_category_edit.text_changed.connect(_on_any_text_changed)

	var debug_label := Label.new()
	debug_label.text = "Debug Log"
	grid.add_child(debug_label)

	_debug_log_check = CheckBox.new()
	_debug_log_check.text = "Print event emissions by default"
	_debug_log_check.toggled.connect(_on_any_toggled)
	grid.add_child(_debug_log_check)

func _build_payload_section(parent: Control) -> void:
	var section := _add_section(parent, "Payload Type")
	var description := Label.new()
	description.text = "Define payload data in a typed GDScript class, then link that script here. The builder will use this payload type when generating the event and listener node scripts."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section.add_child(description)

	var grid := _add_grid(section)
	_payload_class_edit = _add_line_edit_row(grid, "Payload Class", "ThingHappenedPayload")
	_payload_class_edit.text_changed.connect(_on_payload_class_changed)

	var payload_script_label := Label.new()
	payload_script_label.text = "Payload Script"
	grid.add_child(payload_script_label)

	var payload_script_row := HBoxContainer.new()
	payload_script_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(payload_script_row)

	_payload_script_edit = LineEdit.new()
	_payload_script_edit.placeholder_text = "res://events/thing_happened_payload.gd"
	_payload_script_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_payload_script_edit.text_changed.connect(_on_payload_script_changed)
	payload_script_row.add_child(_payload_script_edit)

	var browse_payload_script_button := Button.new()
	browse_payload_script_button.text = "Browse"
	browse_payload_script_button.pressed.connect(_on_browse_payload_script_pressed)
	payload_script_row.add_child(browse_payload_script_button)

	var create_payload_script_button := Button.new()
	create_payload_script_button.text = "Create Payload Script"
	create_payload_script_button.pressed.connect(_on_create_payload_script_pressed)
	payload_script_row.add_child(create_payload_script_button)

	_payload_script_dialog = EditorFileDialog.new()
	_payload_script_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_payload_script_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_payload_script_dialog.filters = PackedStringArray(["*.gd ; GDScript"])
	_payload_script_dialog.file_selected.connect(_on_payload_script_file_selected)
	add_child(_payload_script_dialog)

func _build_names_section(parent: Control) -> void:
	var section := _add_section(parent, "Generated Names")
	var grid := _add_grid(section)

	_event_id_edit = _add_line_edit_row(grid, "Event ID", "skill_started")
	_event_id_edit.text_changed.connect(_on_event_id_changed)

	_event_class_edit = _add_line_edit_row(grid, "Event Class", "SkillStartedEvent")
	_event_class_edit.text_changed.connect(_on_event_class_changed)

	_listener_class_edit = _add_line_edit_row(grid, "Listener Node Class", "SkillStartedEventListenerNode")
	_listener_class_edit.text_changed.connect(_on_listener_class_changed)

func _build_folders_section(parent: Control) -> void:
	var section := _add_section(parent, "Generated Output Folders")
	var grid := _add_grid(section)

	_generated_scripts_folder_edit = _add_line_edit_row(grid, "Generated Scripts Folder", GENERATED_SCRIPTS_DEFAULT)
	_generated_scripts_folder_edit.text = GENERATED_SCRIPTS_DEFAULT
	_generated_scripts_folder_edit.text_changed.connect(_on_any_text_changed)

	_event_resources_folder_edit = _add_line_edit_row(grid, "Event Resources Folder", EVENT_RESOURCES_DEFAULT)
	_event_resources_folder_edit.text = EVENT_RESOURCES_DEFAULT
	_event_resources_folder_edit.text_changed.connect(_on_any_text_changed)

func _build_preview_section(parent: Control) -> void:
	var section := _add_section(parent, "Generated Path Preview")
	var grid := _add_grid(section)

	_event_path_preview = _add_readonly_path_row(grid, "Event Script")
	_listener_path_preview = _add_readonly_path_row(grid, "Listener Node Script")
	_resource_path_preview = _add_readonly_path_row(grid, "Event Resource")

func _build_validation_section(parent: Control) -> void:
	var section := _add_section(parent, "Validation")
	_validation_list = ItemList.new()
	_validation_list.custom_minimum_size = Vector2(0, 110)
	_validation_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(_validation_list)

func _add_section(parent: Control, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var label := Label.new()
	label.text = title
	box.add_child(label)

	return box

func _add_grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	return grid

func _add_line_edit_row(parent: GridContainer, label_text: String, placeholder: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)

	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(edit)
	return edit

func _add_readonly_path_row(parent: GridContainer, label_text: String) -> LineEdit:
	var edit := _add_line_edit_row(parent, label_text, "")
	edit.editable = false
	return edit

func _on_display_name_changed(_new_text: String) -> void:
	if not _event_id_edited:
		_set_event_id_from_display_name()
	_refresh_validation()

func _on_event_id_changed(_new_text: String) -> void:
	if not _updating_from_code:
		_event_id_edited = true
	_sync_generated_names_from_event_id()
	_refresh_validation()

func _on_payload_class_changed(_new_text: String) -> void:
	if not _updating_from_code:
		_payload_class_edited = true
	_refresh_validation()

func _on_payload_script_changed(_new_text: String) -> void:
	if not _updating_from_code:
		_payload_script_edited = true
	_refresh_validation()

func _on_event_class_changed(_new_text: String) -> void:
	if not _updating_from_code:
		_event_class_edited = true
	_refresh_validation()

func _on_listener_class_changed(_new_text: String) -> void:
	if not _updating_from_code:
		_listener_class_edited = true
	_refresh_validation()

func _on_any_text_changed(_new_text: String) -> void:
	_refresh_validation()

func _on_any_toggled(_button_pressed: bool) -> void:
	_refresh_validation()

func _on_browse_payload_script_pressed() -> void:
	var current_path := _payload_script_edit.text.strip_edges()
	if current_path.begins_with("res://"):
		_payload_script_dialog.current_path = current_path
	else:
		_payload_script_dialog.current_dir = "res://"
	_payload_script_dialog.popup_centered_ratio(0.75)

func _on_payload_script_file_selected(path: String) -> void:
	var payload_script := _to_res_path(path)
	_updating_from_code = true
	_payload_script_edit.text = payload_script
	_payload_script_edited = true

	var source := FileAccess.get_file_as_string(payload_script) if FileAccess.file_exists(payload_script) else ""
	var declared_class_name := _find_gdscript_declaration(source, "class_name")
	if declared_class_name != "":
		_payload_class_edit.text = declared_class_name
		_payload_class_edited = true
	_updating_from_code = false
	_refresh_validation()

func _on_create_payload_script_pressed() -> void:
	var payload_class := _payload_class_edit.text.strip_edges()
	var payload_script := _payload_script_edit.text.strip_edges()
	var errors: Array[String] = []
	_validate_class_name(errors, payload_class, "Payload Class", "Payload")
	_validate_output_path(errors, payload_script, "Payload Script", ".gd")
	if not errors.is_empty():
		_status_label.text = "Payload script creation blocked: %s" % errors[0]
		return

	if FileAccess.file_exists(payload_script):
		_status_label.text = "Payload script creation blocked: file already exists: %s." % payload_script
		return

	if not _ensure_parent_dir(payload_script):
		_status_label.text = "Failed to create folder for %s." % payload_script
		return

	if not _write_text_file(payload_script, _build_payload_script_source()):
		_status_label.text = "Failed to write payload script: %s." % payload_script
		return

	_refresh_editor_filesystem([payload_script])
	await get_tree().process_frame
	_refresh_validation()
	_open_generated_script(payload_script)
	_status_label.text = "Created payload script: %s." % payload_script

func _on_generate_pressed() -> void:
	var errors := _get_validation_errors()
	if not errors.is_empty():
		_refresh_validation()
		_status_label.text = "Generation blocked: fix %d validation error(s)." % errors.size()
		return

	var event_script_path := _event_path_preview.text.strip_edges()
	var listener_script_path := _listener_path_preview.text.strip_edges()
	var resource_path := _resource_path_preview.text.strip_edges()

	for path in [event_script_path, listener_script_path, resource_path]:
		if not _ensure_parent_dir(path):
			_status_label.text = "Failed to create folder for %s." % path
			return

	if not _write_text_file(event_script_path, _build_event_script_source()):
		_status_label.text = "Failed to write event script: %s." % event_script_path
		return

	if not _write_text_file(listener_script_path, _build_listener_script_source()):
		_status_label.text = "Failed to write listener node script: %s." % listener_script_path
		return

	_refresh_editor_filesystem([event_script_path, listener_script_path])
	await get_tree().process_frame

	var event_script := ResourceLoader.load(event_script_path, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if event_script == null:
		_status_label.text = "Scripts were written, but Godot has not loaded %s yet. Wait for the filesystem scan, then retry creating the resource." % event_script_path
		return

	var event_resource := event_script.new() as TypedGameEvent
	if event_resource == null:
		_status_label.text = "Failed to instantiate generated event script: %s." % event_script_path
		return

	event_resource.display_name = _display_name_edit.text.strip_edges()
	event_resource.description = _description_edit.text.strip_edges()
	event_resource.category = StringName(_category_edit.text.strip_edges())
	event_resource.debug_log = _debug_log_check.button_pressed

	var save_result := ResourceSaver.save(event_resource, resource_path)
	if save_result != OK:
		_status_label.text = "Failed to save event resource %s: %s." % [resource_path, error_string(save_result)]
		return

	_refresh_editor_filesystem([resource_path])
	event_generated.emit(resource_path)
	_open_generated_resource(resource_path)
	_status_label.text = "Generated event, listener node, and resource: %s." % resource_path

func _set_event_id_from_display_name() -> void:
	_updating_from_code = true
	_event_id_edit.text = _to_snake_case(_display_name_edit.text)
	_updating_from_code = false
	_sync_generated_names_from_event_id()

func _sync_generated_names_from_event_id() -> void:
	var base_name := _to_pascal_case(_event_id_edit.text)
	_updating_from_code = true
	if not _payload_class_edited:
		_payload_class_edit.text = base_name + "Payload" if base_name != "" else ""
	if not _payload_script_edited:
		_payload_script_edit.text = _join_res_path(_generated_scripts_folder_edit.text, _event_id_edit.text + "_payload.gd") if _event_id_edit.text != "" else ""
	if not _event_class_edited:
		_event_class_edit.text = base_name + "Event" if base_name != "" else ""
	if not _listener_class_edited:
		_listener_class_edit.text = base_name + "EventListenerNode" if base_name != "" else ""
	_updating_from_code = false

func _refresh_validation() -> void:
	if _validation_list == null:
		return

	_update_path_preview()

	var errors := _get_validation_errors()

	_validation_list.clear()
	for error in errors:
		_validation_list.add_item("Error: " + error)
	if errors.is_empty():
		_validation_list.add_item("No validation issues.")

	_generate_button.disabled = not errors.is_empty()
	_status_label.text = "Fix %d validation error(s)." % errors.size() if not errors.is_empty() else "Ready to generate."

func _get_validation_errors() -> Array[String]:
	_update_path_preview()
	var errors: Array[String] = []
	_validate_event_metadata(errors)
	_validate_payload_type(errors)
	_validate_names(errors)
	_validate_folders(errors)
	_validate_targets(errors)
	return errors

func _validate_event_metadata(errors: Array[String]) -> void:
	if _display_name_edit.text.strip_edges() == "":
		errors.append("Display Name is required.")

func _validate_payload_type(errors: Array[String]) -> void:
	_validate_class_name(errors, _payload_class_edit.text.strip_edges(), "Payload Class", "Payload")
	var payload_script := _payload_script_edit.text.strip_edges()
	if not payload_script.begins_with("res://"):
		errors.append("Payload Script must start with res://.")
	if not payload_script.ends_with(".gd"):
		errors.append("Payload Script must end with .gd.")
	if payload_script.contains(".godot") or payload_script.contains(".import"):
		errors.append("Payload Script must not contain .godot or .import.")
	if not FileAccess.file_exists(payload_script):
		errors.append("Payload Script must exist.")
		return

	var source := FileAccess.get_file_as_string(payload_script)
	var declared_class_name := _find_gdscript_declaration(source, "class_name")
	if declared_class_name != _payload_class_edit.text.strip_edges():
		errors.append("Payload Script class_name must match Payload Class.")

	if not _payload_script_extends_game_event_payload(payload_script, source):
		errors.append("Payload Script must extend GameEventPayload.")

func _validate_names(errors: Array[String]) -> void:
	var event_id := _event_id_edit.text.strip_edges()
	if not _matches(event_id, "^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$"):
		errors.append("Event ID must be snake_case with no leading, trailing, or double underscores.")

	_validate_class_name(errors, _event_class_edit.text.strip_edges(), "Event Class", "Event")
	_validate_class_name(errors, _listener_class_edit.text.strip_edges(), "Listener Node Class", "EventListenerNode")

func _validate_class_name(errors: Array[String], value: String, label: String, suffix: String) -> void:
	if not _matches(value, "^[A-Z][A-Za-z0-9]*$"):
		errors.append("%s must be a valid PascalCase class name." % label)
		return
	if not value.ends_with(suffix):
		errors.append("%s must end with %s." % [label, suffix])

func _validate_folders(errors: Array[String]) -> void:
	_validate_folder(errors, _generated_scripts_folder_edit.text.strip_edges(), "Generated Scripts Folder")
	_validate_folder(errors, _event_resources_folder_edit.text.strip_edges(), "Event Resources Folder")

func _validate_folder(errors: Array[String], value: String, label: String) -> void:
	if not value.begins_with("res://"):
		errors.append("%s must start with res://." % label)
	if value.contains(".godot") or value.contains(".import"):
		errors.append("%s must not contain .godot or .import." % label)

func _validate_targets(errors: Array[String]) -> void:
	for row in [
		["Event Script", _event_path_preview.text.strip_edges(), ".gd"],
		["Listener Node Script", _listener_path_preview.text.strip_edges(), ".gd"],
		["Event Resource", _resource_path_preview.text.strip_edges(), ".tres"]
	]:
		var label: String = row[0]
		var path: String = row[1]
		var extension: String = row[2]
		if not _validate_output_path(errors, path, label, extension):
			continue
		if FileAccess.file_exists(path):
			errors.append("%s already exists: %s." % [label, path])

func _validate_output_path(errors: Array[String], path: String, label: String, extension: String) -> bool:
	if not path.begins_with("res://"):
		errors.append("%s path must start with res://." % label)
		return false
	if path.contains(".godot") or path.contains(".import"):
		errors.append("%s path must not contain .godot or .import." % label)
		return false
	if not path.ends_with(extension):
		errors.append("%s path must end with %s." % [label, extension])
		return false
	return true

func _update_path_preview() -> void:
	var event_id := _event_id_edit.text.strip_edges()
	if event_id == "":
		_event_path_preview.text = ""
		_listener_path_preview.text = ""
		_resource_path_preview.text = ""
		return

	var generated_folder := _generated_scripts_folder_edit.text.strip_edges()
	var resource_folder := _event_resources_folder_edit.text.strip_edges()
	_event_path_preview.text = _join_res_path(generated_folder, event_id + "_event.gd")
	_listener_path_preview.text = _join_res_path(generated_folder, event_id + "_event_listener_node.gd")
	_resource_path_preview.text = _join_res_path(resource_folder, event_id + ".tres")

func _build_payload_script_source() -> String:
	var payload_class := _payload_class_edit.text.strip_edges()
	return "".join([
		"@tool\n",
		"class_name %s\n" % payload_class,
		"extends GameEventPayload\n",
		"\n",
		"func to_log_text() -> String:\n",
		"\treturn \"%s\"\n" % payload_class
	])

func _build_event_script_source() -> String:
	var event_class := _event_class_edit.text.strip_edges()
	var payload_class := _payload_class_edit.text.strip_edges()
	return "".join([
		"@tool\n",
		"class_name %s\n" % event_class,
		"extends TypedGameEvent\n",
		"\n",
		"signal raised(payload: %s)\n" % payload_class,
		"\n",
		"func emit(payload: %s, emitter: Object = null) -> void:\n" % payload_class,
		"\t_log_emit(payload, emitter)\n",
		"\traised.emit(payload)\n",
		"\n",
		"func get_payload_script() -> Script:\n",
		"\treturn %s\n" % payload_class
	])

func _build_listener_script_source() -> String:
	var event_class := _event_class_edit.text.strip_edges()
	var listener_class := _listener_class_edit.text.strip_edges()
	var payload_class := _payload_class_edit.text.strip_edges()
	return "".join([
		"class_name %s\n" % listener_class,
		"extends EventListenerNode\n",
		"\n",
		"@export var event: %s:\n" % event_class,
		"\tset(value):\n",
		"\t\tif not _prepare_event_assignment(event, value):\n",
		"\t\t\treturn\n",
		"\t\tevent = value\n",
		"\t\t_finish_event_assignment()\n",
		"\n",
		"signal raised(payload: %s)\n" % payload_class,
		"\n",
		"func _get_event() -> TypedGameEvent:\n",
		"\treturn event\n",
		"\n",
		"func _get_event_raised_callable() -> Callable:\n",
		"\treturn _on_event_raised\n",
		"\n",
		"func _on_event_raised(payload: %s) -> void:\n" % payload_class,
		"\t_log_event_received(payload)\n",
		"\traised.emit(payload)\n"
	])

func _ensure_parent_dir(path: String) -> bool:
	if not path.begins_with("res://") or path.contains(".godot") or path.contains(".import"):
		return false

	var folder := path.get_base_dir()
	var absolute_folder := ProjectSettings.globalize_path(folder)
	return DirAccess.make_dir_recursive_absolute(absolute_folder) == OK

func _write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	return true

func _refresh_editor_filesystem(paths: Array) -> void:
	if editor_interface == null:
		return

	var filesystem := editor_interface.get_resource_filesystem()
	if filesystem == null:
		return

	for path in paths:
		filesystem.update_file(path)
	filesystem.scan()

func _open_generated_resource(resource_path: String) -> void:
	if editor_interface == null:
		return

	var resource := ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource != null:
		editor_interface.edit_resource(resource)

func _open_generated_script(script_path: String) -> void:
	if editor_interface == null:
		return

	var script := ResourceLoader.load(script_path, "Script", ResourceLoader.CACHE_MODE_IGNORE) as Script
	if script != null:
		editor_interface.edit_script(script)

func _find_gdscript_declaration(source: String, keyword: String) -> String:
	var regex := RegEx.new()
	if regex.compile("(?m)^\\s*%s\\s+([A-Za-z_][A-Za-z0-9_]*)" % keyword) != OK:
		return ""

	var match := regex.search(source)
	return match.get_string(1) if match != null else ""

func _payload_script_extends_game_event_payload(payload_script_path: String, source: String) -> bool:
	var script := ResourceLoader.load(payload_script_path, "Script", ResourceLoader.CACHE_MODE_REUSE) as Script
	if script != null:
		var game_event_payload_script_path := _get_global_script_path(&"GameEventPayload")
		var base_script: Script = script.get_base_script()
		while base_script != null:
			if base_script.resource_path == game_event_payload_script_path:
				return true
			base_script = base_script.get_base_script()

	return _find_gdscript_declaration(source, "extends") == "GameEventPayload"

func _get_global_script_path(class_name_value: StringName) -> String:
	for global_class in ProjectSettings.get_global_class_list():
		if StringName(global_class.get("class", "")) == class_name_value:
			return global_class.get("path", "")
	return ""

func _join_res_path(folder: String, file_name: String) -> String:
	var base := folder.strip_edges()
	while base.ends_with("/") and base != "res://":
		base = base.trim_suffix("/")
	if base == "" or base == "res://":
		return base + file_name
	return base + "/" + file_name

func _to_res_path(path: String) -> String:
	if path.begins_with("res://"):
		return path
	return ProjectSettings.localize_path(path)

func _to_snake_case(value: String) -> String:
	var result := ""
	var previous_was_separator := true
	for index in value.length():
		var character := value.substr(index, 1)
		var code := character.unicode_at(0)
		var is_upper := code >= 65 and code <= 90
		var is_lower := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57

		if is_upper:
			if not previous_was_separator and result != "":
				result += "_"
			result += character.to_lower()
			previous_was_separator = false
		elif is_lower or is_digit:
			result += character.to_lower()
			previous_was_separator = false
		else:
			if not previous_was_separator and result != "":
				result += "_"
			previous_was_separator = true

	return result.trim_suffix("_")

func _to_pascal_case(event_id: String) -> String:
	var result := ""
	for part in event_id.split("_", false):
		if part == "":
			continue
		result += part.substr(0, 1).to_upper() + part.substr(1).to_lower()
	return result

func _matches(value: String, pattern: String) -> bool:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return false
	return regex.search(value) != null

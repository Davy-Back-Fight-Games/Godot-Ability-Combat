@tool
class_name TypedGameEvent
extends Resource

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: StringName = &"General"
@export var debug_log: bool = false

func _log_emit(payload: GameEventPayload, emitter: Object = null) -> void:
	if not debug_log and not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return

	var emitter_text := "<unknown>"
	if emitter != null:
		emitter_text = str(emitter)

	var payload_text := "<null>"
	if payload != null:
		payload_text = payload.to_log_text()

	print("[TypedGameEvent] %s emitted by %s payload=%s" % [_event_label(), emitter_text, payload_text])

func _event_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path
	return "<unnamed event>"

func get_payload_script() -> Script:
	return null

func get_payload_class_name() -> StringName:
	var payload_script := get_payload_script()
	if payload_script == null:
		return &"GameEventPayload"

	var source := payload_script.source_code
	var class_re := RegEx.new()
	class_re.compile("(?m)^\\s*class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var match := class_re.search(source)
	if match == null:
		return &"GameEventPayload"

	return StringName(match.get_string(1))

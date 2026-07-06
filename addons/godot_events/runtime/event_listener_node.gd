class_name EventListenerNode
extends Node

func _enter_tree() -> void:
	_connect_event()

func _exit_tree() -> void:
	_disconnect_event()

func _prepare_event_assignment(current_event: TypedGameEvent, next_event: TypedGameEvent) -> bool:
	if current_event == next_event:
		return false
	if is_inside_tree() and current_event != null:
		_disconnect_from_event(current_event)
	return true

func _finish_event_assignment() -> void:
	if is_inside_tree():
		_connect_event()

func _connect_event() -> void:
	var event := _get_event()
	if event == null:
		_log_missing_event()
		return

	_connect_to_event(event)

func _disconnect_event() -> void:
	var event := _get_event()
	if event != null:
		_disconnect_from_event(event)

func _connect_to_event(event: TypedGameEvent) -> void:
	var callback := _get_event_raised_callable()
	if not event.is_connected(&"raised", callback):
		event.connect(&"raised", callback)
		_log_event_listener("connected", event)

func _disconnect_from_event(event: TypedGameEvent) -> void:
	var callback := _get_event_raised_callable()
	if event.is_connected(&"raised", callback):
		event.disconnect(&"raised", callback)
		_log_event_listener("disconnected", event)

func _log_event_received(payload: GameEventPayload) -> void:
	var event := _get_event()
	if event == null or not _should_log_listener(event):
		return

	var payload_text := "<null>"
	if payload != null:
		payload_text = payload.to_log_text()

	print("[EventListenerNode] %s received %s payload=%s" % [name, _event_label(event), payload_text])

func _get_event() -> TypedGameEvent:
	return null

func _get_event_raised_callable() -> Callable:
	return Callable()

func _log_missing_event() -> void:
	if not ProjectSettings.get_setting("event_channels/debug_log_events", false):
		return
	print("[EventListenerNode] %s has no event assigned" % name)

func _log_event_listener(action: String, event: TypedGameEvent) -> void:
	if not _should_log_listener(event):
		return
	print("[EventListenerNode] %s %s %s" % [name, action, _event_label(event)])

func _should_log_listener(event: TypedGameEvent) -> bool:
	return event.debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)

func _event_label(event: TypedGameEvent) -> String:
	if event.display_name != "":
		return event.display_name
	if event.resource_path != "":
		return event.resource_path
	return "<unnamed event>"

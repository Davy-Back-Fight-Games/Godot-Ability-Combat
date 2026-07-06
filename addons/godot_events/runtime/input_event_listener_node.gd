class_name InputEventListenerNode
extends Node

enum PollProcess {
	IDLE,
	PHYSICS,
}

@export var input_event: Resource
@export var enabled: bool = true
@export var poll_process: PollProcess = PollProcess.IDLE

signal triggered
signal triggered_with_context(input_event: Resource, listener: InputEventListenerNode)

func _process(_delta: float) -> void:
	if poll_process != PollProcess.IDLE:
		return

	_poll_input_event()

func _physics_process(_delta: float) -> void:
	if poll_process != PollProcess.PHYSICS:
		return

	_poll_input_event()

func _poll_input_event() -> void:
	if not enabled:
		return

	if input_event == null:
		return

	if not input_event.has_method("is_triggered"):
		return

	if input_event.is_triggered():
		if input_event.has_method("log_trigger"):
			input_event.log_trigger(self)
		triggered.emit()
		triggered_with_context.emit(input_event, self)

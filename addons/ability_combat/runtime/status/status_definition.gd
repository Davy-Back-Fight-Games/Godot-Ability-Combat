class_name StatusDefinition
extends Resource

const TimeDurationPattern = preload("res://addons/ability_combat/runtime/time/time_duration_pattern.gd")

enum DurationMode { TIMED, INFINITE, INSTANT }
enum StackingPolicy { REPLACE_MATCH, REFRESH_MATCH, STACK_INDEPENDENTLY, EXTEND_MATCH, IGNORE_IF_MATCH, ADD_STACK }
enum StackMatchMode { SAME_STATUS_TYPE, SAME_STACK_GROUP, SAME_DEFINITION }

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var status_type: StatusType
@export var categories: Array[StatusCategory] = []
@export var tags: Array[StatusTag] = []
@export var stack_group: StatusType
@export var duration_mode: DurationMode = DurationMode.TIMED
@export var duration_pattern: TimeDurationPattern
@export var stacking_policy: StackingPolicy = StackingPolicy.REPLACE_MATCH
@export var stack_match_mode: StackMatchMode = StackMatchMode.SAME_STATUS_TYPE
@export var max_stacks: int = 1
@export var refresh_duration_on_stack: bool = true
@export var dispellable: bool = true
@export var cleanseable: bool = true
@export var expires_on_death: bool = true
@export var modules: Array[StatusEffectModule] = []
@export var debug_log: bool = false

func get_duration() -> float:
	if duration_mode != DurationMode.TIMED:
		return 0.0
	if duration_pattern != null:
		return duration_pattern.get_duration_seconds()
	return 0.0

func is_timed() -> bool:
	return duration_mode == DurationMode.TIMED

func is_infinite() -> bool:
	return duration_mode == DurationMode.INFINITE

func is_instant() -> bool:
	return duration_mode == DurationMode.INSTANT

func get_label() -> String:
	if display_name != "":
		return display_name
	if resource_path != "":
		return resource_path.get_file().get_basename().capitalize()
	return "<unnamed status>"

func has_category(category) -> bool:
	return category != null and category in categories

func has_tag(tag) -> bool:
	return tag != null and tag in tags

func get_stack_key():
	match stack_match_mode:
		StackMatchMode.SAME_STACK_GROUP:
			return stack_group if stack_group != null else status_type
		StackMatchMode.SAME_DEFINITION:
			return self
		_:
			return status_type

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if duration_pattern != null:
		if duration_mode != DurationMode.TIMED:
			errors.append("%s duration_pattern is assigned but duration_mode is not TIMED." % get_label())
		for error in duration_pattern.get_validation_errors():
			errors.append("%s duration_pattern %s" % [get_label(), error])
		if duration_mode == DurationMode.TIMED and duration_pattern.infinite:
			errors.append("%s duration_pattern is infinite on a TIMED status; use INFINITE duration_mode unless timed runtime semantics are required." % get_label())
	return errors

func _should_log() -> bool:
	return debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)

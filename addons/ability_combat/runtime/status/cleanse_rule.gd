class_name CleanseRule
extends Resource

enum MatchMode { ANY, ALL }
enum SelectionPolicy { OLDEST_FIRST, NEWEST_FIRST, SHORTEST_REMAINING_FIRST, LONGEST_REMAINING_FIRST, HIGHEST_STACKS_FIRST, LOWEST_STACKS_FIRST }
enum StackRemovalMode { REMOVE_INSTANCE, REMOVE_ONE_STACK, REMOVE_ALL_STACKS }

@export var match_mode: MatchMode = MatchMode.ANY
@export var include_types: Array[StatusType] = []
@export var include_categories: Array[StatusCategory] = []
@export var include_tags: Array[StatusTag] = []
@export var exclude_types: Array[StatusType] = []
@export var exclude_categories: Array[StatusCategory] = []
@export var exclude_tags: Array[StatusTag] = []
@export var require_cleanseable: bool = true
@export var require_dispellable: bool = false
@export var max_removed: int = 1
@export var selection_policy: SelectionPolicy = SelectionPolicy.OLDEST_FIRST
@export var stack_removal_mode: StackRemovalMode = StackRemovalMode.REMOVE_INSTANCE
@export var debug_log: bool = false

func matches(instance) -> bool:
	if instance == null or instance.definition == null:
		return false
	if require_cleanseable and not instance.definition.cleanseable:
		return false
	if require_dispellable and not instance.definition.dispellable:
		return false
	if _has_any_match(instance, exclude_types, exclude_categories, exclude_tags):
		return false
	return _matches_includes(instance)

func sort_instances(instances: Array) -> Array:
	var sorted := instances.duplicate()
	sorted.sort_custom(func(a, b): return _compare_instances(a, b) < 0)
	return sorted

func _matches_includes(instance) -> bool:
	var has_filters := not include_types.is_empty() or not include_categories.is_empty() or not include_tags.is_empty()
	if not has_filters:
		return true
	if match_mode == MatchMode.ANY:
		return _has_any_match(instance, include_types, include_categories, include_tags)
	return _has_all_matches(instance, include_types, include_categories, include_tags)

func _has_any_match(instance, types: Array, categories: Array, tags: Array) -> bool:
	for type in types:
		if instance.has_type(type):
			return true
	for category in categories:
		if instance.has_category(category):
			return true
	for tag in tags:
		if instance.has_tag(tag):
			return true
	return false

func _has_all_matches(instance, types: Array, categories: Array, tags: Array) -> bool:
	for type in types:
		if not instance.has_type(type):
			return false
	for category in categories:
		if not instance.has_category(category):
			return false
	for tag in tags:
		if not instance.has_tag(tag):
			return false
	return true

func _compare_instances(a, b) -> int:
	match selection_policy:
		SelectionPolicy.NEWEST_FIRST:
			return b.applied_time_msec - a.applied_time_msec
		SelectionPolicy.SHORTEST_REMAINING_FIRST:
			return -1 if a.remaining_duration < b.remaining_duration else 1
		SelectionPolicy.LONGEST_REMAINING_FIRST:
			return -1 if a.remaining_duration > b.remaining_duration else 1
		SelectionPolicy.HIGHEST_STACKS_FIRST:
			return b.stacks - a.stacks
		SelectionPolicy.LOWEST_STACKS_FIRST:
			return a.stacks - b.stacks
		_:
			return a.applied_time_msec - b.applied_time_msec

func _should_log() -> bool:
	return debug_log or ProjectSettings.get_setting("event_channels/debug_log_events", false)

class_name FilteredRuntimeSetTargeting
extends SkillTargeting

enum SortMode {
	RUNTIME_SET_ORDER,
	NEAREST_TO_CASTER,
	FARTHEST_FROM_CASTER,
	NEAREST_TO_FORWARD_LINE,
}

@export var runtime_set: RuntimeSet
@export var filters: Array[Resource] = []
@export var max_targets: int = 0
@export var exclude_caster: bool = false
@export var sort_mode: SortMode = SortMode.RUNTIME_SET_ORDER

var _target_sort_scores: Dictionary = {}
var _target_sort_order: Dictionary = {}

func resolve_targets(caster: Node, skill: Resource) -> Array[Node]:
	return _resolve_targets(caster, skill, null)

func resolve_targets_for_context(context: SkillCastContext) -> Array[Node]:
	if context == null:
		return []
	return _resolve_targets(context.caster, context.skill, context)

func _resolve_targets(caster: Node, skill: Resource, context: SkillCastContext) -> Array[Node]:
	if runtime_set == null:
		return []

	var targets: Array[Node] = []
	for target in runtime_set.get_items():
		if target == null:
			continue
		if not _is_skill_targetable(target):
			continue
		if exclude_caster and target == caster:
			continue
		if not _accepts_shape(caster, target, context):
			continue
		if not _accepts_filters(caster, skill, target):
			continue
		targets.append(target)

	_sort_targets(caster, targets, context)
	if max_targets > 0 and targets.size() > max_targets:
		targets = targets.slice(0, max_targets)

	if _should_log():
		print("[FilteredRuntimeSetTargeting] resolved %s target(s)" % targets.size())

	return targets

func _accepts_shape(_caster: Node, _target: Node, _context: SkillCastContext = null) -> bool:
	return true

func _accepts_filters(caster: Node, skill: Resource, target: Node) -> bool:
	for filter in filters:
		if filter == null or not filter.has_method("accepts_target"):
			continue
		if not filter.accepts_target(caster, skill, target):
			return false
	return true

func _sort_targets(caster: Node, targets: Array[Node], context: SkillCastContext = null) -> void:
	if sort_mode == SortMode.RUNTIME_SET_ORDER or targets.size() < 2:
		return

	var caster_position := SkillTargetingGeometry.try_get_position(caster)
	if not caster_position.found:
		return

	var caster_point: Vector2 = caster_position.position
	var forward: Vector2 = SkillTargetingGeometry.get_forward_for_context(context) if context != null else SkillTargetingGeometry.get_forward(caster)
	_target_sort_scores.clear()
	_target_sort_order.clear()

	for index in targets.size():
		var target := targets[index]
		var target_id := target.get_instance_id()
		_target_sort_order[target_id] = index

		var target_position := SkillTargetingGeometry.try_get_position(target)
		if not target_position.found:
			continue

		var offset: Vector2 = target_position.position - caster_point
		match sort_mode:
			SortMode.NEAREST_TO_CASTER:
				_target_sort_scores[target_id] = offset.length_squared()
			SortMode.FARTHEST_FROM_CASTER:
				_target_sort_scores[target_id] = -offset.length_squared()
			SortMode.NEAREST_TO_FORWARD_LINE:
				_target_sort_scores[target_id] = absf(offset.cross(forward))

	targets.sort_custom(_compare_targets)
	_target_sort_scores.clear()
	_target_sort_order.clear()

func _compare_targets(a: Node, b: Node) -> bool:
	var a_id := a.get_instance_id()
	var b_id := b.get_instance_id()
	var a_has_score := _target_sort_scores.has(a_id)
	var b_has_score := _target_sort_scores.has(b_id)
	if a_has_score and b_has_score:
		var a_score: float = _target_sort_scores[a_id]
		var b_score: float = _target_sort_scores[b_id]
		if not is_equal_approx(a_score, b_score):
			return a_score < b_score
	elif a_has_score != b_has_score:
		return a_has_score

	return int(_target_sort_order.get(a_id, 0)) < int(_target_sort_order.get(b_id, 0))

class_name RuntimeSetTargeting
extends SkillTargeting

@export var runtime_set: RuntimeSet
@export var max_targets: int = 0

func resolve_targets(_caster: Node, _skill: Resource) -> Array[Node]:
	if runtime_set == null:
		return []

	var targets: Array[Node] = []
	for target in runtime_set.get_items():
		if _is_skill_targetable(target):
			targets.append(target)
	if max_targets > 0 and targets.size() > max_targets:
		targets = targets.slice(0, max_targets)

	if _should_log():
		print("[RuntimeSetTargeting] resolved %s target(s)" % targets.size())

	return targets

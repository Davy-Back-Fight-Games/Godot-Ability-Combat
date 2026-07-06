class_name StatBlock
extends Resource

@export var stats: Array[StatValue] = []

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Array[StatId] = []
	for index in stats.size():
		var stat := stats[index]
		if stat == null:
			errors.append("StatBlock stats[%s] is null." % index)
			continue
		if stat.id == null:
			errors.append("StatBlock stats[%s] is missing id." % index)
			continue
		if stat.id in seen_ids:
			errors.append("StatBlock stats[%s] duplicates StatId '%s'." % [index, stat.id.get_label()])
		else:
			seen_ids.append(stat.id)
	return errors

func is_valid_stat_block() -> bool:
	return get_validation_errors().is_empty()

func duplicate_runtime() -> StatBlock:
	var copy := duplicate(true) as StatBlock
	if copy != null:
		copy.reset_to_initial_values()
	return copy

func has_stat(id: StatId) -> bool:
	return get_stat(id) != null

func get_stat(id: StatId) -> StatValue:
	if id == null:
		return null
	for stat in stats:
		if stat != null and stat.id == id:
			return stat
	return null

func get_value(id: StatId, default_value: float = 0.0) -> float:
	var stat := get_stat(id)
	if stat == null:
		return default_value
	return stat.value

func set_value(id: StatId, value: float) -> bool:
	var stat := get_stat(id)
	if stat == null:
		return false
	stat.set_value(value)
	return true

func apply_change(id: StatId, amount: float) -> bool:
	var stat := get_stat(id)
	if stat == null:
		return false
	stat.apply_change(amount)
	return true

func has_resource(resource_type: ResourceType) -> bool:
	return resource_type != null and resource_type.is_valid_resource() and has_stat(resource_type.current_stat) and has_stat(resource_type.max_stat)

func get_resource_current(resource_type: ResourceType, default_value: float = 0.0) -> float:
	if not has_resource(resource_type):
		return default_value
	return get_value(resource_type.current_stat, default_value)

func get_resource_max(resource_type: ResourceType, default_value: float = 0.0) -> float:
	if not has_resource(resource_type):
		return default_value
	return get_value(resource_type.max_stat, default_value)

func set_resource_current(resource_type: ResourceType, value: float) -> bool:
	if not has_resource(resource_type):
		return false
	var max_value := maxf(get_resource_max(resource_type), 0.0)
	return set_value(resource_type.current_stat, clampf(value, 0.0, max_value))

func apply_resource_change(resource_type: ResourceType, amount: float) -> bool:
	if not has_resource(resource_type):
		return false
	return set_resource_current(resource_type, get_resource_current(resource_type) + amount)

func can_pay_resource(resource_type: ResourceType, amount: float) -> bool:
	if amount <= 0.0:
		return true
	return has_resource(resource_type) and get_resource_current(resource_type) >= amount

func try_pay_resource(resource_type: ResourceType, amount: float) -> bool:
	if not can_pay_resource(resource_type, amount):
		return false
	if amount <= 0.0:
		return true
	return apply_resource_change(resource_type, -amount)

func reset_to_initial_values() -> void:
	for stat in stats:
		if stat != null:
			stat.reset_to_initial_value()

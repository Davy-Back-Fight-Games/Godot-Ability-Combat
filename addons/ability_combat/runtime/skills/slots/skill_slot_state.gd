class_name SkillSlotState
extends RefCounted

var slot_index: int = -1
var skill: SkillDefinition
var cooldown_remaining: float = 0.0
var cooldown_total: float = 0.0
var charges_current: int = 1
var charges_max: int = 1
var recharge_remaining: float = 0.0
var recharge_total: float = 0.0
var recast_window_remaining: float = 0.0
var recast_window_total: float = 0.0
var cooldown_group: StringName = &""

func configure(p_slot_index: int, p_skill: SkillDefinition) -> void:
	slot_index = p_slot_index
	if skill == p_skill:
		return
	skill = p_skill
	cooldown_remaining = 0.0
	cooldown_total = 0.0
	recharge_remaining = 0.0
	recharge_total = 0.0
	recast_window_remaining = 0.0
	recast_window_total = skill.get_recast_window_seconds() if skill != null else 0.0
	cooldown_group = skill.get_cooldown_group() if skill != null else &""
	charges_max = skill.get_max_charges() if skill != null else 1
	charges_current = charges_max

func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)
	if recast_window_remaining > 0.0:
		recast_window_remaining = maxf(recast_window_remaining - delta, 0.0)
	_tick_recharge(delta)

func is_on_cooldown() -> bool:
	if charges_max > 1:
		return charges_current <= 0 and recharge_remaining > 0.0
	return cooldown_remaining > 0.0

func get_cooldown_remaining() -> float:
	if charges_max > 1:
		return recharge_remaining if charges_current <= 0 else 0.0
	return cooldown_remaining

func get_cooldown_total() -> float:
	return cooldown_total

func get_charges_current() -> int:
	return charges_current

func get_charges_max() -> int:
	return charges_max

func get_recharge_remaining() -> float:
	return recharge_remaining

func get_recharge_total() -> float:
	return recharge_total

func get_recast_window_remaining() -> float:
	return recast_window_remaining

func get_recast_window_total() -> float:
	return recast_window_total

func begin_cooldown(seconds: float) -> void:
	var cooldown := maxf(seconds, 0.0)
	cooldown_total = cooldown
	cooldown_group = skill.get_cooldown_group() if skill != null else cooldown_group
	charges_max = skill.get_max_charges() if skill != null else charges_max
	charges_current = clampi(charges_current, 0, charges_max)
	if charges_max > 1:
		charges_current = max(charges_current - 1, 0)
		if charges_current < charges_max and recharge_remaining <= 0.0:
			recharge_total = _get_recharge_seconds(cooldown)
			recharge_remaining = recharge_total
	else:
		cooldown_remaining = cooldown
	if skill != null:
		recast_window_total = skill.get_recast_window_seconds()
		recast_window_remaining = recast_window_total

func _tick_recharge(delta: float) -> void:
	if charges_max <= 1 or charges_current >= charges_max or recharge_remaining <= 0.0:
		return
	recharge_remaining = maxf(recharge_remaining - delta, 0.0)
	while recharge_remaining <= 0.0 and charges_current < charges_max:
		charges_current += 1
		if charges_current >= charges_max:
			recharge_remaining = 0.0
			recharge_total = 0.0
			return
		recharge_total = _get_recharge_seconds(cooldown_total)
		recharge_remaining += recharge_total

func _get_recharge_seconds(fallback: float) -> float:
	if skill == null:
		return fallback
	var recharge := skill.get_recharge_seconds()
	return recharge if recharge > 0.0 else fallback

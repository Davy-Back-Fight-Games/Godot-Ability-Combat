class_name TimedSkillEffect
extends Resource

const TRIGGER_CAST_POINT := "cast_point"
const TRIGGER_CHANNEL_TICK := "channel_tick"
const TRIGGER_FINISH := "finish"
const TRIGGER_INTERRUPT := "interrupt"

enum Trigger { CAST_POINT, CHANNEL_TICK, FINISH, INTERRUPT }

@export var trigger_id: Trigger = Trigger.CAST_POINT
@export var effect: SkillEffect
@export var tick_every_n: int = 1:
	set(value):
		tick_every_n = maxi(value, 1)

func should_trigger(trigger_name: String, cast_instance: SkillCastInstance = null) -> bool:
	if trigger_name != get_trigger_name():
		return false
	if trigger_name != TRIGGER_CHANNEL_TICK:
		return true
	var tick_number := 0
	if cast_instance != null:
		tick_number = cast_instance.consumed_channel_tick_count
	return tick_number > 0 and tick_number % get_tick_every_n() == 0

func apply_context(context: SkillCastContext) -> bool:
	if effect == null:
		return true
	effect.apply_context(context)
	return true

func get_tick_every_n() -> int:
	return maxi(tick_every_n, 1)

func get_trigger_name() -> String:
	return _trigger_id_to_name(trigger_id)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var resolved_trigger := get_trigger_name()
	if not _is_valid_trigger(resolved_trigger):
		errors.append("TimedSkillEffect has invalid trigger: %s" % resolved_trigger)
	if effect == null:
		errors.append("TimedSkillEffect has no effect")
	return errors

func _is_valid_trigger(value: String) -> bool:
	return value == TRIGGER_CAST_POINT or value == TRIGGER_CHANNEL_TICK or value == TRIGGER_FINISH or value == TRIGGER_INTERRUPT

func _trigger_id_to_name(value: Trigger) -> String:
	match value:
		Trigger.CHANNEL_TICK:
			return TRIGGER_CHANNEL_TICK
		Trigger.FINISH:
			return TRIGGER_FINISH
		Trigger.INTERRUPT:
			return TRIGGER_INTERRUPT
		_:
			return TRIGGER_CAST_POINT

extends Node

## 4개 스킬 슬롯의 장착/해제/쿨다운을 관리한다.

const MAX_SLOTS := 4

var _slots: Array[String] = ["", "", "", ""]
var _cooldown_timers: Array[Timer] = []


func _ready() -> void:
	for i in range(MAX_SLOTS):
		var timer := Timer.new()
		timer.name = "CooldownTimer_%d" % i
		timer.one_shot = true
		var idx: int = i
		timer.timeout.connect(_on_cooldown_timeout.bind(idx))
		add_child(timer)
		_cooldown_timers.append(timer)


# === 슬롯 관리 ===


func equip(slot_index: int, skill_id: String) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_slots[slot_index] = skill_id


func unequip(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_slots[slot_index] = ""
	_cooldown_timers[slot_index].stop()


func get_skill_id(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return ""
	return _slots[slot_index]


func swap(slot_a: int, slot_b: int) -> void:
	if slot_a < 0 or slot_a >= MAX_SLOTS:
		return
	if slot_b < 0 or slot_b >= MAX_SLOTS:
		return
	var temp: String = _slots[slot_a]
	_slots[slot_a] = _slots[slot_b]
	_slots[slot_b] = temp


func get_equipped_paths() -> Array:
	var paths: Array = []
	for sid in _slots:
		if sid.is_empty():
			continue
		paths.append(sid)
	return paths


# === 쿨다운 ===


func is_on_cooldown(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return true
	return not _cooldown_timers[slot_index].is_stopped()


func start_cooldown(slot_index: int, duration: float) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_cooldown_timers[slot_index].wait_time = duration
	_cooldown_timers[slot_index].start()
	EventBus.skill_cooldown_started.emit(slot_index, duration)


func get_remaining(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return 0.0
	var timer: Timer = _cooldown_timers[slot_index]
	if timer.is_stopped():
		return 0.0
	return timer.time_left


func get_ratio(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return 0.0
	var timer: Timer = _cooldown_timers[slot_index]
	if timer.is_stopped() or timer.wait_time <= 0.0:
		return 0.0
	return timer.time_left / timer.wait_time


func _on_cooldown_timeout(slot_index: int) -> void:
	EventBus.skill_cooldown_finished.emit(slot_index)

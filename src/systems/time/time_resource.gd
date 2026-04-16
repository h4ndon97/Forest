extends Node

## 시간 자원 잔량을 관리하고, 소모/회복 계산을 담당한다.

signal resource_changed(current: float, max_val: float)
signal resource_depleted

var current: float = 100.0
var max_value: float = 100.0

var _config: TimeConfigData
var _was_depleted: bool = false
var _base_max: float = 100.0


func setup(config: TimeConfigData) -> void:
	_config = config
	_base_max = config.resource_max
	max_value = _base_max + GrowthSystem.get_time_max_bonus()
	current = config.resource_initial
	_was_depleted = false
	EventBus.growth_stats_changed.connect(_on_growth_stats_changed)


func consume(game_hours_elapsed: float) -> void:
	var amount: float = _config.consume_per_game_hour * game_hours_elapsed
	current = maxf(current - amount, 0.0)
	resource_changed.emit(current, max_value)
	if current <= 0.0 and not _was_depleted:
		_was_depleted = true
		resource_depleted.emit()


func recover(game_hours_elapsed: float) -> void:
	if current >= max_value:
		return
	var rate: float = _config.recover_per_game_hour + GrowthSystem.get_time_recovery_bonus()
	var amount: float = rate * game_hours_elapsed
	_apply_recovery(amount)


func consume_flat(amount: float) -> void:
	current = maxf(current - amount, 0.0)
	resource_changed.emit(current, max_value)
	if current <= 0.0 and not _was_depleted:
		_was_depleted = true
		resource_depleted.emit()


func recover_flat(amount: float) -> void:
	if current >= max_value:
		return
	_apply_recovery(amount)


func full_recover() -> void:
	current = max_value
	_was_depleted = false
	resource_changed.emit(current, max_value)


func is_depleted() -> bool:
	return current <= 0.0


func get_ratio() -> float:
	if max_value <= 0.0:
		return 0.0
	return current / max_value


func _on_growth_stats_changed() -> void:
	var new_max: float = _base_max + GrowthSystem.get_time_max_bonus()
	if new_max == max_value:
		return
	max_value = new_max
	current = minf(current, max_value)
	resource_changed.emit(current, max_value)


func _apply_recovery(amount: float) -> void:
	current = minf(current + amount, max_value)
	if current > 0.0:
		_was_depleted = false
	resource_changed.emit(current, max_value)

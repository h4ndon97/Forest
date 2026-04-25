extends Node

## 현재 시각(hour)을 관리하고, 진행 계산 및 경계 판정을 담당한다.

signal day_night_boundary_crossed(is_day: bool)

var current_hour: float = 12.0

var _config: TimeConfigData
var _was_day: bool = true


func setup(config: TimeConfigData) -> void:
	_config = config
	current_hour = config.initial_hour
	_was_day = is_day()


## 시각을 강제 설정한다. 경계 상태도 갱신.
func set_hour(hour: float) -> void:
	current_hour = hour
	_was_day = is_day()


func advance_manipulation(delta: float) -> float:
	var hours_elapsed: float = _config.manipulation_speed * delta
	var old_hour := current_hour
	current_hour += hours_elapsed
	_wrap_hour()
	_check_boundary_crossing(old_hour)
	return hours_elapsed


func advance_flow(delta: float, rate: float = 1.0) -> float:
	var hours_per_second: float = _config.flow_speed / 60.0
	var hours_elapsed: float = hours_per_second * delta * rate
	var old_hour := current_hour
	current_hour += hours_elapsed
	_wrap_hour()
	_check_boundary_crossing(old_hour)
	return hours_elapsed


## rate 무관 전체 속도 기준 시간 경과를 계산한다 (자원 소모/회복용).
func compute_full_flow_hours(delta: float) -> float:
	var hours_per_second: float = _config.flow_speed / 60.0
	return hours_per_second * delta


func is_day() -> bool:
	return current_hour >= _config.sunrise_hour and current_hour < _config.sunset_hour


func reached_manipulation_limit() -> bool:
	var limit_offset: float = _config.manipulation_limit_minutes / 60.0
	var sunrise_limit: float = _config.sunrise_hour - limit_offset
	var sunset_limit: float = _config.sunset_hour - limit_offset

	if _was_day:
		return current_hour >= sunset_limit and current_hour < _config.sunset_hour
	if sunrise_limit < 0.0:
		return current_hour >= (24.0 + sunrise_limit) or current_hour < _config.sunrise_hour
	return current_hour >= sunrise_limit and current_hour < _config.sunrise_hour


func get_sun_angle() -> float:
	if not is_day():
		return -1.0
	return (
		(current_hour - _config.sunrise_hour) / (_config.sunset_hour - _config.sunrise_hour) * 180.0
	)


func get_time_string() -> String:
	var hour_int: int = int(current_hour) % 24
	var minute_float: float = (current_hour - floorf(current_hour)) * 60.0
	var minute_int: int = int(minute_float)
	return "%02d:%02d" % [hour_int, minute_int]


func _wrap_hour() -> void:
	while current_hour >= 24.0:
		current_hour -= 24.0
	while current_hour < 0.0:
		current_hour += 24.0


func _check_boundary_crossing(_old_hour: float) -> void:
	var now_day := is_day()
	if now_day != _was_day:
		_was_day = now_day
		day_night_boundary_crossed.emit(now_day)

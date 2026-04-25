extends Node

## 그림자 시스템 Autoload.
## 시간 이벤트를 수신하여 전역 그림자 파라미터를 관리한다.
## 밤에는 등불 소스 기반 per-object 그림자 계산을 지원한다.

const CONFIG_PATH := "res://data/shadow/shadow_config.tres"
const LANTERN_CONFIG_PATH := "res://data/lantern/lantern_config.tres"
const TimeStateMachineScript = preload("res://src/systems/time/time_state_machine.gd")

var _config: ShadowConfigData
var _is_day: bool = true
var _shadow_direction: Vector2 = Vector2.DOWN
var _shadow_scale_factor: float = 0.0
var _shadow_sprite_scale: float = 0.1
var _intensity_multiplier: float = 0.2
var _locked: bool = false
var _last_sun_angle: float = 0.0

# 등불 소스 관리
var _lantern_active: bool = false
var _lantern_position: Vector2 = Vector2.ZERO
var _lantern_max_range: float = 200.0
var _lantern_base_range: float = 200.0


func _ready() -> void:
	_config = load(CONFIG_PATH) as ShadowConfigData
	_shadow_direction = _config.default_direction

	var lantern_config: LanternConfigData = load(LANTERN_CONFIG_PATH) as LanternConfigData
	_lantern_base_range = lantern_config.max_range
	_lantern_max_range = _lantern_base_range

	EventBus.sun_state_updated.connect(_on_sun_state_updated)
	EventBus.day_night_changed.connect(_on_day_night_changed)
	EventBus.lantern_toggled.connect(_on_lantern_toggled)
	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.growth_stats_changed.connect(_on_growth_stats_changed)


func get_shadow_direction() -> Vector2:
	return _shadow_direction


func get_shadow_scale_factor() -> float:
	return _shadow_scale_factor


func get_shadow_sprite_scale() -> float:
	return _shadow_sprite_scale


func get_intensity_multiplier() -> float:
	return _intensity_multiplier


func get_shadow_base_alpha() -> float:
	return _config.shadow_base_alpha


func is_day_mode() -> bool:
	return _is_day


## 등불 토글 시그널 수신. 등불 ON/OFF에 따라 내부 상태를 갱신한다.
func _on_lantern_toggled(is_on: bool, lantern_position: Vector2) -> void:
	_lantern_active = is_on
	if _locked:
		return
	if is_on:
		_lantern_position = lantern_position
	elif not _is_day:
		_update_night_no_lantern()


## 등불 위치를 갱신한다. 등불 ON 중 매 프레임 호출.
func update_lantern_position(pos: Vector2) -> void:
	if _locked:
		return
	_lantern_position = pos


## 등불이 현재 활성 상태인지 반환한다.
func is_lantern_active() -> bool:
	return _lantern_active


## 밤에 특정 오브젝트 위치의 그림자 파라미터를 계산한다.
## 등불 기반 per-object 계산. 범위 밖이면 빈 Dictionary 반환.
func get_night_shadow_params(object_pos: Vector2) -> Dictionary:
	if _is_day or not _lantern_active:
		return {}

	var distance := object_pos.distance_to(_lantern_position)
	if distance > _lantern_max_range:
		return {}

	var direction := ShadowCalculator.calculate_night_direction(object_pos, _lantern_position)
	var scale_factor := ShadowCalculator.calculate_night_scale_factor(distance, _lantern_max_range)
	var sprite_scale := ShadowCalculator.scale_factor_to_sprite_scale(scale_factor, _config)
	var intensity := ShadowCalculator.calculate_intensity(scale_factor, false, _config)

	return {
		"direction": direction,
		"sprite_scale": sprite_scale,
		"intensity": intensity,
	}


## 밤에 특정 위치의 강도를 구한다.
func get_intensity_at(pos: Vector2) -> float:
	if _is_day:
		return _intensity_multiplier
	if not _lantern_active:
		return 0.0

	var distance := pos.distance_to(_lantern_position)
	if distance > _lantern_max_range:
		return 0.0

	var scale_factor := ShadowCalculator.calculate_night_scale_factor(distance, _lantern_max_range)
	return ShadowCalculator.calculate_intensity(scale_factor, false, _config)


# --- 내부 ---


func _on_time_state_changed(_old_state: int, new_state: int) -> void:
	if new_state == TimeStateMachineScript.TimeState.FLOWING:
		_locked = true
	else:
		_locked = false
		# 잠금 해제 시 현재 상태로 즉시 갱신
		if _is_day and _last_sun_angle >= 0.0:
			_update_from_sun_angle(_last_sun_angle)
		elif not _is_day and not _lantern_active:
			_update_night_no_lantern()


func _on_sun_state_updated(sun_angle: float, is_day: bool) -> void:
	_is_day = is_day
	_last_sun_angle = sun_angle
	if _locked:
		return
	if _is_day and sun_angle >= 0.0:
		_update_from_sun_angle(sun_angle)
	elif not _lantern_active:
		_update_night_no_lantern()


func _on_day_night_changed(is_day: bool) -> void:
	_is_day = is_day
	if _locked:
		return
	if not is_day and not _lantern_active:
		_update_night_no_lantern()


func _update_from_sun_angle(sun_angle: float) -> void:
	_shadow_direction = ShadowCalculator.calculate_day_direction(sun_angle)
	_shadow_scale_factor = ShadowCalculator.calculate_day_scale_factor(sun_angle)
	_shadow_sprite_scale = ShadowCalculator.scale_factor_to_sprite_scale(
		_shadow_scale_factor, _config
	)
	_intensity_multiplier = ShadowCalculator.calculate_intensity(
		_shadow_scale_factor, true, _config
	)

	EventBus.shadow_params_changed.emit(
		_shadow_direction, _shadow_sprite_scale, _intensity_multiplier
	)


func _on_growth_stats_changed() -> void:
	_lantern_max_range = _lantern_base_range + GrowthSystem.get_lantern_range_bonus()


## 밤 + 등불 OFF: 그림자 없음 상태를 전역 방송.
func _update_night_no_lantern() -> void:
	_shadow_direction = _config.default_direction
	_shadow_scale_factor = 0.0
	_shadow_sprite_scale = 0.0
	_intensity_multiplier = 0.0

	EventBus.shadow_params_changed.emit(_shadow_direction, 0.0, 0.0)

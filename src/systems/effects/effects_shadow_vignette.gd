class_name EffectsShadowVignette
extends RefCounted

## REC-FX-007 — 그림자 강도 기반 화면 가장자리 비네트.
## EventBus.shadow_params_changed(dir, scale, intensity) 구독 → OverlayVignette 색·알파 Tween.
##
## 비네트 슬롯 우선순위 정책:
##   - DuskWarning(EffectsDuskWarning) 활성(거리 0~2) 시 → 본 시스템 손 떼기
##   - DuskWarning 비활성(거리 -1) 시 → 그림자 강도에 따라 비네트 표시
##   - 즉 동일 비네트 슬롯을 두 시스템이 시간차로 공유한다.
##
## 알파 매핑: intensity < threshold → 0.0 (OFF)
##           intensity ≥ threshold → 0~alpha_max 선형 (강도 1.5에서 풀)

const _DUSK_INACTIVE: int = -1
const _DUSK_MAX_DISTANCE: int = 2

var _host: Node
var _config: EffectsConfigData
var _dusk_active: bool = false
var _shadow_intensity: float = 0.0
var _madness_stage: int = 0
var _color_tween: Tween = null
var _current_color: Color = Color(0.0, 0.0, 0.0, 0.0)


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	EventBus.shadow_params_changed.connect(_on_shadow_params_changed)
	EventBus.dusk_spider_approached.connect(_on_dusk_distance_changed)
	# REC-MECH-002 시너지: 광기 단계 → 비네트 알파 추가 보정.
	EventBus.madness_stage_changed.connect(_on_madness_stage_changed)


# === 내부 ===


func _on_shadow_params_changed(_direction: Vector2, _scale: float, intensity: float) -> void:
	_shadow_intensity = intensity
	_apply()


func _on_dusk_distance_changed(distance: int) -> void:
	var was_active: bool = _dusk_active
	_dusk_active = (distance >= 0 and distance <= _DUSK_MAX_DISTANCE)
	# DuskWarning이 비활성으로 전환 시 우리가 비네트 권한 회수 → 자기 색 재발화.
	if was_active and not _dusk_active:
		_apply()
	# DuskWarning이 활성으로 전환 시 우리는 손 뗌 (DuskWarning이 자기 색을 set).
	# 별도 clear 호출하지 않는다 — 같은 프레임에 DuskWarning이 덮어쓸 것.


func _on_madness_stage_changed(_old_stage: int, new_stage: int) -> void:
	_madness_stage = new_stage
	_apply()


func _apply() -> void:
	if _dusk_active:
		return
	var target: Color = _resolve_target_color()
	var duration: float = _config.shadow_vignette_transition_duration
	_kill_tween()
	if duration <= 0.0 or _host == null:
		_set_color(target)
		return
	_color_tween = _host.create_tween().set_ignore_time_scale(true)
	_color_tween.tween_method(_set_color, _current_color, target, duration)


func _resolve_target_color() -> Color:
	var threshold: float = _config.shadow_vignette_threshold
	var madness_boost: float = _resolve_madness_boost()
	if _shadow_intensity < threshold and madness_boost <= 0.0:
		var off_color: Color = _config.shadow_vignette_color
		off_color.a = 0.0
		return off_color
	# 강도 threshold~1.5 → 0~alpha_max 선형. 1.5 초과는 클램프.
	var span: float = max(1.5 - threshold, 0.001)
	var t: float = clampf((_shadow_intensity - threshold) / span, 0.0, 1.0)
	var color: Color = _config.shadow_vignette_color
	# 기본 비네트 알파 + 광기 단계별 추가 보정. max는 1.0으로 클램프.
	color.a = clampf(t * _config.shadow_vignette_alpha_max + madness_boost, 0.0, 1.0)
	return color


func _resolve_madness_boost() -> float:
	# MadnessSystem이 EffectsSystem보다 늦게 _ready 되어 첫 호출 시 config null 가능.
	var madness_config: MadnessConfigData = MadnessSystem.get_config()
	if madness_config == null:
		return 0.0
	match _madness_stage:
		1:
			return madness_config.vignette_boost_warning
		2:
			return madness_config.vignette_boost_alert
		3:
			return madness_config.vignette_boost_critical
		_:
			return 0.0


func _set_color(value: Color) -> void:
	_current_color = value
	OverlaySystem.set_vignette_color(value, value.a)


func _kill_tween() -> void:
	if _color_tween != null and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = null

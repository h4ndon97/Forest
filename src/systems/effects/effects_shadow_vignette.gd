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
var _color_tween: Tween = null
var _current_color: Color = Color(0.0, 0.0, 0.0, 0.0)


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	EventBus.shadow_params_changed.connect(_on_shadow_params_changed)
	EventBus.dusk_spider_approached.connect(_on_dusk_distance_changed)


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
	if _shadow_intensity < threshold:
		var off_color: Color = _config.shadow_vignette_color
		off_color.a = 0.0
		return off_color
	# 강도 threshold~1.5 → 0~alpha_max 선형. 1.5 초과는 클램프.
	var span: float = max(1.5 - threshold, 0.001)
	var t: float = clampf((_shadow_intensity - threshold) / span, 0.0, 1.0)
	var color: Color = _config.shadow_vignette_color
	color.a = t * _config.shadow_vignette_alpha_max
	return color


func _set_color(value: Color) -> void:
	_current_color = value
	OverlaySystem.set_vignette_color(value, value.a)


func _kill_tween() -> void:
	if _color_tween != null and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = null

class_name EffectsDuskWarning
extends RefCounted

## Phase 3-7 Pass 4 — 땅거미 거리 기반 비네트 경고.
## EventBus.dusk_spider_approached(distance) 구독 → OverlayVignette 색·알파 Tween.
## 거리: -1=해제, 0=같은 맵(빨강), 1=근접(보라↔빨강 중간), 2=먼 보라, 3+=무효.

const DISTANCE_INACTIVE: int = -1
const MAX_WARNING_DISTANCE: int = 2

var _host: Node
var _config: EffectsConfigData
var _vignette: OverlayVignette
var _current_distance: int = DISTANCE_INACTIVE
var _color_tween: Tween = null
var _shake_tween: Tween = null
var _current_color: Color = Color(0.0, 0.0, 0.0, 0.0)


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	_vignette = OverlaySystem.get_node_or_null("Vignette") as OverlayVignette
	_install_radius()
	OverlaySystem.set_vignette_color(_current_color, 0.0)
	EventBus.dusk_spider_approached.connect(_on_distance_changed)


## 거리 → 목표 색·알파를 즉시 적용(트랜지션 없음, 초기화/디버그용).
func apply_instant(distance: int) -> void:
	_kill_tween()
	_current_distance = distance
	var target: Color = _resolve_color_for_distance(distance)
	_set_color(target)
	_update_shake(distance)


## 거리 → 목표 색·알파를 Tween으로 보간.
func apply_transition(distance: int) -> void:
	if distance == _current_distance:
		return
	_current_distance = distance
	_kill_tween()
	var target: Color = _resolve_color_for_distance(distance)
	var duration: float = _config.dusk_vignette_transition_duration
	if duration <= 0.0 or _host == null:
		_set_color(target)
	else:
		_color_tween = _host.create_tween().set_ignore_time_scale(true)
		_color_tween.tween_method(_set_color, _current_color, target, duration)
	_update_shake(distance)


# === 내부 ===


func _install_radius() -> void:
	# OverlaySystem 내부의 Vignette 노드는 외부로 직접 노출되지 않으므로
	# CanvasLayer 자식에서 직접 찾아 반경을 셋한다(Pass 4 스코프 한정 호출).
	var vignette: OverlayVignette = OverlaySystem.get_node_or_null("Vignette") as OverlayVignette
	if vignette == null:
		return
	vignette.set_radius(_config.dusk_vignette_inner_radius, _config.dusk_vignette_outer_radius)


func _resolve_color_for_distance(distance: int) -> Color:
	if distance < 0 or distance > MAX_WARNING_DISTANCE:
		var clear_color: Color = _config.dusk_vignette_color_far
		clear_color.a = 0.0
		return clear_color
	match distance:
		0:
			var c0: Color = _config.dusk_vignette_color_near
			c0.a = _config.dusk_vignette_alpha_distance_0
			return c0
		1:
			var c1: Color = _config.dusk_vignette_color_far.lerp(
				_config.dusk_vignette_color_near, _config.dusk_vignette_lerp_distance_1
			)
			c1.a = _config.dusk_vignette_alpha_distance_1
			return c1
		_:
			var c2: Color = _config.dusk_vignette_color_far
			c2.a = _config.dusk_vignette_alpha_distance_2
			return c2


func _set_color(value: Color) -> void:
	_current_color = value
	OverlaySystem.set_vignette_color(value, value.a)


func _kill_tween() -> void:
	if _color_tween != null and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = null


func _on_distance_changed(distance: int) -> void:
	apply_transition(distance)


# === 화면 경계 셰이크 (거리 ≤ 1 활성) ===


func _update_shake(distance: int) -> void:
	_kill_shake()
	if _vignette == null or _host == null:
		return
	var amp: float = _resolve_shake_amp(distance) * _config.shake_intensity_mult
	if amp <= 0.0:
		_vignette.position = Vector2.ZERO
		return
	var step: float = _config.dusk_warning_shake_period * 0.25
	_shake_tween = _host.create_tween().set_loops().set_ignore_time_scale(true)
	_shake_tween.tween_property(_vignette, "position", Vector2(amp, 0.0), step)
	_shake_tween.tween_property(_vignette, "position", Vector2(0.0, amp), step)
	_shake_tween.tween_property(_vignette, "position", Vector2(-amp, 0.0), step)
	_shake_tween.tween_property(_vignette, "position", Vector2(0.0, -amp), step)


func _resolve_shake_amp(distance: int) -> float:
	match distance:
		0:
			return _config.dusk_warning_shake_amp_distance_0
		1:
			return _config.dusk_warning_shake_amp_distance_1
		_:
			return 0.0


func _kill_shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = null

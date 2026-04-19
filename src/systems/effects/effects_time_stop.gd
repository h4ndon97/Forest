class_name EffectsTimeStop
extends RefCounted

## Phase 3-7 Pass 3 — 시간 정지 포스트프로세스 관리.
## Step 1: 셰이더 assign + weight 즉시 on/off.
## Step 2: EventBus(time_flow_started/stopped) 구독 + Tween 트랜지션.
## Step 3에서 파티클 정지 그룹 토글, Step 4에서 해제 펄스/잔상 추가.

const SHADER: Shader = preload("res://assets/shaders/effects/time_stop_sepia.gdshader")

const PARAM_WEIGHT: StringName = &"weight"
const PARAM_SEPIA: StringName = &"sepia_tone"
const PARAM_TINT: StringName = &"tint_color"
const PARAM_SAT: StringName = &"saturation_lerp"

var _host: Node
var _config: EffectsConfigData
var _applied: bool = false
var _current_weight: float = 0.0
var _weight_tween: Tween = null


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	_install_shader()
	EventBus.time_flow_stopped.connect(_on_time_flow_stopped)
	EventBus.time_flow_started.connect(_on_time_flow_started)


## 셰이더 weight를 즉시 0 또는 target으로 설정 (트랜지션 없음, 초기화용).
func apply_instant(on: bool) -> void:
	_kill_tween()
	_applied = on
	var target_weight: float = _config.time_stop_weight_target if on else 0.0
	_set_weight(target_weight)


## 셰이더 weight를 Tween으로 0↔target 보간 (time_flow 시그널·디버그 진입점).
func apply_transition(on: bool) -> void:
	if _applied == on:
		return
	_applied = on
	_kill_tween()
	var target_weight: float = _config.time_stop_weight_target if on else 0.0
	var duration: float = _config.time_stop_transition_duration
	if duration <= 0.0:
		_set_weight(target_weight)
		return
	_weight_tween = _host.create_tween().set_ignore_time_scale(true)
	_weight_tween.tween_method(_set_weight, _current_weight, target_weight, duration)


func is_applied() -> bool:
	return _applied


# === 내부 ===


func _install_shader() -> void:
	OverlaySystem.set_post_process_shader(SHADER)
	_set_weight(0.0)
	OverlaySystem.set_post_process_param(PARAM_SEPIA, _config.time_stop_sepia_tone)
	OverlaySystem.set_post_process_param(PARAM_TINT, _config.time_stop_tint_color)
	OverlaySystem.set_post_process_param(PARAM_SAT, _config.time_stop_saturation_lerp)


func _set_weight(value: float) -> void:
	_current_weight = value
	OverlaySystem.set_post_process_param(PARAM_WEIGHT, value)


func _kill_tween() -> void:
	if _weight_tween != null and _weight_tween.is_valid():
		_weight_tween.kill()
	_weight_tween = null


func _on_time_flow_stopped(_current_hour: float) -> void:
	apply_transition(true)


func _on_time_flow_started(_current_hour: float) -> void:
	apply_transition(false)

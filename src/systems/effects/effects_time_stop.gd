class_name EffectsTimeStop
extends RefCounted

## Phase 3-7 Pass 3 — 시간 정지 포스트프로세스 관리.
## Step 1: 셰이더 assign + weight 즉시 on/off.
## Step 2에서 EventBus(time_flow_started/stopped) 구독 + Tween 트랜지션 예정.
## Step 3에서 파티클 정지 그룹 토글, Step 4에서 해제 펄스/잔상 추가.

const SHADER: Shader = preload("res://assets/shaders/effects/time_stop_sepia.gdshader")

const PARAM_WEIGHT: StringName = &"weight"
const PARAM_SEPIA: StringName = &"sepia_tone"
const PARAM_TINT: StringName = &"tint_color"
const PARAM_SAT: StringName = &"saturation_lerp"

var _host: Node
var _config: EffectsConfigData
var _applied: bool = false


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	_install_shader()


## 셰이더 weight를 즉시 0 또는 target으로 설정 (트랜지션 없음, 디버그/초기화용).
func apply_instant(on: bool) -> void:
	_applied = on
	var target_weight: float = _config.time_stop_weight_target if on else 0.0
	OverlaySystem.set_post_process_param(PARAM_WEIGHT, target_weight)


func is_applied() -> bool:
	return _applied


# === 내부 ===


func _install_shader() -> void:
	OverlaySystem.set_post_process_shader(SHADER)
	OverlaySystem.set_post_process_param(PARAM_WEIGHT, 0.0)
	OverlaySystem.set_post_process_param(PARAM_SEPIA, _config.time_stop_sepia_tone)
	OverlaySystem.set_post_process_param(PARAM_TINT, _config.time_stop_tint_color)
	OverlaySystem.set_post_process_param(PARAM_SAT, _config.time_stop_saturation_lerp)

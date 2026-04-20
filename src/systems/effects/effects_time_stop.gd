class_name EffectsTimeStop
extends RefCounted

## Phase 3-7 Pass 3 — 시간 정지 포스트프로세스 관리.
## Step 1: 셰이더 assign + weight 즉시 on/off.
## Step 2: EventBus(time_flow_started/stopped) 구독 + Tween 트랜지션.
## Step 3: 파티클 정지 그룹 토글(EffectsFreezable).
## Step 4: 해제 시 블루 펄스 + 플레이어 잔상(apply_transition on=false 경로에서 트리거).

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
## on=false(해제) 시 블루 펄스 + 플레이어 잔상도 함께 트리거한다(Step 4).
func apply_transition(on: bool) -> void:
	if _applied == on:
		return
	_applied = on
	_kill_tween()
	var target_weight: float = _config.time_stop_weight_target if on else 0.0
	var duration: float = _config.time_stop_transition_duration
	if duration <= 0.0:
		_set_weight(target_weight)
	else:
		_weight_tween = _host.create_tween().set_ignore_time_scale(true)
		_weight_tween.tween_method(_set_weight, _current_weight, target_weight, duration)
	if not on:
		_trigger_release_fx()


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


# === Step 4: 해제 연출 트리거 ===


func _trigger_release_fx() -> void:
	if _host == null or _config == null:
		return
	_host.request_screen_flash(
		_config.time_stop_blue_pulse_color, _config.time_stop_blue_pulse_duration
	)
	var sprite: Node2D = _find_player_sprite()
	if sprite == null:
		return
	_host.request_afterimage(
		sprite,
		_config.time_stop_afterimage_count,
		_config.time_stop_afterimage_interval,
		_config.time_stop_afterimage_fade
	)


func _find_player_sprite() -> Node2D:
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("AnimatedSprite2D") as Node2D

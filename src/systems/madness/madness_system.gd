extends Node

## REC-MECH-002 — 그림자 광기 시스템 Autoload (인프라 단계).
##
## 컨셉: 큰 그림자 영역 장기 노출 시 광기 누적 → 단계별 위협 → 시간 정지 회복.
##
## 1차 인프라 (2026-04-26):
##   - 광기 게이지 0~max_value 누적/회복
##   - 강도 ≥ threshold 일 때 매 프레임 강도 비례 누적
##   - 시간 정지 중(time_state_changed STOPPED) 회복
##   - 4단계 분류 + 단계 변경 시 EventBus.madness_stage_changed emit
##   - REC-FX-007 비네트 시너지: 단계별 추가 알파 보정 (config)
##
## 미구현 (후속 작업):
##   - 환영 적 spawn (별도 entity 디자인 필요)
##   - 거점 진입 시 광기 즉시 회복 (HP 회복과 같은 패턴)
##   - 다회차 페널티 (NG+ 균열 깊이와 결합 가능)

enum MadnessStage { SAFE = 0, WARNING = 1, ALERT = 2, CRITICAL = 3 }

const CONFIG_PATH := "res://data/madness/madness_config.tres"
const TimeStateMachineScript = preload("res://src/systems/time/time_state_machine.gd")

var _config: MadnessConfigData
var _value: float = 0.0
var _stage: int = MadnessStage.SAFE
var _is_time_stopped: bool = false
var _player_ref: Node2D = null


func _ready() -> void:
	_config = load(CONFIG_PATH) as MadnessConfigData
	if _config == null:
		push_warning("MadnessSystem: config 누락 — 기본값 사용")
		_config = MadnessConfigData.new()
	EventBus.time_state_changed.connect(_on_time_state_changed)


func _process(delta: float) -> void:
	if _config == null:
		return
	if _is_time_stopped:
		_recover(delta)
	else:
		_accumulate(delta)


# === 공개 API ===


## 현재 광기 게이지 값 (0~max_value).
func get_value() -> float:
	return _value


## 현재 단계 (MadnessStage 상수).
func get_stage() -> int:
	return _stage


## config 조회 — HUD/이펙트 시너지에서 단계별 보정값 읽기용.
func get_config() -> MadnessConfigData:
	return _config


## 디버그/거점/스토리 트리거용 강제 0 회복.
func reset() -> void:
	_set_value(0.0)


# === 내부 ===


func _on_time_state_changed(_old_state: int, new_state: int) -> void:
	_is_time_stopped = (new_state == TimeStateMachineScript.TimeState.STOPPED)


func _accumulate(delta: float) -> void:
	# 플레이어 위치 그림자 강도 조회 → 임계값 이상이면 누적.
	var player: Node2D = _resolve_player()
	if player == null:
		return
	var intensity: float = ShadowSystem.get_intensity_at(player.global_position)
	if intensity < _config.intensity_threshold:
		return
	# 강도 비례 누적 — 강도 1.0일 때 accumulation_rate * delta.
	var add: float = intensity * _config.accumulation_rate * delta
	_set_value(_value + add)


func _recover(delta: float) -> void:
	if _value <= 0.0:
		return
	var sub: float = _config.recovery_rate * delta
	_set_value(_value - sub)


func _set_value(new_value: float) -> void:
	var clamped: float = clampf(new_value, 0.0, _config.max_value)
	if clamped == _value:
		return
	_value = clamped
	EventBus.madness_changed.emit(_value, _config.max_value)
	_check_stage_change()


func _check_stage_change() -> void:
	var new_stage: int = _resolve_stage(_value / _config.max_value)
	if new_stage == _stage:
		return
	var old_stage: int = _stage
	_stage = new_stage
	EventBus.madness_stage_changed.emit(old_stage, new_stage)


func _resolve_stage(ratio: float) -> int:
	if ratio < _config.stage_safe_end:
		return MadnessStage.SAFE
	if ratio < _config.stage_warning_end:
		return MadnessStage.WARNING
	if ratio < _config.stage_alert_end:
		return MadnessStage.ALERT
	return MadnessStage.CRITICAL


func _resolve_player() -> Node2D:
	if _player_ref != null and is_instance_valid(_player_ref):
		return _player_ref
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player is Node2D:
		_player_ref = player
		return _player_ref
	return null

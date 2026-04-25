extends Node2D

## 환경 오브젝트 공통 베이스.
## 상호작용 게이팅(STOPPED 강제) + 영향 구역 관리 + 하이라이트/프롬프트 토글.
## 서브 클래스는 _on_interact() / _apply_effect() / _clear_effect()를 override.

const TimeStateMachineScript = preload("res://src/systems/time/time_state_machine.gd")

@export var data: EnvironmentObjectData
@export var influence_zone: Area2D
@export var highlight_node: Node2D
@export var prompt_node: Node2D

var _is_active: bool = true
var _player_nearby: bool = false


func _ready() -> void:
	add_to_group("environment_objects")
	if highlight_node:
		highlight_node.visible = false
	if prompt_node:
		prompt_node.visible = false


## 플레이어가 interact_environment 키를 눌렀을 때 호출.
## STOPPED + can_interact + _is_active일 때만 효과 발동.
func interact() -> void:
	if not is_operable():
		return
	_on_interact()


## 서브클래스에서 override.
func _on_interact() -> void:
	pass


## 플레이어 InteractionDetector가 가까워졌을 때 호출.
func notify_player_nearby(nearby: bool) -> void:
	_player_nearby = nearby
	_refresh_prompt()


## 근접 중 현재 플레이어가 가장 가까운 타겟일 때 하이라이트 켜기.
func set_highlight(on: bool) -> void:
	if highlight_node:
		highlight_node.visible = on


## 조작 가능한 상태인지 반환.
func is_operable() -> bool:
	if not _is_active:
		return false
	if data == null or not data.can_interact:
		return false
	if TimeSystem.get_time_state() != TimeStateMachineScript.TimeState.STOPPED:
		return false
	return true


## 플레이어 선택 로직(가장 가까운 오브젝트 찾기)에서 사용.
func get_interaction_radius() -> float:
	if data:
		return data.interaction_radius
	return 48.0


# --- 내부 ---


func _refresh_prompt() -> void:
	if not prompt_node:
		return
	prompt_node.visible = _player_nearby and (data == null or data.can_interact)
	# STOPPED이 아니면 dimmed로 표시
	if prompt_node.visible and prompt_node.has_method("set_dimmed"):
		prompt_node.set_dimmed(not is_operable())

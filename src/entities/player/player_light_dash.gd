extends Node

## 빛 대시 보조 컴포넌트 (Phase 3-3-d 보스 보상 능력).
## state_machine이 LIGHT_DASH 상태로 전이하는 시점에 i-frame을 부여한다.
## 입력/쿨다운/이동 속도는 state_machine + movement에서 처리.
## 잔상/이펙트 등 향후 시각 연출 추가 자리.

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")

var _stats: PlayerStatsData
var _health: Node


func setup(parent: CharacterBody2D) -> void:
	_stats = parent.stats
	_health = parent.get_node_or_null("Health")
	var sm: Node = parent.get_node_or_null("StateMachine")
	if sm:
		sm.state_changed.connect(_on_state_changed)


func _on_state_changed(_old_state: int, new_state: int) -> void:
	if new_state != StateMachine.State.LIGHT_DASH:
		return
	if _health == null or not _health.has_method("set_invulnerable"):
		return
	_health.set_invulnerable(_stats.light_dash_iframe)

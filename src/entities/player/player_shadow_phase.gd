extends Node

## 그림자 잠수 보조 컴포넌트 (Phase 4-0 #4 보스 보상 능력).
## state_machine이 SHADOW_PHASE 상태로 전이하는 시점에 i-frame + afterimage를 부여한다.
## 비행 거동(facing 방향 직선 + 중력 무시)은 player_movement.calculate_velocity에서 처리.
## i-frame(0.32s)이 적/투사체 hurtbox 통과를 보장 — CharacterBody2D 충돌 마스크는 변경하지 않음
## (지형 충돌은 유지해 안전한 게임플레이 경계).
## duration 종료 시 FALL 복귀.

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")

var _stats: PlayerStatsData
var _health: Node
var _sprite: Node2D


func setup(parent: CharacterBody2D) -> void:
	_stats = parent.stats
	_health = parent.get_node_or_null("Health")
	_sprite = parent.get_node_or_null("AnimatedSprite2D")
	var sm: Node = parent.get_node_or_null("StateMachine")
	if sm:
		sm.state_changed.connect(_on_state_changed)


func _on_state_changed(_old_state: int, new_state: int) -> void:
	if new_state != StateMachine.State.SHADOW_PHASE:
		return
	if _health != null and _health.has_method("set_invulnerable"):
		_health.set_invulnerable(_stats.shadow_phase_iframe)
	if _sprite != null:
		var cfg: EffectsConfigData = EffectsSystem.get_config()
		EffectsSystem.request_afterimage(
			_sprite,
			cfg.light_dash_afterimage_count,
			cfg.light_dash_afterimage_interval,
			cfg.light_dash_afterimage_fade
		)

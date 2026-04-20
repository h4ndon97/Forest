extends Node

## 빛 대시 보조 컴포넌트 (Phase 3-3-d 보스 보상 능력).
## state_machine이 LIGHT_DASH 상태로 전이하는 시점에 i-frame + 잔상을 부여한다.
## 입력/쿨다운/이동 속도는 state_machine + movement에서 처리.

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
	if new_state != StateMachine.State.LIGHT_DASH:
		return
	if _health != null and _health.has_method("set_invulnerable"):
		_health.set_invulnerable(_stats.light_dash_iframe)
	if _sprite != null:
		var cfg: EffectsConfigData = EffectsSystem.get_config()
		EffectsSystem.request_afterimage(
			_sprite,
			cfg.light_dash_afterimage_count,
			cfg.light_dash_afterimage_interval,
			cfg.light_dash_afterimage_fade
		)

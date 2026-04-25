extends Node

## 빛 도약 보조 컴포넌트 (Phase 4-0 #4 보스 보상 능력).
## state_machine이 LIGHT_LEAP 상태로 전이하는 시점에 i-frame + afterimage를 부여한다.
## velocity.y 상향 설정은 player.gd._on_state_changed에서, velocity.x 자유 이동은
## player_movement.calculate_velocity에서 처리.
## duration 종료 시 FALL 복귀 — 자연 중력으로 하강.

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
	if new_state != StateMachine.State.LIGHT_LEAP:
		return
	if _health != null and _health.has_method("set_invulnerable"):
		_health.set_invulnerable(_stats.light_leap_iframe)
	var cfg: EffectsConfigData = EffectsSystem.get_config()
	# Light Leap 전용 잔상 (Light Dash보다 진하고 길게).
	if _sprite != null:
		EffectsSystem.request_afterimage(
			_sprite,
			cfg.light_leap_afterimage_count,
			cfg.light_leap_afterimage_interval,
			cfg.light_leap_afterimage_fade
		)
	# 진입 시점 mini screen flash — "빛처럼 쭉 지르는" burst 강조.
	if cfg.light_leap_burst_duration > 0.0:
		EventBus.screen_flash_requested.emit(
			cfg.light_leap_burst_color, cfg.light_leap_burst_duration
		)

extends Node

## 그림자 발걸음 보조 컴포넌트 (Phase 4-0 #4 보스 보상 능력).
## state_machine이 SHADOW_STEP 상태로 전이하는 시점에:
##   1. EnemySystem.get_nearest_enemy로 가까운 적 탐색 (max_dist=stats.shadow_step_max_target_dist)
##   2. 발견 시 적의 등 뒤(facing 반대 + back_offset)로 즉시 텔포 + facing을 적 방향으로
##   3. 발견 안 됨: 위치 유지 (회피 용도, i-frame만)
## i-frame/afterimage는 항상 부여. 입력/쿨다운/duration는 state_machine이 처리.

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")

var _stats: PlayerStatsData
var _parent: CharacterBody2D
var _health: Node
var _sprite: Node2D
var _movement: Node


func setup(parent: CharacterBody2D) -> void:
	_parent = parent
	_stats = parent.stats
	_health = parent.get_node_or_null("Health")
	_sprite = parent.get_node_or_null("AnimatedSprite2D")
	_movement = parent.get_node_or_null("MovementComponent")
	var sm: Node = parent.get_node_or_null("StateMachine")
	if sm:
		sm.state_changed.connect(_on_state_changed)


func _on_state_changed(_old_state: int, new_state: int) -> void:
	if new_state != StateMachine.State.SHADOW_STEP:
		return
	if _health != null and _health.has_method("set_invulnerable"):
		_health.set_invulnerable(_stats.shadow_step_iframe)

	_try_teleport_behind_enemy()

	# 시각 효과: afterimage (light_dash와 동일 파라미터 — Pass 5에서 보라 톤 분리 검토).
	if _sprite != null:
		var cfg: EffectsConfigData = EffectsSystem.get_config()
		EffectsSystem.request_afterimage(
			_sprite,
			cfg.light_dash_afterimage_count,
			cfg.light_dash_afterimage_interval,
			cfg.light_dash_afterimage_fade
		)


func _try_teleport_behind_enemy() -> void:
	if _parent == null or not is_instance_valid(_parent):
		return
	var origin: Vector2 = _parent.global_position
	var nearest: Node = EnemySystem.get_nearest_enemy(origin, _stats.shadow_step_max_target_dist)
	if nearest == null or not (nearest is Node2D):
		return

	var target_pos: Vector2 = (nearest as Node2D).global_position
	# 적의 등 뒤 = (origin → target) 방향의 적 너머. back_dir은 적 너머로 가는 방향.
	var dx: float = target_pos.x - origin.x
	var back_dir: float
	if absf(dx) > 0.001:
		back_dir = signf(dx)
	else:
		# 같은 X축 위에 적이 있으면 facing 방향으로 처리.
		back_dir = float(_movement.facing_direction) if _movement else 1.0
	var teleport_pos: Vector2 = target_pos + Vector2(back_dir * _stats.shadow_step_back_offset, 0.0)
	_parent.global_position = teleport_pos
	_parent.velocity = Vector2.ZERO

	# 적을 마주보도록 facing 보정 (back_dir의 반대)
	if _movement and _movement.has_method("set_facing"):
		_movement.set_facing(-int(back_dir))

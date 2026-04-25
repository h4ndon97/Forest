extends RefCounted

## shadow 피니시 — 근접 적 뒤편 즉시 텔포 + 3단 다단히트 + 0.35s i-frame (COMBAT.md §2).
## 적 부재 시 finish_neutral로 fallback (D3).

const FinishStrategyScript = preload("res://src/entities/player/finish/finish_strategy.gd")
const FinishNeutralScript = preload("res://src/entities/player/finish/finish_neutral.gd")

const SHADOW_SEARCH_RANGE := 120.0
## 텔포 착지점 = 적 위치에서 player의 새 facing 기준 뒤쪽으로 28px.
const SHADOW_TELEPORT_BEHIND_OFFSET := 28.0
const SHADOW_IFRAME_DURATION := 0.35
## 3단 다단히트: t=0, 0.1, 0.2. 각 히트 활성 0.08s.
const SHADOW_HIT_COUNT := 3
const SHADOW_HIT_INTERVAL := 0.1
const SHADOW_HIT_DURATION := 0.08


static func execute(ctx: Dictionary) -> void:
	var player: CharacterBody2D = ctx.get(FinishStrategyScript.KEY_PLAYER)
	var movement: Node = ctx.get(FinishStrategyScript.KEY_MOVEMENT)
	if player == null or movement == null:
		FinishNeutralScript.execute(ctx)
		return

	var target: Node = EnemySystem.get_nearest_enemy(player.global_position, SHADOW_SEARCH_RANGE)
	if target == null or not (target is Node2D):
		# D3: 적 부재 시 일반 피니시로 폴백 (UX 혼선 방지).
		FinishNeutralScript.execute(ctx)
		return

	# 텔포 후 바라볼 방향 = 적 방향. 그림자 섀도우는 "뒤로 돌아가 연타" — 적 뒤에서 적 쪽을 봄.
	var enemy_pos: Vector2 = (target as Node2D).global_position
	var to_enemy_x: float = enemy_pos.x - player.global_position.x
	var new_facing: int = 1 if to_enemy_x >= 0.0 else -1
	if movement.has_method("_update_facing"):
		# facing_direction은 public이지만 _update_facing이 signal을 emit하므로 우회.
		movement.call("_update_facing", float(new_facing))
	else:
		movement.facing_direction = new_facing

	# 적 뒤로 텔포 — 적의 반대편. new_facing이 오른쪽(1)이면 적의 왼쪽(x - 28)에 착지.
	player.global_position = enemy_pos + Vector2(-new_facing * SHADOW_TELEPORT_BEHIND_OFFSET, 0.0)

	# i-frame
	var health: Node = ctx.get(FinishStrategyScript.KEY_HEALTH)
	if health != null and health.has_method("set_invulnerable"):
		health.set_invulnerable(SHADOW_IFRAME_DURATION)

	# 3단 다단히트 스케줄. ctx는 Dictionary(참조)이므로 람다 캡처 안전.
	var per_hit_damage: float = (
		ctx.get(FinishStrategyScript.KEY_DAMAGE, 0.0) / float(SHADOW_HIT_COUNT)
	)
	var tree: SceneTree = player.get_tree()
	for i in range(SHADOW_HIT_COUNT):
		var delay: float = i * SHADOW_HIT_INTERVAL
		if delay <= 0.0:
			_spawn_single_hit(ctx, per_hit_damage)
		else:
			var timer: SceneTreeTimer = tree.create_timer(delay, true, false, true)
			# 캡처한 ctx/damage로 단일 히트 스폰. 플레이어가 사망하면 spawn_standard_finish_hitbox가
			# spec.attacker 검증에서 실패해 자연 스킵.
			timer.timeout.connect(func(): _spawn_single_hit(ctx, per_hit_damage))


static func _spawn_single_hit(ctx: Dictionary, damage_override: float) -> void:
	FinishStrategyScript.spawn_standard_finish_hitbox(
		ctx, Vector2.ZERO, Vector2.ZERO, SHADOW_HIT_DURATION, damage_override
	)

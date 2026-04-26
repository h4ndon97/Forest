extends RefCounted

## light 피니시 — LIGHT_DASH 상태 강제 진입으로 전방 돌진 + i-frame + afterimage 자동 처리,
## 확장된 60×24 히트박스로 돌진 경로 전체 커버 (COMBAT.md §2).
## 해금/쿨다운 조건 무시 — 콤보 피니시 전용 경로.
##
## REC-MECH-007 (2026-04-26): 같은 룸 내 거울에서 빛 빔 반사 추가 트리거.
## 거울이 그룹 "mirror"에 등록되어 있고 같은 stage scene 안에 있으면 자동 발동.
## 빔 hitbox는 거울의 rotation_pivot 자식으로 spawn → 거울 회전 자동 추적.

const FinishStrategyScript = preload("res://src/entities/player/finish/finish_strategy.gd")

## 돌진 경로를 모두 포함하도록 전방 확장된 히트박스.
const LIGHT_HITBOX_SIZE := Vector2(60, 24)
const LIGHT_HITBOX_OFFSET := Vector2(40, -14)
## light_dash_duration(0.18s)보다 살짝 길게 설정해 돌진 종료 후 여운 타격 허용.
const LIGHT_ACTIVE_DURATION := 0.22


static func execute(ctx: Dictionary) -> void:
	var player: CharacterBody2D = ctx.get(FinishStrategyScript.KEY_PLAYER)
	if player != null:
		var state_machine: Node = player.get_node_or_null("StateMachine")
		if state_machine != null and state_machine.has_method("force_light_dash"):
			state_machine.force_light_dash()

	FinishStrategyScript.spawn_standard_finish_hitbox(
		ctx, LIGHT_HITBOX_SIZE, LIGHT_HITBOX_OFFSET, LIGHT_ACTIVE_DURATION
	)

	# REC-MECH-007: 같은 룸 내 거울에서 빛 빔 반사 동시 발동.
	_trigger_mirror_reflections(ctx)


# === REC-MECH-007: 거울 반사 ===


static func _trigger_mirror_reflections(ctx: Dictionary) -> void:
	var player: CharacterBody2D = ctx.get(FinishStrategyScript.KEY_PLAYER)
	if player == null or not is_instance_valid(player):
		return
	var tree: SceneTree = player.get_tree()
	if tree == null:
		return
	var mirrors: Array = tree.get_nodes_in_group("mirror")
	if mirrors.is_empty():
		return
	var fx_config: EffectsConfigData = EffectsSystem.get_config()
	if fx_config == null:
		return
	var finish_damage: float = ctx.get(FinishStrategyScript.KEY_DAMAGE, 0.0)
	var beam_damage: float = finish_damage * fx_config.light_beam_damage_ratio
	if beam_damage <= 0.0:
		return
	for mirror in mirrors:
		if not is_instance_valid(mirror):
			continue
		_emit_beam_from_mirror(mirror, beam_damage, fx_config)


static func _emit_beam_from_mirror(
	mirror: Node, beam_damage: float, fx_config: EffectsConfigData
) -> void:
	var pivot: Node2D = mirror.get("rotation_pivot") as Node2D
	if pivot == null or not is_instance_valid(pivot):
		return
	# 시각: 거울 위치 + pivot.global_rotation 방향으로 빛 빔.
	EffectsSystem.spawn_light_beam(pivot.global_position, pivot.global_rotation)
	# Hitbox: AttackSpec → CombatSystem.request_attack.
	# spec.attacker = pivot 으로 두면 hitbox가 pivot 자식 → 거울 회전 자동 추적.
	var spec := AttackSpec.new()
	spec.attacker = pivot
	spec.source_group = "player_attack"
	spec.shape_type = "rect"
	var length: float = fx_config.light_beam_length
	var width: float = fx_config.light_beam_width
	spec.hitbox_size = Vector2(length, width)
	# 거울 위치(local 0)에서 +x 방향으로 length/2 만큼 이동한 중심.
	spec.hitbox_offset = Vector2(length * 0.5, 0.0)
	spec.active_duration = fx_config.light_beam_active_duration
	spec.damage = beam_damage
	spec.attribute = "light"
	spec.is_finish = false
	spec.piercing = true  # 룸 내 다중 적 관통.
	spec.tags = PackedStringArray(["mirror_reflection", "light"])
	CombatSystem.request_attack(spec)

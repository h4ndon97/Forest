extends RefCounted

## light 피니시 — LIGHT_DASH 상태 강제 진입으로 전방 돌진 + i-frame + afterimage 자동 처리,
## 확장된 60×24 히트박스로 돌진 경로 전체 커버 (COMBAT.md §2).
## 해금/쿨다운 조건 무시 — 콤보 피니시 전용 경로.

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

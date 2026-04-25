extends RefCounted

## hybrid 피니시 — 제자리 + 80×40 광역 히트박스 (COMBAT.md §2).
## 다중 타겟 동시 데미지. neutral 대비 가로·세로 모두 확장.

const FinishStrategyScript = preload("res://src/entities/player/finish/finish_strategy.gd")

const HYBRID_HITBOX_SIZE := Vector2(80, 40)
## offset.x는 facing에 맞춰 spawn helper가 재계산. y는 config 기본값 유지.
const HYBRID_HITBOX_OFFSET := Vector2(32, -14)


static func execute(ctx: Dictionary) -> void:
	FinishStrategyScript.spawn_standard_finish_hitbox(ctx, HYBRID_HITBOX_SIZE, HYBRID_HITBOX_OFFSET)

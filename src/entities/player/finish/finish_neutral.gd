extends RefCounted

## neutral 피니시 — 표준 히트박스 + finish_damage. 강넉백은 Phase 5 밸런싱 이월.

const FinishStrategyScript = preload("res://src/entities/player/finish/finish_strategy.gd")


static func execute(ctx: Dictionary) -> void:
	FinishStrategyScript.spawn_standard_finish_hitbox(ctx)

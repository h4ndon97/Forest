extends Node2D

## 2-1 입구 스텁 (Phase 3-3-d).
## 정식 2구역 콘텐츠는 Phase 4부터. 현재는 stage_2_1.tres ABILITY 잠금 검증용.

const STAGE_ID := "stage_2_1"
const SPAWN_POSITION := Vector2(80, 320)


func _ready() -> void:
	EventBus.stage_entered.emit(STAGE_ID)
	EventBus.spawn_point_set.emit(SPAWN_POSITION)
	StageCamera.apply(STAGE_ID)

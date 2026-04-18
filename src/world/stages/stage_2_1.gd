extends Node2D

## 2-1 입구 스텁 (Phase 3-3-d).
## 정식 2구역 콘텐츠는 Phase 4부터. 현재는 stage_2_1.tres ABILITY 잠금 검증용.

const STAGE_ID := "stage_2_1"
const SPAWN_POSITION := Vector2(80, 320)
const STAGE_WIDTH := 640
const STAGE_HEIGHT := 360


func _ready() -> void:
	EventBus.stage_entered.emit(STAGE_ID)
	EventBus.spawn_point_set.emit(SPAWN_POSITION)
	_setup_camera_limits()


func _setup_camera_limits() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if not camera:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = STAGE_WIDTH
	camera.limit_bottom = STAGE_HEIGHT

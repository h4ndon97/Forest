class_name StageCamera
extends RefCounted

## 스테이지 카메라 limit 적용 헬퍼.
## StageData.room_size 기반으로 Player의 Camera2D.limit_*을 (0, 0)~size로 설정한다.
## 각 스테이지 _ready에서 StageCamera.apply(STAGE_ID) 한 줄로 사용.

const _DEFAULT_SIZE := Vector2(640, 360)


## stage_id로 StageData를 룩업해 카메라 limit을 적용한다.
## player가 트리에 없거나 Camera2D 자식이 없으면 silent skip.
static func apply(stage_id: String) -> void:
	var camera := _resolve_player_camera()
	if camera == null:
		return
	var size: Vector2 = _resolve_room_size(stage_id)
	_set_limits(camera, size)


## 명시적 Camera2D + size로 적용 (test 씬 등 stage_data 없는 곳용).
static func apply_to(camera: Camera2D, size: Vector2) -> void:
	if camera == null:
		return
	_set_limits(camera, size)


# --- 내부 ---


static func _resolve_player_camera() -> Camera2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var player := tree.get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as Camera2D


static func _resolve_room_size(stage_id: String) -> Vector2:
	if stage_id.is_empty():
		return _DEFAULT_SIZE
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if data == null:
		return _DEFAULT_SIZE
	return data.room_size


static func _set_limits(camera: Camera2D, size: Vector2) -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)

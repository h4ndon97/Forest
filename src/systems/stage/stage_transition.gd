extends CanvasLayer

## 스테이지 전환 연출 (페이드 인/아웃) 및 씬 로딩을 담당한다.
## Player를 씬 전환 전에 분리 보존하고, 새 씬에 재삽입한다.
## StageSystem의 자식 노드로 동작한다.

const FADE_DURATION := 0.3
const SPAWN_MARGIN := 48.0
const SPAWN_Y_FLOOR := 320.0

var _fade_rect: ColorRect
var _is_transitioning: bool = false
var _pending_entry_direction: String = ""


func _ready() -> void:
	layer = 100
	_create_fade_rect()


## 전환 실행. 페이드 아웃 → Player 보존 → 씬 전환 → Player 재삽입 → 페이드 인.
func execute(scene_path: String, entry_direction: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_pending_entry_direction = entry_direction

	# 입력 차단
	get_tree().paused = true

	# 페이드 아웃
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	# Player를 씬 트리에서 분리하여 보존
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	if player and player.get_parent():
		player.get_parent().remove_child(player)

	# 씬 전환
	get_tree().change_scene_to_file(scene_path)

	# 1프레임 대기 (새 씬 _ready 완료 보장)
	await get_tree().process_frame
	await get_tree().process_frame

	# Player를 새 씬에 삽입하고 위치 설정
	_reinsert_player(player)

	# 페이드 인
	var tween_in := create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tween_in.finished

	# 입력 복원
	get_tree().paused = false
	_is_transitioning = false

	# 카메라 smoothing 최종 reset — paused 동안 Camera2D._process가 멈춰
	# _camera_pos가 stale이므로 paused 해제 후 한 프레임 진행한 뒤 재동기화.
	# (StageCamera._set_limits의 deferred reset은 paused 동안 stale 값으로 sync되어 보정 필요)
	await get_tree().process_frame
	if player:
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera:
			camera.reset_smoothing()


func is_transitioning() -> bool:
	return _is_transitioning


## 페이드 사각형을 즉시 검정으로 설정한다 (세이브 로드 시 초기 씬 노출 방지).
func set_fade_black() -> void:
	_fade_rect.color = Color(0, 0, 0, 1)


# --- 내부 ---


func _create_fade_rect() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)


func _reinsert_player(player: CharacterBody2D) -> void:
	if not player:
		push_warning("StageTransition: Player가 없어 재삽입 불가")
		return

	var root := get_tree().current_scene
	if not root:
		push_warning("StageTransition: 현재 씬이 없음")
		return

	# 새 씬에 이미 Player 노드가 있으면 제거 (중복 방지)
	var existing_player := get_tree().get_first_node_in_group("player")
	if existing_player and existing_player != player:
		existing_player.queue_free()

	root.add_child(player)

	# 진입 방향에 따라 스폰 위치 결정
	var viewport_width := float(
		ProjectSettings.get_setting("display/window/size/viewport_width", 640)
	)

	if _pending_entry_direction == "left":
		player.global_position = Vector2(SPAWN_MARGIN, SPAWN_Y_FLOOR)
	elif _pending_entry_direction == "right":
		player.global_position = Vector2(viewport_width - SPAWN_MARGIN, SPAWN_Y_FLOOR)
	elif _pending_entry_direction == "checkpoint":
		player.global_position = Vector2(viewport_width / 2.0, SPAWN_Y_FLOOR)

	player.velocity = Vector2.ZERO

	# 리스폰 포인트 갱신
	EventBus.spawn_point_set.emit(player.global_position)

	# 카메라 limit 재적용 — Stage._ready 시점엔 player가 트리에 없어 skip되므로 reinsert 후 1회 더.
	StageCamera.apply(StageSystem.get_current_stage_id())

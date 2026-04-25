extends Area2D

## 스테이지 간 이동 포탈.
## 플레이어가 영역 안에서 윗방향키를 누르면 전환을 요청한다.

const INWARD_OFFSET_X: float = 24.0

## 이 포탈이 연결하는 목적지 스테이지 ID
@export var target_stage_id: String = ""
## 포탈 배치 방향 ("left" 또는 "right"). 플레이어 진입 시 반대쪽에서 스폰.
@export var direction: String = "right"

var _player_in_area: bool = false
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.stage_access_denied.connect(_on_access_denied)
	_apply_direction_offset()


func _apply_direction_offset() -> void:
	# 스프라이트 캔버스가 충돌 박스보다 넓어 맵 경계에 잘리는 것을 보완 —
	# 좌측 포탈은 오른쪽으로, 우측 포탈은 왼쪽으로 시각만 살짝 안쪽 이동.
	var visual := get_node_or_null("PortalVisual") as Node2D
	if visual == null:
		return
	var sign_x: float = 1.0 if direction == "left" else -1.0
	visual.position.x = sign_x * INWARD_OFFSET_X


func _process(_delta: float) -> void:
	if not _player_in_area or _triggered:
		return
	if Input.is_action_just_pressed("move_up"):
		_activate()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = true
		_notify_visual(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = false
		_notify_visual(false)


func _notify_visual(nearby: bool) -> void:
	var visual := get_node_or_null("PortalVisual")
	if visual and visual.has_method("set_player_nearby"):
		visual.set_player_nearby(nearby)


func _activate() -> void:
	if target_stage_id.is_empty():
		push_warning("StagePortal: target_stage_id가 설정되지 않음")
		return

	_triggered = true
	var entry_dir := "left" if direction == "right" else "right"
	EventBus.stage_transition_requested.emit(target_stage_id, entry_dir, {})


func _on_access_denied(stage_id: String, _lock_type: int, _reason: String) -> void:
	if stage_id == target_stage_id:
		_triggered = false

extends Node

## 월드맵 입력 라우터 — Stage 0.
## WorldMapUI 자식 노드. process_mode=ALWAYS로 일시정지와 무관하게 입력 수신.
## 닫힘 상태: M키 → OpenPolicy 통과 시 view-only 모드로 world_map_opened emit.
## 열림 상태: 기존 _process 입력(close/navigate/travel)을 모드별 분기로 처리.

const OpenPolicyScript = preload("res://src/ui/menus/world_map/world_map_open_policy.gd")

var _ui: Node  # WorldMapUI Autoload
var _open_policy: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = get_parent()
	_open_policy = Node.new()
	_open_policy.name = "OpenPolicy"
	_open_policy.set_script(OpenPolicyScript)
	add_child(_open_policy)


func _process(_delta: float) -> void:
	if _ui.is_open():
		_handle_open_input()
	else:
		_handle_closed_input()


# 닫힘 상태 — M키 토글 트리거.
func _handle_closed_input() -> void:
	if not Input.is_action_just_pressed("map"):
		return
	if not _open_policy.can_open():
		return
	_ui.set_open_mode(_ui.MODE_VIEW_ONLY)
	EventBus.world_map_opened.emit()


# 열림 상태 — close / navigate / travel 라우팅.
func _handle_open_input() -> void:
	if (
		Input.is_action_just_pressed("interact")
		or Input.is_action_just_pressed("ui_cancel")
		or Input.is_action_just_pressed("map")
	):
		_ui.close_world_map()
		return

	if not _ui.has_selectables():
		return

	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_ui.navigate(-1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_ui.navigate(1)
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_accept"):
		if _ui.get_open_mode() == _ui.MODE_FAST_TRAVEL:
			_ui.travel_to_selected()

extends "res://src/entities/objects/environment/base/environment_object.gd"

## 수문(Floodgate) 환경 오브젝트.
## STOPPED 중 interact()로 토글 (closed ↔ open).
## 토글 시 StateFlags.set_flag(flag_id, _is_open) — 영속 플래그.
## zone3+ HiddenRevealer(FLAG)가 해당 플래그를 구독해 막힌 경로/물 반사면 노출.
##
## 본 Step 4에서는 자체 효과 없음 — 깃발 신호만. 실제 영향은 zone3+ 콘텐츠가 결정.

@export var floodgate_data: FloodgateData

var _is_open: bool = false

@onready var _body_visual: ColorRect = $Body/Visual
@onready var _highlight_node_local: Node2D = $Highlight
@onready var _prompt_node_local: Node2D = $Prompt


func _ready() -> void:
	highlight_node = _highlight_node_local
	prompt_node = _prompt_node_local
	super._ready()
	if floodgate_data == null:
		push_warning("Floodgate: floodgate_data 미설정")
		return
	data = floodgate_data
	# 영속 플래그가 이미 set이면 시작부터 open 상태로 복원
	_is_open = (
		StateFlags.has_flag(floodgate_data.flag_id) and StateFlags.get_flag(floodgate_data.flag_id)
	)
	_apply_visual_state()


func _on_interact() -> void:
	if floodgate_data == null:
		return
	_is_open = not _is_open
	_apply_visual_state()
	StateFlags.set_flag(floodgate_data.flag_id, _is_open)
	EventBus.environment_interacted.emit(get_instance_id(), 1 if _is_open else 0)


# --- 내부 ---


func _apply_visual_state() -> void:
	if _body_visual == null or floodgate_data == null:
		return
	_body_visual.color = (floodgate_data.open_color if _is_open else floodgate_data.closed_color)

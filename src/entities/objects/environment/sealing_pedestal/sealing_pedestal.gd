extends "res://src/entities/objects/environment/base/environment_object.gd"

## 봉인 제단(SealingPedestal) 환경 오브젝트.
## STOPPED 중 interact()로 *한 번만* 활성화 (재사용 불가, 영구 ON).
## 활성화 시 StateFlags.set_flag(flag_id, true) — 영속 플래그.
## Phase 4-C zone4 콘텐츠 작업 시 활용처 결정 (HiddenRevealer FLAG 구독 등).
##
## 본 Step 4에서는 자체 효과 없음 — 깃발 신호만. 실제 영향은 zone4+ 콘텐츠가 결정.

@export var sealing_pedestal_data: SealingPedestalData

var _is_activated: bool = false

@onready var _body_visual: ColorRect = $Body/Visual
@onready var _highlight_node_local: Node2D = $Highlight
@onready var _prompt_node_local: Node2D = $Prompt


func _ready() -> void:
	highlight_node = _highlight_node_local
	prompt_node = _prompt_node_local
	super._ready()
	if sealing_pedestal_data == null:
		push_warning("SealingPedestal: sealing_pedestal_data 미설정")
		return
	data = sealing_pedestal_data
	# 영속 플래그가 이미 set이면 시작부터 활성 상태로 복원
	_is_activated = (
		StateFlags.has_flag(sealing_pedestal_data.flag_id)
		and StateFlags.get_flag(sealing_pedestal_data.flag_id)
	)
	_apply_visual_state()


func _on_interact() -> void:
	if sealing_pedestal_data == null:
		return
	# 봉인 제단은 한 번 활성화 후 영구 ON — 재토글 불가
	if _is_activated:
		return
	_is_activated = true
	_apply_visual_state()
	StateFlags.set_flag(sealing_pedestal_data.flag_id, true)
	EventBus.environment_interacted.emit(get_instance_id(), 1)


# --- 내부 ---


func _apply_visual_state() -> void:
	if _body_visual == null or sealing_pedestal_data == null:
		return
	_body_visual.color = (
		sealing_pedestal_data.active_color
		if _is_activated
		else sealing_pedestal_data.inactive_color
	)

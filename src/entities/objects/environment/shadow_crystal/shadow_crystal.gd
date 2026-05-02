extends "res://src/entities/objects/environment/base/environment_object.gd"

## 그림자 결정(ShadowCrystal) 환경 오브젝트.
## STOPPED 중 interact()로 *한 번만* 동조 (재사용 불가, 영구 ON).
## 동조 시 StateFlags.set_flag(flag_id, true) — 영속 플래그.
## Phase 4-D zone5 *최종 보스실 진입 조건* (zone5 본 진행은 미동조자도 가능).
## sealing_pedestal.gd 답습 — flag·이름·색조만 차별화.

@export var shadow_crystal_data: ShadowCrystalData

var _is_attuned: bool = false

@onready var _body_visual: ColorRect = $Body/Visual
@onready var _highlight_node_local: Node2D = $Highlight
@onready var _prompt_node_local: Node2D = $Prompt


func _ready() -> void:
	highlight_node = _highlight_node_local
	prompt_node = _prompt_node_local
	super._ready()
	if shadow_crystal_data == null:
		push_warning("ShadowCrystal: shadow_crystal_data 미설정")
		return
	data = shadow_crystal_data
	# 영속 플래그가 이미 set이면 시작부터 동조 상태로 복원
	_is_attuned = (
		StateFlags.has_flag(shadow_crystal_data.flag_id)
		and StateFlags.get_flag(shadow_crystal_data.flag_id)
	)
	_apply_visual_state()


func _on_interact() -> void:
	if shadow_crystal_data == null:
		return
	# 그림자 결정은 한 번 동조 후 영구 ON — 재토글 불가
	if _is_attuned:
		return
	_is_attuned = true
	_apply_visual_state()
	StateFlags.set_flag(shadow_crystal_data.flag_id, true)
	EventBus.environment_interacted.emit(get_instance_id(), 1)


# --- 내부 ---


func _apply_visual_state() -> void:
	if _body_visual == null or shadow_crystal_data == null:
		return
	_body_visual.color = (
		shadow_crystal_data.active_color
		if _is_attuned
		else shadow_crystal_data.inactive_color
	)

extends "res://src/entities/objects/environment/base/environment_object.gd"

## 횃불(Torch) 환경 오브젝트.
## STOPPED 중 interact()로 점화 ↔ 소화 토글 (Floodgate 답습).
## 점화 시 같은 stage 안 보스 약점 노출 — `EventBus.boss_weak_point_exposed.emit` (Lens 답습).
## 소화 시 약점 닫힘. zone4 Lord Remnant 약점 트리거 인프라.
##
## 참고: weak_point_reveal_source는 BossStatsData 메타 분류 필드 — 코드 영향 없음.
## base_boss는 boss_weak_point_exposed 시그널 자체를 source-agnostic하게 구독.

@export var torch_data: TorchData

var _is_lit: bool = false

@onready var _body_visual: ColorRect = $Body/Visual
@onready var _highlight_node_local: Node2D = $Highlight
@onready var _prompt_node_local: Node2D = $Prompt


func _ready() -> void:
	highlight_node = _highlight_node_local
	prompt_node = _prompt_node_local
	super._ready()
	if torch_data == null:
		push_warning("Torch: torch_data 미설정")
		return
	data = torch_data
	_apply_visual_state()


func _on_interact() -> void:
	if torch_data == null:
		return
	_is_lit = not _is_lit
	_apply_visual_state()
	_emit_boss_weak_point(_is_lit)
	EventBus.environment_interacted.emit(get_instance_id(), 1 if _is_lit else 0)


# --- 내부 ---


func _emit_boss_weak_point(exposed: bool) -> void:
	# 같은 stage 안 보스만 약점 노출 — 다른 stage 보스에 영향 없음
	var stage: Node = get_parent()
	if stage == null:
		return
	for child in stage.get_children():
		if not child.is_in_group("bosses"):
			continue
		var boss_data: Variant = child.get("boss_data")
		if boss_data == null:
			continue
		EventBus.boss_weak_point_exposed.emit(boss_data.boss_id, exposed)


func _apply_visual_state() -> void:
	if _body_visual == null or torch_data == null:
		return
	_body_visual.color = (torch_data.lit_color if _is_lit else torch_data.unlit_color)

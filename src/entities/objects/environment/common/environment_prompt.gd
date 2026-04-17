extends Node2D

## 환경 오브젝트 상호작용 프롬프트 (fallback 라벨).
## 플레이어 근접 시 "E: <액션>" 표시.
## 시간이 정지 상태가 아니면 dimmed 표시.

@export var prompt_text: String = "상호작용"
@export var offset_y: float = -48.0
@export var dimmed_alpha: float = 0.35

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.text = "[E] " + prompt_text
	_label.position = Vector2(-24, offset_y)
	_label.modulate = Color(1, 1, 1, 1)
	add_child(_label)


## 외부에서 프롬프트 문구 갱신 (거울 회전 상태 등).
func set_prompt_text(text: String) -> void:
	prompt_text = text
	if _label:
		_label.text = "[E] " + text


## 조작 불가능 상태(시간 흐름 중 등) 표시.
func set_dimmed(dimmed: bool) -> void:
	if not _label:
		return
	var a: float = dimmed_alpha if dimmed else 1.0
	_label.modulate = Color(1, 1, 1, a)

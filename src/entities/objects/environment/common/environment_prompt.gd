extends Node2D

## 환경 오브젝트 상호작용 프롬프트 — 간결한 "E" 힌트.
## 플레이어 근접 시 표시, 시간 흐름 중에는 dimmed.
## prompt_text 는 legacy API 호환을 위해 유지되나 화면에는 "E" 만 표시.

const FONT_SIZE: int = 10
const BASE_ALPHA: float = 0.85

@export var prompt_text: String = ""
@export var offset_y: float = -24.0
@export var dimmed_alpha: float = 0.35

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.text = "E"
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.position = Vector2(-4, offset_y)
	_label.modulate = Color(1, 1, 1, BASE_ALPHA)
	add_child(_label)


## Legacy API 호환 — 표시 텍스트는 변경되지 않음 (항상 "E").
func set_prompt_text(text: String) -> void:
	prompt_text = text


## 조작 불가능 상태(시간 흐름 중 등) 표시.
func set_dimmed(dimmed: bool) -> void:
	if not _label:
		return
	var a: float = dimmed_alpha if dimmed else BASE_ALPHA
	_label.modulate = Color(1, 1, 1, a)

class_name OverlayVignette
extends ColorRect

## Phase 3-7 Pass 1 — 비네트 슬롯 스텁.
## Pass 4 (땅거미 공포 연출)에서 거리 기반 색/알파 보간을 구현한다.
## Pass 1 단계는 색·알파 API 시그니처만 노출하고 본문은 단색 모드.

var _current_color: Color = Color(0.0, 0.0, 0.0, 0.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = _current_color
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_vignette(color_value: Color, alpha: float) -> void:
	_current_color = color_value
	_current_color.a = clampf(alpha, 0.0, 1.0)
	color = _current_color


func clear() -> void:
	_current_color = Color(0.0, 0.0, 0.0, 0.0)
	color = _current_color

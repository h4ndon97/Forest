class_name MenuFrame
extends Control

## 공통 메뉴 프레임. 어두운 베일 + 중앙 테두리 패널 + 제목 라벨 + 하단 힌트 라벨.
## CanvasLayer 자식으로 attach하여 사용한다.
## 컨텐츠는 get_content_root()에 add_child하거나 프레임과 같은 CanvasLayer 레벨에 추가.

const FRAME_BORDER_COLOR := Color("F2CC66")
const FRAME_BG_COLOR := Color(0.08, 0.06, 0.04, 0.92)
const TITLE_COLOR := Color("F2CC66")
const HINT_COLOR := Color("8A8070")
const VEIL_DEFAULT_ALPHA: float = 0.6
const TITLE_FONT_SIZE: int = 22
const HINT_FONT_SIZE: int = 10
const TITLE_PAD_TOP: float = 18.0
const TITLE_AREA_HEIGHT: float = 34.0
const HINT_PAD_BOTTOM: float = 12.0
const HINT_AREA_HEIGHT: float = 16.0

var _frame_size: Vector2 = Vector2(240, 320)
var _veil: ColorRect
var _border: ColorRect
var _bg: ColorRect
var _title_label: Label
var _hint_label: Label
var _content_root: Control


## 부모 CanvasLayer에 attach하고 프레임 레이아웃을 구성한다.
func setup(parent: CanvasLayer, frame_size: Vector2, title_text: String = "") -> void:
	_frame_size = frame_size
	name = "MenuFrame"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	set_title(title_text)
	set_hint("")


func set_veil_enabled(enabled: bool) -> void:
	if _veil:
		_veil.visible = enabled


func set_title(text: String) -> void:
	if _title_label == null:
		return
	_title_label.text = text
	_title_label.visible = not text.is_empty()


func set_hint(text: String) -> void:
	if _hint_label == null:
		return
	_hint_label.text = text
	_hint_label.visible = not text.is_empty()


## 컨텐츠 추가용 풀스크린 Control. 프레임 위에 그려진다.
func get_content_root() -> Control:
	return _content_root


func _build_layout() -> void:
	_veil = ColorRect.new()
	_veil.name = "Veil"
	_veil.color = Color(0, 0, 0, VEIL_DEFAULT_ALPHA)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_border = ColorRect.new()
	_border.name = "FrameBorder"
	_border.color = FRAME_BORDER_COLOR
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border)
	_center_rect(_border, _frame_size + Vector2(2, 2))

	_bg = ColorRect.new()
	_bg.name = "FrameBg"
	_bg.color = FRAME_BG_COLOR
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_center_rect(_bg, _frame_size)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)
	_anchor_top_strip(_title_label, TITLE_PAD_TOP, TITLE_AREA_HEIGHT)

	_content_root = Control.new()
	_content_root.name = "ContentRoot"
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_root)
	_content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", HINT_COLOR)
	_hint_label.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_label)
	_anchor_bottom_strip(_hint_label, HINT_PAD_BOTTOM, HINT_AREA_HEIGHT)


func _center_rect(ctrl: Control, rect_size: Vector2) -> void:
	ctrl.anchor_left = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.offset_left = -rect_size.x * 0.5
	ctrl.offset_right = rect_size.x * 0.5
	ctrl.offset_top = -rect_size.y * 0.5
	ctrl.offset_bottom = rect_size.y * 0.5


func _anchor_top_strip(ctrl: Control, pad_top: float, height: float) -> void:
	ctrl.anchor_left = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.offset_left = -_frame_size.x * 0.5
	ctrl.offset_right = _frame_size.x * 0.5
	ctrl.offset_top = -_frame_size.y * 0.5 + pad_top
	ctrl.offset_bottom = -_frame_size.y * 0.5 + pad_top + height


func _anchor_bottom_strip(ctrl: Control, pad_bottom: float, height: float) -> void:
	ctrl.anchor_left = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.offset_left = -_frame_size.x * 0.5
	ctrl.offset_right = _frame_size.x * 0.5
	ctrl.offset_top = _frame_size.y * 0.5 - pad_bottom - height
	ctrl.offset_bottom = _frame_size.y * 0.5 - pad_bottom

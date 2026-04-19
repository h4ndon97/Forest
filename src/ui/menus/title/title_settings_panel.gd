extends Node

## 타이틀 설정 패널 — placeholder.
## BGM/SFX/창모드 항목만 시각적으로 표시, 값은 저장되지 않음.
## Phase 5 접근성 단계에서 실제 구현 예정.

signal closed

const COLOR_BG := Color(0.10, 0.08, 0.06, 0.94)
const COLOR_BORDER := Color("F2CC66")
const COLOR_LABEL := Color("F0E8D8")
const COLOR_HINT := Color("8A8070")
const PANEL_SIZE := Vector2(420, 240)
const FONT_SIZE: int = 13

var _root: Control
var _dim_rect: ColorRect
var _is_open: bool = false


func setup(parent_layer: CanvasLayer) -> void:
	_root = Control.new()
	_root.name = "SettingsRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	parent_layer.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim_rect = ColorRect.new()
	_dim_rect.color = Color(0, 0, 0, 0.5)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim_rect)
	_dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_panel()


func open() -> void:
	_root.visible = true
	_is_open = true


func close() -> void:
	_root.visible = false
	_is_open = false
	closed.emit()


func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("attack"):
		close()


func _build_panel() -> void:
	var border := ColorRect.new()
	border.color = COLOR_BORDER
	_center(border, PANEL_SIZE + Vector2(4, 4))
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(border)
	var panel := ColorRect.new()
	panel.color = COLOR_BG
	_center(panel, PANEL_SIZE)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)
	_add_title_label()
	_add_notice_label()
	_add_placeholder_rows()
	_add_close_hint()


func _add_title_label() -> void:
	var label := Label.new()
	label.text = "설정"
	label.add_theme_color_override("font_color", COLOR_LABEL)
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(label, Vector2(-PANEL_SIZE.x * 0.5, -PANEL_SIZE.y * 0.5 + 12), Vector2(PANEL_SIZE.x, 28))
	_root.add_child(label)


func _add_notice_label() -> void:
	var label := Label.new()
	label.text = "* 현재 설정은 저장되지 않습니다 (Phase 5 구현 예정)"
	label.add_theme_color_override("font_color", COLOR_HINT)
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(label, Vector2(-PANEL_SIZE.x * 0.5, -PANEL_SIZE.y * 0.5 + 44), Vector2(PANEL_SIZE.x, 20))
	_root.add_child(label)


func _add_placeholder_rows() -> void:
	var rows := [
		{"label": "BGM 볼륨", "type": "slider"},
		{"label": "SFX 볼륨", "type": "slider"},
		{"label": "창 모드", "type": "toggle"},
	]
	for i in rows.size():
		var y_offset: float = -PANEL_SIZE.y * 0.5 + 80 + i * 36
		_add_row(rows[i]["label"], rows[i]["type"], y_offset)


func _add_row(label_text: String, control_type: String, y_offset: float) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLOR_LABEL)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	_place(label, Vector2(-PANEL_SIZE.x * 0.5 + 24, y_offset), Vector2(140, 24))
	_root.add_child(label)
	if control_type == "slider":
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.value = 80
		slider.focus_mode = Control.FOCUS_NONE
		_place(slider, Vector2(-PANEL_SIZE.x * 0.5 + 180, y_offset + 4), Vector2(200, 16))
		_root.add_child(slider)
	else:
		var btn := Button.new()
		btn.text = "창"
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", FONT_SIZE)
		btn.add_theme_color_override("font_color", COLOR_LABEL)
		_place(btn, Vector2(-PANEL_SIZE.x * 0.5 + 180, y_offset), Vector2(80, 24))
		_root.add_child(btn)


func _add_close_hint() -> void:
	var hint := Label.new()
	hint.text = "ESC : 닫기"
	hint.add_theme_color_override("font_color", COLOR_HINT)
	hint.add_theme_font_size_override("font_size", 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(hint, Vector2(-PANEL_SIZE.x * 0.5, PANEL_SIZE.y * 0.5 - 24), Vector2(PANEL_SIZE.x, 16))
	_root.add_child(hint)


func _center(rect: Control, size: Vector2) -> void:
	rect.anchor_left = 0.5
	rect.anchor_right = 0.5
	rect.anchor_top = 0.5
	rect.anchor_bottom = 0.5
	rect.offset_left = -size.x * 0.5
	rect.offset_right = size.x * 0.5
	rect.offset_top = -size.y * 0.5
	rect.offset_bottom = size.y * 0.5


func _place(ctrl: Control, pos: Vector2, size: Vector2) -> void:
	ctrl.anchor_left = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.offset_left = pos.x
	ctrl.offset_top = pos.y
	ctrl.offset_right = pos.x + size.x
	ctrl.offset_bottom = pos.y + size.y

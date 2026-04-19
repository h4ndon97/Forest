extends Node

## 타이틀 확인 다이얼로그.
## "기존 세이브 덮어쓰기?" 류의 2지 선택 (예/아니오) 모달.

signal confirmed
signal cancelled

const COLOR_BG := Color(0.10, 0.08, 0.06, 0.92)
const COLOR_BORDER := Color("F2CC66")
const COLOR_TEXT := Color("F0E8D8")
const COLOR_WARN := Color("C84A4A")
const COLOR_BTN_ACTIVE := Color("F0E8D8")
const COLOR_BTN_INACTIVE := Color("8A8070")
const DIALOG_SIZE := Vector2(360, 160)
const FONT_SIZE: int = 14

var _root: Control
var _dim_rect: ColorRect
var _panel_bg: ColorRect
var _panel_border: ColorRect
var _message_label: Label
var _yes_button: Button
var _no_button: Button
var _selected_yes: bool = false
var _is_open: bool = false


func setup(parent_layer: CanvasLayer) -> void:
	_root = Control.new()
	_root.name = "ConfirmRoot"
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


func show_dialog(message: String) -> void:
	_message_label.text = message
	_root.visible = true
	_is_open = true
	_selected_yes = false
	_update_button_selection()


func hide_dialog() -> void:
	_root.visible = false
	_is_open = false


func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_selected_yes = true
		_update_button_selection()
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_selected_yes = false
		_update_button_selection()
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		_activate()
	elif Input.is_action_just_pressed("ui_cancel"):
		hide_dialog()
		cancelled.emit()


func _build_panel() -> void:
	_panel_border = ColorRect.new()
	_panel_border.color = COLOR_BORDER
	_panel_border.anchor_left = 0.5
	_panel_border.anchor_right = 0.5
	_panel_border.anchor_top = 0.5
	_panel_border.anchor_bottom = 0.5
	_panel_border.offset_left = -DIALOG_SIZE.x * 0.5 - 2
	_panel_border.offset_right = DIALOG_SIZE.x * 0.5 + 2
	_panel_border.offset_top = -DIALOG_SIZE.y * 0.5 - 2
	_panel_border.offset_bottom = DIALOG_SIZE.y * 0.5 + 2
	_panel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel_border)
	_panel_bg = ColorRect.new()
	_panel_bg.color = COLOR_BG
	_panel_bg.anchor_left = 0.5
	_panel_bg.anchor_right = 0.5
	_panel_bg.anchor_top = 0.5
	_panel_bg.anchor_bottom = 0.5
	_panel_bg.offset_left = -DIALOG_SIZE.x * 0.5
	_panel_bg.offset_right = DIALOG_SIZE.x * 0.5
	_panel_bg.offset_top = -DIALOG_SIZE.y * 0.5
	_panel_bg.offset_bottom = DIALOG_SIZE.y * 0.5
	_panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel_bg)
	_message_label = Label.new()
	_message_label.add_theme_color_override("font_color", COLOR_WARN)
	_message_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.anchor_left = 0.5
	_message_label.anchor_right = 0.5
	_message_label.anchor_top = 0.5
	_message_label.anchor_bottom = 0.5
	_message_label.offset_left = -DIALOG_SIZE.x * 0.5 + 16
	_message_label.offset_right = DIALOG_SIZE.x * 0.5 - 16
	_message_label.offset_top = -DIALOG_SIZE.y * 0.5 + 24
	_message_label.offset_bottom = 12
	_root.add_child(_message_label)
	_yes_button = _make_button("예")
	_no_button = _make_button("아니오")
	_yes_button.offset_left = -DIALOG_SIZE.x * 0.5 + 40
	_yes_button.offset_right = -20
	_no_button.offset_left = 20
	_no_button.offset_right = DIALOG_SIZE.x * 0.5 - 40
	_yes_button.pressed.connect(
		func():
			_selected_yes = true
			_activate()
	)
	_no_button.pressed.connect(
		func():
			_selected_yes = false
			_activate()
	)


func _make_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.flat = true
	btn.add_theme_font_size_override("font_size", FONT_SIZE)
	btn.focus_mode = Control.FOCUS_NONE
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.anchor_top = 0.5
	btn.anchor_bottom = 0.5
	btn.offset_top = DIALOG_SIZE.y * 0.5 - 44
	btn.offset_bottom = DIALOG_SIZE.y * 0.5 - 16
	_root.add_child(btn)
	return btn


func _update_button_selection() -> void:
	var yes_color: Color = COLOR_BTN_ACTIVE if _selected_yes else COLOR_BTN_INACTIVE
	var no_color: Color = COLOR_BTN_INACTIVE if _selected_yes else COLOR_BTN_ACTIVE
	_yes_button.add_theme_color_override("font_color", yes_color)
	_no_button.add_theme_color_override("font_color", no_color)


func _activate() -> void:
	hide_dialog()
	if _selected_yes:
		confirmed.emit()
	else:
		cancelled.emit()

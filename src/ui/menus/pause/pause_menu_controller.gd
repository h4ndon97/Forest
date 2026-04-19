extends Node

## 일시정지 메뉴 네비게이션 컨트롤러.
## 3-메뉴(이어하기/설정/타이틀로) 버튼 표시, 키/마우스 입력 처리.
## 선택 시 해당 시그널 발행 (past-tense).

signal resume_selected
signal settings_selected
signal return_title_selected

const SelectionRectScript = preload("res://src/ui/common/menu_selection_rect.gd")
const ITEMS := ["이어하기", "설정", "타이틀로"]
const COLOR_ACTIVE := Color("F0E8D8")
const COLOR_INACTIVE := Color("8A8070")
const COLOR_HINT := Color("6A5A40")
const FONT_SIZE: int = 18
const HINT_FONT_SIZE: int = 10
const ITEM_HEIGHT: float = 32.0
const MENU_WIDTH: float = 200.0

var _root: Control
var _vbox: VBoxContainer
var _selection_rect: MenuSelectionRect
var _return_hint_label: Label
var _buttons: Array[Button] = []
var _selected_index: int = 0
var _input_active: bool = true


func setup(parent_layer: CanvasLayer) -> void:
	_root = Control.new()
	_root.name = "PauseMenuRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_layer.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_selection_rect()
	_build_menu_list()
	_build_return_hint()


func set_input_active(active: bool) -> void:
	_input_active = active


func set_selected_index(index: int) -> void:
	if _buttons.is_empty():
		return
	_selected_index = clamp(index, 0, _buttons.size() - 1)
	_update_selection()


func _process(_delta: float) -> void:
	if not _input_active:
		return
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_navigate(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_navigate(1)
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		_activate()


func _build_selection_rect() -> void:
	_selection_rect = SelectionRectScript.new() as MenuSelectionRect
	_selection_rect.name = "SelectionRect"
	_selection_rect.custom_minimum_size = Vector2(MENU_WIDTH, ITEM_HEIGHT - 4)
	_root.add_child(_selection_rect)


func _build_menu_list() -> void:
	_vbox = VBoxContainer.new()
	_vbox.name = "MenuList"
	_vbox.anchor_left = 0.5
	_vbox.anchor_right = 0.5
	_vbox.anchor_top = 0.5
	_vbox.anchor_bottom = 0.5
	_vbox.offset_left = -MENU_WIDTH * 0.5
	_vbox.offset_right = MENU_WIDTH * 0.5
	_vbox.offset_top = -ITEM_HEIGHT * ITEMS.size() * 0.5
	_vbox.offset_bottom = ITEM_HEIGHT * ITEMS.size() * 0.5
	_vbox.add_theme_constant_override("separation", 4)
	_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_child(_vbox)
	for i in ITEMS.size():
		var btn := Button.new()
		btn.text = ITEMS[i]
		btn.flat = true
		btn.custom_minimum_size = Vector2(MENU_WIDTH, ITEM_HEIGHT - 4)
		btn.add_theme_font_size_override("font_size", FONT_SIZE)
		btn.add_theme_color_override("font_color", COLOR_INACTIVE)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_button_pressed.bind(i))
		btn.mouse_entered.connect(_on_button_hovered.bind(i))
		_buttons.append(btn)
		_vbox.add_child(btn)
	_update_selection.call_deferred()


func _build_return_hint() -> void:
	_return_hint_label = Label.new()
	_return_hint_label.name = "ReturnHint"
	_return_hint_label.text = "※ 마지막 거점에서 이어집니다"
	_return_hint_label.add_theme_color_override("font_color", COLOR_HINT)
	_return_hint_label.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	_return_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_return_hint_label.anchor_left = 0.5
	_return_hint_label.anchor_right = 0.5
	_return_hint_label.anchor_top = 0.5
	_return_hint_label.anchor_bottom = 0.5
	_return_hint_label.offset_left = -MENU_WIDTH * 0.5
	_return_hint_label.offset_right = MENU_WIDTH * 0.5
	_return_hint_label.offset_top = ITEM_HEIGHT * ITEMS.size() * 0.5 + 10
	_return_hint_label.offset_bottom = ITEM_HEIGHT * ITEMS.size() * 0.5 + 26
	_root.add_child(_return_hint_label)


func _navigate(dir: int) -> void:
	_selected_index = wrapi(_selected_index + dir, 0, _buttons.size())
	_update_selection()


func _activate() -> void:
	_emit_by_index(_selected_index)


func _on_button_pressed(index: int) -> void:
	if not _input_active:
		return
	_selected_index = index
	_update_selection()
	_emit_by_index(index)


func _on_button_hovered(index: int) -> void:
	if not _input_active:
		return
	_selected_index = index
	_update_selection()


func _emit_by_index(index: int) -> void:
	match index:
		0:
			resume_selected.emit()
		1:
			settings_selected.emit()
		2:
			return_title_selected.emit()


func _update_selection() -> void:
	for i in _buttons.size():
		var btn: Button = _buttons[i]
		if i == _selected_index:
			btn.add_theme_color_override("font_color", COLOR_ACTIVE)
		else:
			btn.add_theme_color_override("font_color", COLOR_INACTIVE)
	if _buttons.is_empty():
		return
	if _selection_rect:
		_selection_rect.set_target(_buttons[_selected_index])

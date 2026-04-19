extends Node

## 타이틀 메뉴 네비게이션 컨트롤러.
## 버튼 4개(새 게임/이어하기/설정/종료) 표시, 키/마우스 입력 처리.
## 선택 시 해당 시그널 발행 (past-tense).

signal new_game_selected
signal continue_selected
signal settings_selected
signal quit_selected

const ITEMS := ["새 게임", "이어하기", "설정", "종료"]
const COLOR_ACTIVE := Color("F0E8D8")
const COLOR_INACTIVE := Color("8A8070")
const COLOR_DISABLED := Color("5A4A30")
const COLOR_SELECTION_BG := Color("F2CC66", 0.3)
const FONT_SIZE: int = 18
const ITEM_HEIGHT: float = 32.0
const MENU_WIDTH: float = 240.0
const BREATH_PERIOD: float = 1.0
const BREATH_AMPLITUDE: float = 0.10

var _root: Control
var _vbox: VBoxContainer
var _hint_label: Label
var _version_label: Label
var _selection_rect: ColorRect
var _buttons: Array[Button] = []
var _selected_index: int = 0
var _continue_enabled: bool = false
var _input_active: bool = true
var _time: float = 0.0


func setup(parent_layer: CanvasLayer) -> void:
	_root = Control.new()
	_root.name = "MenuRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_layer.add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_selection_rect()
	_build_menu_list()
	_build_hint_label()
	_build_version_label()


func set_continue_enabled(enabled: bool) -> void:
	_continue_enabled = enabled
	_refresh_buttons()
	if not enabled and _selected_index == 1:
		_selected_index = 0
		_update_selection()


func set_input_active(active: bool) -> void:
	_input_active = active


func _process(delta: float) -> void:
	_time += delta
	_update_selection_pulse()
	if not _input_active:
		return
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_navigate(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_navigate(1)
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		_activate()


func _build_selection_rect() -> void:
	_selection_rect = ColorRect.new()
	_selection_rect.name = "SelectionRect"
	_selection_rect.color = COLOR_SELECTION_BG
	_selection_rect.custom_minimum_size = Vector2(MENU_WIDTH, ITEM_HEIGHT - 4)
	_selection_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_vbox.offset_top = 0.0
	_vbox.offset_bottom = ITEM_HEIGHT * ITEMS.size()
	_vbox.add_theme_constant_override("separation", 4)
	_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_child(_vbox)
	for i in ITEMS.size():
		var btn := Button.new()
		btn.text = ITEMS[i]
		btn.flat = true
		btn.custom_minimum_size = Vector2(MENU_WIDTH, ITEM_HEIGHT - 4)
		btn.add_theme_font_size_override("font_size", FONT_SIZE)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_button_pressed.bind(i))
		btn.mouse_entered.connect(_on_button_hovered.bind(i))
		_buttons.append(btn)
		_vbox.add_child(btn)
	_refresh_buttons()
	_update_selection.call_deferred()


func _build_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.text = "↑↓/WS : 이동   Enter/J : 선택"
	_hint_label.add_theme_color_override("font_color", COLOR_INACTIVE)
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.anchor_left = 0.0
	_hint_label.anchor_right = 1.0
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_bottom = 1.0
	_hint_label.offset_top = -28.0
	_hint_label.offset_bottom = -12.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hint_label)


func _build_version_label() -> void:
	_version_label = Label.new()
	_version_label.text = (
		"v" + str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	)
	_version_label.add_theme_color_override("font_color", COLOR_INACTIVE)
	_version_label.add_theme_font_size_override("font_size", 10)
	_version_label.anchor_left = 1.0
	_version_label.anchor_right = 1.0
	_version_label.anchor_top = 1.0
	_version_label.anchor_bottom = 1.0
	_version_label.offset_left = -80.0
	_version_label.offset_top = -20.0
	_version_label.offset_right = -8.0
	_version_label.offset_bottom = -4.0
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_version_label)


func _refresh_buttons() -> void:
	for i in _buttons.size():
		var btn: Button = _buttons[i]
		var is_continue: bool = i == 1
		if is_continue and not _continue_enabled:
			btn.disabled = true
			btn.add_theme_color_override("font_color", COLOR_DISABLED)
		else:
			btn.disabled = false
			btn.add_theme_color_override("font_color", COLOR_INACTIVE)


func _navigate(dir: int) -> void:
	var next: int = _selected_index
	for _i in _buttons.size():
		next = wrapi(next + dir, 0, _buttons.size())
		if next == 1 and not _continue_enabled:
			continue
		break
	_selected_index = next
	_update_selection()


func _activate() -> void:
	if _selected_index == 1 and not _continue_enabled:
		return
	_emit_by_index(_selected_index)


func _on_button_pressed(index: int) -> void:
	if not _input_active:
		return
	if index == 1 and not _continue_enabled:
		return
	_selected_index = index
	_update_selection()
	_emit_by_index(index)


func _on_button_hovered(index: int) -> void:
	if not _input_active:
		return
	if index == 1 and not _continue_enabled:
		return
	_selected_index = index
	_update_selection()


func _emit_by_index(index: int) -> void:
	match index:
		0:
			new_game_selected.emit()
		1:
			continue_selected.emit()
		2:
			settings_selected.emit()
		3:
			quit_selected.emit()


func _update_selection() -> void:
	for i in _buttons.size():
		var btn: Button = _buttons[i]
		if btn.disabled:
			continue
		if i == _selected_index:
			btn.add_theme_color_override("font_color", COLOR_ACTIVE)
		else:
			btn.add_theme_color_override("font_color", COLOR_INACTIVE)
	if _buttons.is_empty():
		return
	var target: Button = _buttons[_selected_index]
	if target and _selection_rect:
		var pos: Vector2 = target.global_position
		_selection_rect.global_position = pos
		_selection_rect.size = Vector2(target.size.x, target.size.y)


func _update_selection_pulse() -> void:
	if not _selection_rect:
		return
	var breath: float = 0.5 + 0.5 * sin(_time * TAU / BREATH_PERIOD)
	var alpha: float = lerpf(COLOR_SELECTION_BG.a - BREATH_AMPLITUDE, COLOR_SELECTION_BG.a, breath)
	_selection_rect.color.a = alpha

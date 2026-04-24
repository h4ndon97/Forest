extends CanvasLayer

## 인벤토리 메뉴 Autoload (CanvasLayer).
## Tab으로 토글, ESC로 닫기. Q/E로 [장비]/[스킬] 탭 전환.
## 활성 탭에 ↑↓/J/F 입력을 위임.

const TabControllerScript = preload("res://src/ui/menus/inventory/inventory_tab_controller.gd")
const EquipmentTabScript = preload("res://src/ui/menus/inventory/equipment_tab.gd")
const SkillTabScript = preload("res://src/ui/menus/inventory/skill_tab.gd")
const TAB_EQUIPMENT: int = 0
const TAB_SKILL: int = 1

var _is_open: bool = false
var _is_at_checkpoint: bool = false
var _bg: ColorRect
var _title_label: Label
var _hint_label: Label
var _tabs: InventoryTabController
var _equipment_tab: EquipmentTab
var _skill_tab: SkillTab


func _ready() -> void:
	layer = 80
	visible = false
	_build_ui()
	EventBus.checkpoint_entered.connect(_on_checkpoint_entered)
	EventBus.checkpoint_exited.connect(_on_checkpoint_exited)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		if _is_open:
			_close()
		else:
			_open()
		return

	if not _is_open:
		return

	if Input.is_action_just_pressed("ui_cancel"):
		_close()
		return

	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_route_navigate(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_route_navigate(1)
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_route_horizontal(-1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_route_horizontal(1)
	elif Input.is_action_just_pressed("ui_accept"):
		_route_equip()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		match key_event.physical_keycode:
			KEY_Q:
				_tabs.cycle(-1)
			KEY_E:
				_tabs.cycle(1)
			KEY_F:
				_route_equip()
			KEY_J:
				_route_j_by_tab()


func is_open() -> bool:
	return _is_open


# --- 입력 라우팅 ---


func _route_navigate(direction: int) -> void:
	match _tabs.get_active_index():
		TAB_EQUIPMENT:
			_equipment_tab.navigate(direction)
		TAB_SKILL:
			_skill_tab.navigate(direction)


func _route_horizontal(direction: int) -> void:
	if _tabs.get_active_index() == TAB_SKILL:
		_skill_tab.navigate_horizontal(direction)


## Enter / F = 양 탭 공통 "장착".
func _route_equip() -> void:
	match _tabs.get_active_index():
		TAB_EQUIPMENT:
			_equipment_tab.activate()
		TAB_SKILL:
			_skill_tab.activate_equip()


## J = 탭별 분기. 장비=장착(원래 UX), 스킬=해제.
func _route_j_by_tab() -> void:
	match _tabs.get_active_index():
		TAB_EQUIPMENT:
			_equipment_tab.activate()
		TAB_SKILL:
			_skill_tab.activate_unequip()


# --- 열기/닫기 ---


func _open() -> void:
	_is_open = true
	visible = true
	_equipment_tab.set_at_checkpoint(_is_at_checkpoint)
	_skill_tab.set_at_checkpoint(_is_at_checkpoint)
	_equipment_tab.refresh()
	_skill_tab.refresh()
	_apply_active_tab()
	EffectsSystem.request_dissolve_flash()
	EventBus.inventory_opened.emit()


func _close() -> void:
	_is_open = false
	visible = false
	EffectsSystem.request_dissolve_flash()
	EventBus.inventory_closed.emit()


# --- UI 구성 ---


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = Color(0.0, 0.0, 0.0, 0.75)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var header := Control.new()
	header.name = "Header"
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "인벤토리"
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_top = 28.0
	_title_label.offset_bottom = 52.0
	header.add_child(_title_label)

	_tabs = TabControllerScript.new() as InventoryTabController
	_tabs.name = "TabController"
	add_child(_tabs)
	_tabs.setup(header)
	_tabs.tab_changed.connect(_on_tab_changed)

	_equipment_tab = EquipmentTabScript.new() as EquipmentTab
	_equipment_tab.name = "EquipmentTab"
	add_child(_equipment_tab)
	_equipment_tab.setup()

	_skill_tab = SkillTabScript.new() as SkillTab
	_skill_tab.name = "SkillTab"
	add_child(_skill_tab)
	_skill_tab.setup()

	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.text = ""
	_hint_label.add_theme_font_size_override("font_size", 8)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -28.0
	_hint_label.offset_bottom = -10.0
	header.add_child(_hint_label)


# --- 시그널 ---


func _on_tab_changed(_index: int) -> void:
	_apply_active_tab()


func _on_checkpoint_entered(_id: String) -> void:
	_is_at_checkpoint = true
	_equipment_tab.set_at_checkpoint(true)
	_skill_tab.set_at_checkpoint(true)
	if _is_open:
		_apply_active_tab()


func _on_checkpoint_exited(_id: String) -> void:
	_is_at_checkpoint = false
	_equipment_tab.set_at_checkpoint(false)
	_skill_tab.set_at_checkpoint(false)
	if _is_open:
		_apply_active_tab()


func _apply_active_tab() -> void:
	var active: int = _tabs.get_active_index()
	_equipment_tab.visible = active == TAB_EQUIPMENT
	_skill_tab.visible = active == TAB_SKILL
	match active:
		TAB_EQUIPMENT:
			_hint_label.text = _equipment_tab.get_hint()
		TAB_SKILL:
			_hint_label.text = _skill_tab.get_hint()

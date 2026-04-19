class_name SkillTab
extends Control

## 인벤토리 [스킬] 탭. 슬롯(좌, 4칸) + 해금 스킬 목록(우) + 정보(하).
## 거점에서만 장착/해제 가능. F=장착, J=해제. 컬럼 ←→, 항목 ↑↓.

const NavigatorScript = preload("res://src/ui/menus/inventory/skill_tab_navigator.gd")
const SLOT_COUNT: int = 4
const COLOR_EMPTY := Color(0.5, 0.5, 0.5)
const COLOR_LIGHT := Color(0.95, 0.85, 0.45)
const COLOR_SHADOW := Color(0.55, 0.55, 0.85)
const COLOR_HYBRID := Color(0.85, 0.55, 0.85)
const COLOR_SELECT := Color(1.0, 1.0, 1.0)
const COLOR_DIM := Color(0.7, 0.7, 0.7)
const FONT_TITLE := 9
const FONT_ITEM := 8
const FONT_SLOT_NUM := 7

var _slot_labels: Array[Label] = []
var _list_container: VBoxContainer
var _list_labels: Array[Label] = []
var _info_label: Label
var _list_skill_ids: Array[String] = []
var _navigator: SkillTabNavigator
var _is_at_checkpoint: bool = false


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_navigator = NavigatorScript.new() as SkillTabNavigator
	_build_ui()
	EventBus.skill_equipped.connect(_on_slots_changed.unbind(2))
	EventBus.skill_unequipped.connect(_on_slots_changed.unbind(1))
	EventBus.skill_unlocked.connect(_on_slots_changed.unbind(1))


func set_at_checkpoint(value: bool) -> void:
	_is_at_checkpoint = value


func refresh() -> void:
	_refresh_slots()
	_refresh_list()
	_update_selection()


func navigate(direction: int) -> void:
	_navigator.navigate_vertical(direction)
	_update_selection()


func navigate_horizontal(direction: int) -> void:
	_navigator.navigate_horizontal(direction)
	_update_selection()


## F=장착(목록→슬롯). 거점에서만.
func activate_equip() -> void:
	if not _is_at_checkpoint:
		return
	if not _navigator.is_on_list():
		return
	if _list_skill_ids.is_empty():
		return
	var skill_id: String = _list_skill_ids[_navigator.get_list_index()]
	var slot: int = _find_target_slot()
	SkillSystem.equip_skill(slot, skill_id)


## J=해제(슬롯). 거점에서만.
func activate_unequip() -> void:
	if not _is_at_checkpoint:
		return
	if not _navigator.is_on_slots():
		return
	SkillSystem.unequip_skill(_navigator.get_slot_index())


func get_hint() -> String:
	if _is_at_checkpoint:
		return "[Q/E] 탭  [↑↓] 선택  [←→] 컬럼  [F/Enter] 장착  [J] 해제  [Tab/ESC] 닫기"
	return "[Q/E] 탭  [↑↓] 선택  [←→] 컬럼  (변경은 거점에서만)  [Tab/ESC] 닫기"


# --- 내부 ---


func _on_slots_changed() -> void:
	if visible:
		refresh()


func _find_target_slot() -> int:
	for i in range(SLOT_COUNT):
		if SkillSystem.get_equipped_skill(i) == null:
			return i
	return _navigator.get_slot_index()


func _refresh_slots() -> void:
	for i in range(SLOT_COUNT):
		var skill: SkillData = SkillSystem.get_equipped_skill(i)
		if skill == null:
			_slot_labels[i].text = "[%d] [빈 슬롯]" % (i + 1)
			_slot_labels[i].add_theme_color_override("font_color", COLOR_EMPTY)
		else:
			_slot_labels[i].text = "[%d] %s" % [i + 1, skill.display_name]
			_slot_labels[i].add_theme_color_override("font_color", _get_path_color(skill.path))


func _refresh_list() -> void:
	_list_skill_ids.clear()
	for label: Label in _list_labels:
		label.queue_free()
	_list_labels.clear()

	var ids: Array = SkillSystem.get_all_skill_ids()
	for sid in ids:
		var sid_str: String = sid
		if not SkillSystem.is_skill_unlocked(sid_str):
			continue
		_list_skill_ids.append(sid_str)

	for i in range(_list_skill_ids.size()):
		var skill: SkillData = SkillSystem.get_skill_data(_list_skill_ids[i])
		if skill == null:
			continue
		var label := Label.new()
		label.text = "  %s" % skill.display_name
		label.add_theme_font_size_override("font_size", FONT_ITEM)
		label.add_theme_color_override("font_color", _get_path_color(skill.path))
		_list_container.add_child(label)
		_list_labels.append(label)

	_navigator.set_list_size(_list_skill_ids.size())


func _update_selection() -> void:
	var slot_focus: int = _navigator.get_slot_index() if _navigator.is_on_slots() else -1
	for i in range(SLOT_COUNT):
		var lbl: Label = _slot_labels[i]
		var prefix: String = "> " if i == slot_focus else "  "
		var skill: SkillData = SkillSystem.get_equipped_skill(i)
		if skill == null:
			lbl.text = "%s[%d] [빈 슬롯]" % [prefix, i + 1]
		else:
			lbl.text = "%s[%d] %s" % [prefix, i + 1, skill.display_name]

	var list_focus: int = _navigator.get_list_index() if _navigator.is_on_list() else -1
	for i in range(_list_labels.size()):
		var skill: SkillData = SkillSystem.get_skill_data(_list_skill_ids[i])
		if skill == null:
			continue
		var prefix: String = "> " if i == list_focus else "  "
		_list_labels[i].text = "%s%s" % [prefix, skill.display_name]

	_update_info()


func _update_info() -> void:
	var skill: SkillData = _get_focused_skill()
	if skill == null:
		_info_label.text = "(스킬 없음)"
		return
	var attr_label: String = _format_path(skill.path)
	var type_label: String = "액티브" if skill.skill_type == "active" else "패시브"
	_info_label.text = (
		"%s  [%s · %s · T%d]\n%s\n시간 %.0f · 쿨다운 %.1fs · 데미지 %.0f"
		% [
			skill.display_name,
			attr_label,
			type_label,
			skill.tier,
			skill.description,
			skill.time_cost,
			skill.cooldown,
			skill.damage,
		]
	)


func _get_focused_skill() -> SkillData:
	if _navigator.is_on_slots():
		return SkillSystem.get_equipped_skill(_navigator.get_slot_index())
	if _list_skill_ids.is_empty():
		return null
	return SkillSystem.get_skill_data(_list_skill_ids[_navigator.get_list_index()])


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.name = "SkillLayout"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left = -180
	vbox.offset_right = 180
	vbox.offset_top = -100
	vbox.offset_bottom = 100
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var h_box := HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 16)
	vbox.add_child(h_box)

	_build_slot_panel(h_box)
	_build_list_panel(h_box)

	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.text = ""
	_info_label.add_theme_font_size_override("font_size", FONT_ITEM)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_info_label)


func _build_slot_panel(parent: Container) -> void:
	var slot_vbox := VBoxContainer.new()
	slot_vbox.name = "SlotPanel"
	slot_vbox.custom_minimum_size = Vector2(160, 0)
	parent.add_child(slot_vbox)
	var title := Label.new()
	title.text = "장착 슬롯"
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	slot_vbox.add_child(title)
	for i in range(SLOT_COUNT):
		var lbl := Label.new()
		lbl.text = "[%d] [빈 슬롯]" % (i + 1)
		lbl.add_theme_font_size_override("font_size", FONT_ITEM)
		slot_vbox.add_child(lbl)
		_slot_labels.append(lbl)


func _build_list_panel(parent: Container) -> void:
	_list_container = VBoxContainer.new()
	_list_container.name = "SkillList"
	_list_container.custom_minimum_size = Vector2(160, 0)
	parent.add_child(_list_container)
	var title := Label.new()
	title.text = "해금 스킬"
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	_list_container.add_child(title)


func _get_path_color(path: String) -> Color:
	match path:
		"light":
			return COLOR_LIGHT
		"shadow":
			return COLOR_SHADOW
		"hybrid":
			return COLOR_HYBRID
	return COLOR_DIM


func _format_path(path: String) -> String:
	match path:
		"light":
			return "빛"
		"shadow":
			return "그림자"
		"hybrid":
			return "하이브리드"
	return path

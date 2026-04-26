class_name EquipmentTab
extends Control

## 인벤토리 [장비] 탭. 장비 슬롯(좌) + 소지 아이템(우) + 정보(하).
## 거점에서만 장착 가능. 거점 외부에선 navigate만 허용.

const ItemDataClass = preload("res://data/items/item_data.gd")
const COLOR_COMMON := Color(0.7, 0.7, 0.7, 0.9)
const COLOR_RARE := Color(0.3, 0.5, 0.9, 0.9)
const COLOR_UNIQUE := Color(0.9, 0.7, 0.2, 0.9)
## REC-UX-003: flavor_text 라벨 색조 — 메카닉 설명과 시각 분리.
const COLOR_FLAVOR := Color(0.55, 0.45, 0.7, 0.85)
const SLOT_NAMES := ["무기", "방어구", "장신구1", "장신구2", "장신구3"]
const FONT_TITLE := 9
const FONT_ITEM := 8

var _equip_labels: Array[Label] = []
var _item_labels: Array[Label] = []
var _bag_container: VBoxContainer
var _info_label: Label
var _flavor_label: Label
var _item_ids: Array[String] = []
var _selected_index: int = 0
var _is_at_checkpoint: bool = false


func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	EventBus.equipment_changed.connect(_on_equipment_changed)


## 거점 진입/이탈 상태 갱신.
func set_at_checkpoint(value: bool) -> void:
	_is_at_checkpoint = value


## 슬롯/소지품/선택 표시 전체 갱신.
func refresh() -> void:
	_refresh_equipment()
	_refresh_bag()
	_update_selection()


func navigate(direction: int) -> void:
	if _item_ids.is_empty():
		return
	_selected_index = wrapi(_selected_index + direction, 0, _item_ids.size())
	_update_selection()


func activate() -> void:
	if _item_ids.is_empty():
		return
	if not _is_at_checkpoint:
		return
	var item_id: String = _item_ids[_selected_index]
	InventorySystem.auto_equip(item_id)
	refresh()


## 하단 hint 라벨에 표시할 텍스트.
func get_hint() -> String:
	if _is_at_checkpoint:
		return "[Q/E] 탭  [↑↓] 선택  [J/F/Enter] 장착  [Tab/ESC] 닫기"
	return "[Q/E] 탭  [↑↓] 선택  (장착은 거점에서만)  [Tab/ESC] 닫기"


# --- 내부 ---


func _on_equipment_changed(_slot_type: int, _item_id: String) -> void:
	if visible:
		refresh()


func _refresh_equipment() -> void:
	for i in range(SLOT_NAMES.size()):
		var item_id: String = InventorySystem.get_equipped(i)
		if item_id == "":
			_equip_labels[i].text = "%s: [빈 슬롯]" % SLOT_NAMES[i]
			_equip_labels[i].add_theme_color_override("font_color", Color.GRAY)
		else:
			var data: Resource = InventorySystem.get_item_data(item_id)
			if data:
				_equip_labels[i].text = "%s: %s" % [SLOT_NAMES[i], data.display_name]
				_equip_labels[i].add_theme_color_override(
					"font_color", _get_rarity_color(data.rarity)
				)


func _refresh_bag() -> void:
	_item_ids.clear()
	for label: Label in _item_labels:
		label.queue_free()
	_item_labels.clear()

	var bag: Array[String] = InventorySystem.get_bag()
	for item_id: String in bag:
		_item_ids.append(item_id)

	for i in range(_item_ids.size()):
		var data: Resource = InventorySystem.get_item_data(_item_ids[i])
		if data == null:
			continue
		var label := Label.new()
		label.text = "  %s" % data.display_name
		label.add_theme_font_size_override("font_size", FONT_ITEM)
		label.add_theme_color_override("font_color", _get_rarity_color(data.rarity))
		_bag_container.add_child(label)
		_item_labels.append(label)

	if _selected_index >= _item_ids.size():
		_selected_index = maxi(_item_ids.size() - 1, 0)


func _update_selection() -> void:
	for i in range(_item_labels.size()):
		var data: Resource = InventorySystem.get_item_data(_item_ids[i])
		if data == null:
			continue
		if i == _selected_index:
			_item_labels[i].text = "> %s" % data.display_name
		else:
			_item_labels[i].text = "  %s" % data.display_name

	if _item_ids.is_empty():
		_info_label.text = "소지 아이템 없음"
		_flavor_label.text = ""
		_flavor_label.visible = false
		return
	var sel_data: Resource = InventorySystem.get_item_data(_item_ids[_selected_index])
	if sel_data:
		_info_label.text = "%s\n%s" % [sel_data.display_name, sel_data.description]
		# REC-UX-003: flavor_text 있으면 별도 영역에 시 톤으로 표시.
		var flavor: String = sel_data.flavor_text if "flavor_text" in sel_data else ""
		if flavor != "":
			_flavor_label.text = "  ※ %s" % flavor
			_flavor_label.visible = true
		else:
			_flavor_label.text = ""
			_flavor_label.visible = false


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.name = "EquipmentLayout"
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

	_build_equip_panel(h_box)
	_build_bag_panel(h_box)

	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.text = ""
	_info_label.add_theme_font_size_override("font_size", FONT_ITEM)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_info_label)

	# REC-UX-003: flavor_text 표시 영역. 회색 보라 색조로 메카닉 설명과 시각 분리.
	_flavor_label = Label.new()
	_flavor_label.name = "FlavorLabel"
	_flavor_label.text = ""
	_flavor_label.add_theme_font_size_override("font_size", FONT_ITEM)
	_flavor_label.add_theme_color_override("font_color", COLOR_FLAVOR)
	_flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_flavor_label.visible = false
	vbox.add_child(_flavor_label)


func _build_equip_panel(parent: Container) -> void:
	var equip_vbox := VBoxContainer.new()
	equip_vbox.name = "EquipPanel"
	equip_vbox.custom_minimum_size = Vector2(160, 0)
	parent.add_child(equip_vbox)
	var equip_title := Label.new()
	equip_title.text = "장비 슬롯"
	equip_title.add_theme_font_size_override("font_size", FONT_TITLE)
	equip_vbox.add_child(equip_title)
	for i in range(SLOT_NAMES.size()):
		var lbl := Label.new()
		lbl.text = "%s: [빈 슬롯]" % SLOT_NAMES[i]
		lbl.add_theme_font_size_override("font_size", FONT_ITEM)
		equip_vbox.add_child(lbl)
		_equip_labels.append(lbl)


func _build_bag_panel(parent: Container) -> void:
	_bag_container = VBoxContainer.new()
	_bag_container.name = "BagPanel"
	_bag_container.custom_minimum_size = Vector2(160, 0)
	parent.add_child(_bag_container)
	var bag_title := Label.new()
	bag_title.text = "소지 아이템"
	bag_title.add_theme_font_size_override("font_size", FONT_TITLE)
	_bag_container.add_child(bag_title)


func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		ItemDataClass.ItemRarity.RARE:
			return COLOR_RARE
		ItemDataClass.ItemRarity.UNIQUE:
			return COLOR_UNIQUE
	return COLOR_COMMON

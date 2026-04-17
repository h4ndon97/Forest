extends CanvasLayer

## 인벤토리 메뉴 UI.
## Tab으로 열고, ESC/Tab으로 닫는다.
## 장비 슬롯(좌), 소지 아이템 목록(우), 선택 아이템 정보(하) 표시.

const ItemDataClass = preload("res://data/items/item_data.gd")
const COLOR_COMMON := Color(0.7, 0.7, 0.7, 0.9)
const COLOR_RARE := Color(0.3, 0.5, 0.9, 0.9)
const COLOR_UNIQUE := Color(0.9, 0.7, 0.2, 0.9)

const SLOT_NAMES := ["무기", "방어구", "장신구1", "장신구2", "장신구3"]
const SLOT_SIZE := Vector2(80, 20)

var _is_open: bool = false
var _bg: ColorRect
var _equip_labels: Array[Label] = []
var _item_labels: Array[Label] = []
var _info_label: Label
var _hint_label: Label
var _item_ids: Array[String] = []
var _selected_index: int = 0
var _bag_container: VBoxContainer
var _is_at_checkpoint: bool = false


func _ready() -> void:
	layer = 80
	visible = false
	_build_ui()
	EventBus.checkpoint_entered.connect(func(_id: String): _is_at_checkpoint = true)
	EventBus.checkpoint_exited.connect(func(_id: String): _is_at_checkpoint = false)
	EventBus.equipment_changed.connect(func(_s: int, _id: String): _refresh())


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

	if _item_ids.is_empty():
		return

	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_navigate(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_navigate(1)
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		_equip_selected()


func _open() -> void:
	_is_open = true
	visible = true
	_refresh()
	EventBus.inventory_opened.emit()


func _close() -> void:
	_is_open = false
	visible = false
	EventBus.inventory_closed.emit()


func _navigate(dir: int) -> void:
	if _item_ids.is_empty():
		return
	_selected_index = wrapi(_selected_index + dir, 0, _item_ids.size())
	_update_selection()


func _equip_selected() -> void:
	if _item_ids.is_empty():
		return
	if not _is_at_checkpoint:
		return
	var item_id: String = _item_ids[_selected_index]
	InventorySystem.auto_equip(item_id)
	_refresh()


func _refresh() -> void:
	_refresh_equipment()
	_refresh_bag()
	_update_selection()


func _refresh_equipment() -> void:
	for i in range(5):
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
		label.add_theme_font_size_override("font_size", 8)
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
		return
	var sel_data: Resource = InventorySystem.get_item_data(_item_ids[_selected_index])
	if sel_data:
		_info_label.text = "%s\n%s" % [sel_data.display_name, sel_data.description]

	if _is_at_checkpoint:
		_hint_label.text = "[Tab] 닫기  [J] 장착  [↑↓] 선택"
	else:
		_hint_label.text = "[Tab] 닫기  [↑↓] 선택  (장착은 거점에서만)"


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = Color(0.0, 0.0, 0.0, 0.75)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.set_anchors_preset(Control.PRESET_CENTER)
	main.offset_left = -200
	main.offset_right = 200
	main.offset_top = -120
	main.offset_bottom = 120
	add_child(main)

	var title := Label.new()
	title.text = "인벤토리"
	title.add_theme_font_size_override("font_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_child(title)

	var h_box := HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 16)
	main.add_child(h_box)

	var equip_vbox := VBoxContainer.new()
	equip_vbox.name = "EquipPanel"
	equip_vbox.custom_minimum_size = Vector2(160, 0)
	h_box.add_child(equip_vbox)
	var equip_title := Label.new()
	equip_title.text = "장비 슬롯"
	equip_title.add_theme_font_size_override("font_size", 9)
	equip_vbox.add_child(equip_title)
	for i in range(5):
		var lbl := Label.new()
		lbl.text = "%s: [빈 슬롯]" % SLOT_NAMES[i]
		lbl.add_theme_font_size_override("font_size", 8)
		equip_vbox.add_child(lbl)
		_equip_labels.append(lbl)

	_bag_container = VBoxContainer.new()
	_bag_container.name = "BagPanel"
	_bag_container.custom_minimum_size = Vector2(160, 0)
	h_box.add_child(_bag_container)
	var bag_title := Label.new()
	bag_title.text = "소지 아이템"
	bag_title.add_theme_font_size_override("font_size", 9)
	_bag_container.add_child(bag_title)

	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.text = ""
	_info_label.add_theme_font_size_override("font_size", 8)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	main.add_child(_info_label)

	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.text = "[Tab] 닫기"
	_hint_label.add_theme_font_size_override("font_size", 7)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	main.add_child(_hint_label)


func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		ItemDataClass.ItemRarity.RARE:
			return COLOR_RARE
		ItemDataClass.ItemRarity.UNIQUE:
			return COLOR_UNIQUE
	return COLOR_COMMON

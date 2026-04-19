extends CanvasLayer

## 상점 UI.
## shop_opened 시그널로 열리고, ESC로 닫는다.
## Phase 5까지 화폐 미결정 — 현재 무조건 구매 성공.

const ItemDataClass = preload("res://data/items/item_data.gd")
const COLOR_COMMON := Color(0.7, 0.7, 0.7, 0.9)
const COLOR_RARE := Color(0.3, 0.5, 0.9, 0.9)
const COLOR_UNIQUE := Color(0.9, 0.7, 0.2, 0.9)

var _is_open: bool = false
var _shop_items: Array[String] = []
var _selected_index: int = 0
var _bg: ColorRect
var _item_labels: Array[Label] = []
var _info_label: Label
var _hint_label: Label
var _list_container: VBoxContainer


func _ready() -> void:
	layer = 85
	visible = false
	_build_ui()
	EventBus.shop_opened.connect(_on_shop_opened)


func _process(_delta: float) -> void:
	if not _is_open:
		return

	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("interact"):
		_close()
		return

	if _shop_items.is_empty():
		return

	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		_navigate(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		_navigate(1)
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		_purchase_selected()


func is_open() -> bool:
	return _is_open


func _on_shop_opened(shop_id: String) -> void:
	_shop_items.clear()
	var keepers: Array = get_tree().get_nodes_in_group("shop_keepers")
	for keeper: Node in keepers:
		if keeper.has_method("get_shop_items") and keeper.shop_id == shop_id:
			var items: Array[String] = keeper.get_shop_items()
			_shop_items.assign(items)
			break
	if _shop_items.is_empty():
		_shop_items.assign(
			["sword_shadow", "leather_vest", "ring_of_strength", "hp_potion", "time_crystal"]
		)
	_selected_index = 0
	_is_open = true
	visible = true
	_refresh()


func _close() -> void:
	_is_open = false
	visible = false
	EventBus.shop_closed.emit()


func _navigate(dir: int) -> void:
	_selected_index = wrapi(_selected_index + dir, 0, _shop_items.size())
	_update_selection()


func _purchase_selected() -> void:
	if _shop_items.is_empty():
		return
	var item_id: String = _shop_items[_selected_index]
	var success: bool = InventorySystem.acquire_item(item_id)
	if success:
		EventBus.shop_purchase_completed.emit(item_id)
		_info_label.text = "구매 완료!"
	else:
		_info_label.text = "구매 실패 (소지 불가)"


func _refresh() -> void:
	for label: Label in _item_labels:
		label.queue_free()
	_item_labels.clear()

	for i in range(_shop_items.size()):
		var data: Resource = InventorySystem.get_item_data(_shop_items[i])
		if data == null:
			continue
		var label := Label.new()
		label.text = "  %s  (%d)" % [data.display_name, data.buy_price]
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", _get_rarity_color(data.rarity))
		_list_container.add_child(label)
		_item_labels.append(label)
	_update_selection()


func _update_selection() -> void:
	for i in range(_item_labels.size()):
		var data: Resource = InventorySystem.get_item_data(_shop_items[i])
		if data == null:
			continue
		if i == _selected_index:
			_item_labels[i].text = "> %s  (%d)" % [data.display_name, data.buy_price]
		else:
			_item_labels[i].text = "  %s  (%d)" % [data.display_name, data.buy_price]

	if _shop_items.is_empty():
		_info_label.text = "판매 물품 없음"
		return
	var sel_data: Resource = InventorySystem.get_item_data(_shop_items[_selected_index])
	if sel_data:
		_info_label.text = "%s\n%s" % [sel_data.display_name, sel_data.description]


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.color = Color(0.0, 0.05, 0.0, 0.8)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.set_anchors_preset(Control.PRESET_CENTER)
	main.offset_left = -140
	main.offset_right = 140
	main.offset_top = -100
	main.offset_bottom = 100
	add_child(main)

	var title := Label.new()
	title.text = "상점"
	title.add_theme_font_size_override("font_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_child(title)

	_list_container = VBoxContainer.new()
	_list_container.name = "ItemList"
	main.add_child(_list_container)

	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.text = ""
	_info_label.add_theme_font_size_override("font_size", 8)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	main.add_child(_info_label)

	_hint_label = Label.new()
	_hint_label.text = "[J] 구매  [↑↓] 선택  [ESC] 닫기"
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

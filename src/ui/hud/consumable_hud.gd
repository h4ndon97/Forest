extends CanvasLayer

## 소모품 슬롯 HUD.
## HP 회복(1번), 시간자원 회복(2번) 2슬롯 표시.

const SLOT_COUNT := 2
const BOTTLE_SIZE := Vector2(24, 32)

# 좌하단 각진 병 배치 (ui_design_master.md §A-5, 640×360 기준, 병 top-left)
const BOTTLE_COORDS: Array[Vector2] = [
	Vector2(16, 312),  # HP 병
	Vector2(48, 312),  # Time 병
]

# 플레이어 HUD 빛/그림자 축 (feedback_ui_dual_axis): HP=불씨 금 / Time=달 보라
const COLOR_HP := Color(0.949, 0.8, 0.4, 0.9)          # #F2CC66
const COLOR_TIME := Color(0.545, 0.184, 0.776, 0.9)    # #8B2FC6
const COLOR_EMPTY := Color(0.5, 0.5, 0.5, 0.3)
const COLOR_FLASH := Color(1.0, 1.0, 1.0, 1.0)

const CONSUMABLE_IDS := ["hp_potion", "time_crystal"]
const KEY_LABELS := ["1", "2"]
const SLOT_COLORS := [COLOR_HP, COLOR_TIME]

var _slot_backgrounds: Array[ColorRect] = []
var _count_labels: Array[Label] = []
var _flash_tweens: Array[Tween] = [null, null]


func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.consumable_count_changed.connect(_on_count_changed)
	EventBus.consumable_used.connect(_on_consumable_used)
	_refresh_all.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("consumable_1"):
		InventorySystem.use_consumable(CONSUMABLE_IDS[0])
	elif event.is_action_pressed("consumable_2"):
		InventorySystem.use_consumable(CONSUMABLE_IDS[1])


func _build_ui() -> void:
	var root := Control.new()
	root.name = "BottleRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	for i in range(SLOT_COUNT):
		var bottle := _create_slot(i)
		bottle.position = BOTTLE_COORDS[i]
		root.add_child(bottle)


func _create_slot(index: int) -> Control:
	var panel := Control.new()
	panel.name = "Bottle_%d" % index
	panel.custom_minimum_size = BOTTLE_SIZE

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = SLOT_COLORS[index]
	bg.size = BOTTLE_SIZE
	panel.add_child(bg)
	_slot_backgrounds.append(bg)

	# 키 레이블 '1'/'2': 병 중앙 (Pass 1 placeholder)
	var key_label := Label.new()
	key_label.name = "KeyLabel"
	key_label.text = KEY_LABELS[index]
	key_label.add_theme_font_size_override("font_size", 8)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.size = BOTTLE_SIZE
	panel.add_child(key_label)

	# 수량 숫자: 우측 상단 (spec: x+16, y-4, 8×8)
	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.text = "0"
	count_label.add_theme_font_size_override("font_size", 7)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.position = Vector2(16, -4)
	count_label.size = Vector2(12, 10)
	panel.add_child(count_label)
	_count_labels.append(count_label)

	return panel


func _on_count_changed(item_id: String, current: int, _max_val: int) -> void:
	var idx: int = CONSUMABLE_IDS.find(item_id)
	if idx < 0:
		return
	_count_labels[idx].text = str(current)
	if current <= 0:
		_slot_backgrounds[idx].color = COLOR_EMPTY
	else:
		_slot_backgrounds[idx].color = SLOT_COLORS[idx]


func _on_consumable_used(consumable_type: int, _amount: float) -> void:
	if consumable_type < 0 or consumable_type >= SLOT_COUNT:
		return
	_flash_slot(consumable_type)


func _flash_slot(index: int) -> void:
	var bg: ColorRect = _slot_backgrounds[index]
	var original: Color = SLOT_COLORS[index]
	bg.color = COLOR_FLASH
	if _flash_tweens[index]:
		_flash_tweens[index].kill()
	_flash_tweens[index] = create_tween()
	_flash_tweens[index].tween_property(bg, "color", original, 0.15)


func _refresh_all() -> void:
	for i in range(SLOT_COUNT):
		var count: int = InventorySystem.get_consumable_count(CONSUMABLE_IDS[i])
		_count_labels[i].text = str(count)
		if count <= 0:
			_slot_backgrounds[i].color = COLOR_EMPTY

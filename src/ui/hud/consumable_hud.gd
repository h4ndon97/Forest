extends CanvasLayer

## 소모품 슬롯 HUD.
## HP 회복(1번), 시간자원 회복(2번) 2슬롯 표시.

const SLOT_COUNT := 2
const BOTTLE_SIZE := Vector2(32, 32)

# 좌하단 슬롯 배치 (ui_design_master.md §A-5, 640×360 기준, 슬롯 top-left)
const BOTTLE_COORDS: Array[Vector2] = [
	Vector2(16, 312),  # HP 슬롯
	Vector2(52, 312),  # Time 슬롯 (32 + 4px gap)
]

# 상태 modulate — 사용자 PNG 색 보존 위해 색 tint 제거, 알파만 변동
const COLOR_ACTIVE := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_EMPTY := Color(1.0, 1.0, 1.0, 0.4)
const COLOR_FLASH := Color(1.5, 1.5, 1.5, 1.0)

const CONSUMABLE_IDS := ["hp_potion", "time_crystal"]

# A-4 PNG 드롭인 (파일 없으면 ColorRect fallback)
const HP_POTION_PNG := "res://assets/ui/hud/hud_consumable_hp.png"
const TIME_POTION_PNG := "res://assets/ui/hud/hud_consumable_time.png"
const SLOT_FRAME_PNG := "res://assets/ui/hud/hud_consumable_slot.png"
const PNG_PATHS := [HP_POTION_PNG, TIME_POTION_PNG]

var _slot_backgrounds: Array[Control] = []
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

	# 슬롯 프레임 (PNG 있으면 배경 레이어로 추가, 없으면 생략)
	var slot_frame: TextureRect = _create_slot_frame()
	if slot_frame != null:
		slot_frame.size = BOTTLE_SIZE
		panel.add_child(slot_frame)

	var bg: Control = _create_slot_background(index)
	bg.name = "Background"
	bg.size = BOTTLE_SIZE
	bg.modulate = COLOR_ACTIVE
	panel.add_child(bg)
	_slot_backgrounds.append(bg)

	# 수량 숫자: 우하단 슬롯 프레임 안쪽 (키 인디케이터는 튜토리얼 학습으로 대체)
	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.text = "0"
	count_label.add_theme_font_size_override("font_size", 7)
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	count_label.add_theme_constant_override("outline_size", 3)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.position = Vector2(17, 14)
	count_label.size = Vector2(8, 8)
	panel.add_child(count_label)
	_count_labels.append(count_label)

	return panel


func _create_slot_frame() -> TextureRect:
	# 슬롯 프레임 PNG (옵션). 있으면 모든 슬롯 동일 사용.
	if not ResourceLoader.exists(SLOT_FRAME_PNG):
		return null
	var tex_rect := TextureRect.new()
	tex_rect.name = "SlotFrame"
	tex_rect.texture = load(SLOT_FRAME_PNG) as Texture2D
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex_rect


func _create_slot_background(index: int) -> Control:
	# PNG 있으면 TextureRect, 없으면 흰 베이스 ColorRect (modulate가 색 결정).
	var png_path: String = PNG_PATHS[index]
	if ResourceLoader.exists(png_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(png_path) as Texture2D
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tex_rect
	var color_rect := ColorRect.new()
	color_rect.color = Color.WHITE
	return color_rect


func _on_count_changed(item_id: String, current: int, _max_val: int) -> void:
	var idx: int = CONSUMABLE_IDS.find(item_id)
	if idx < 0:
		return
	_count_labels[idx].text = str(current)
	if current <= 0:
		_slot_backgrounds[idx].modulate = COLOR_EMPTY
	else:
		_slot_backgrounds[idx].modulate = COLOR_ACTIVE


func _on_consumable_used(consumable_type: int, _amount: float) -> void:
	if consumable_type < 0 or consumable_type >= SLOT_COUNT:
		return
	_flash_slot(consumable_type)


func _flash_slot(index: int) -> void:
	var bg: Control = _slot_backgrounds[index]
	bg.modulate = COLOR_FLASH
	if _flash_tweens[index]:
		_flash_tweens[index].kill()
	_flash_tweens[index] = create_tween()
	_flash_tweens[index].tween_property(bg, "modulate", COLOR_ACTIVE, 0.15)


func _refresh_all() -> void:
	for i in range(SLOT_COUNT):
		var count: int = InventorySystem.get_consumable_count(CONSUMABLE_IDS[i])
		_count_labels[i].text = str(count)
		if count <= 0:
			_slot_backgrounds[i].modulate = COLOR_EMPTY

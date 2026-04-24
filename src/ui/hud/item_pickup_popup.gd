extends CanvasLayer

## Phase 3-7 Pass 5 Step 1 ④ — 아이템 획득 팝업.
## EventBus.item_acquired 구독 → 하단 중앙 slide-in 0.2s + hold 1.5s + fade 0.3s.

const FONT_PATH: String = "res://assets/fonts/galmuri/Galmuri11.ttf"
const POPUP_LAYER: int = 60

const POPUP_WIDTH: float = 200.0
const POPUP_HEIGHT: float = 28.0
const ICON_SIZE: float = 16.0
const SCREEN_WIDTH: float = 640.0
const BASE_Y: float = 320.0
const SLIDE_FROM_Y: float = 360.0
const SLIDE_DURATION: float = 0.2
const HOLD_DURATION: float = 1.5
const FADE_DURATION: float = 0.3

const RARITY_BORDER: Dictionary = {
	ItemData.ItemRarity.COMMON: Color(0.7, 0.7, 0.7, 0.9),
	ItemData.ItemRarity.RARE: Color(0.4, 0.7, 1.0, 0.9),
	ItemData.ItemRarity.UNIQUE: Color(0.949, 0.8, 0.4, 0.9),
}

var _panel: PanelContainer
var _icon: TextureRect
var _icon_fallback: ColorRect
var _label: Label
var _tween: Tween
var _font: FontFile
var _label_settings: LabelSettings


func _ready() -> void:
	layer = POPUP_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_font()
	_build_nodes()
	EventBus.item_acquired.connect(_on_item_acquired)


func _load_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH) as FontFile
	_label_settings = LabelSettings.new()
	if _font != null:
		_label_settings.font = _font
	_label_settings.font_size = 12
	_label_settings.font_color = Color(0.95, 0.92, 0.85)
	_label_settings.shadow_offset = Vector2(1, 1)
	_label_settings.shadow_color = Color(0, 0, 0, 0.9)


func _build_nodes() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0
	_panel.visible = false
	add_child(_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(hbox)

	var icon_slot := Control.new()
	icon_slot.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	hbox.add_child(icon_slot)

	_icon_fallback = ColorRect.new()
	_icon_fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon_fallback.color = Color(0.5, 0.5, 0.5, 1.0)
	_icon_fallback.visible = false
	icon_slot.add_child(_icon_fallback)

	_icon = TextureRect.new()
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_slot.add_child(_icon)

	_label = Label.new()
	_label.label_settings = _label_settings
	hbox.add_child(_label)


func _on_item_acquired(item_id: String) -> void:
	var data: Resource = InventorySystem.get_item_data(item_id)
	if data == null or not (data is ItemData):
		return
	var item_data: ItemData = data as ItemData
	_label.text = "%s 획득" % item_data.display_name
	_label_settings.font_color = _rarity_color(item_data.rarity)
	if item_data.icon != null:
		_icon.texture = item_data.icon
		_icon.visible = true
		_icon_fallback.visible = false
	else:
		_icon.texture = null
		_icon.visible = false
		_icon_fallback.color = _rarity_color(item_data.rarity)
		_icon_fallback.visible = true
	_play_popup()


func _rarity_color(rarity: int) -> Color:
	return RARITY_BORDER.get(rarity, Color(0.95, 0.92, 0.85))


func _play_popup() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_panel.size = _panel.get_combined_minimum_size()
	var base_x: float = (SCREEN_WIDTH - _panel.size.x) * 0.5
	_panel.position = Vector2(base_x, SLIDE_FROM_Y)
	_panel.modulate.a = 0.0
	_panel.visible = true
	_tween = create_tween()
	_tween.set_ignore_time_scale(true)
	_tween.tween_property(_panel, "position:y", BASE_Y, SLIDE_DURATION)
	_tween.parallel().tween_property(_panel, "modulate:a", 1.0, SLIDE_DURATION)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(_on_popup_complete)


func _on_popup_complete() -> void:
	_panel.visible = false

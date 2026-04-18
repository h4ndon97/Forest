extends Node2D

## 보스 HP 바 — 화면 하단 풀너비.
## CanvasLayer 자식으로 배치되어 카메라 무관.

const BAR_WIDTH := 480.0
const BAR_HEIGHT := 12.0
const BAR_BOTTOM_MARGIN := 24.0
const BG_COLOR := Color(0.05, 0.05, 0.05, 0.85)
const HP_COLOR := Color(0.9, 0.25, 0.2, 0.95)
const HP_COLOR_LOW := Color(1.0, 0.4, 0.1, 1.0)
const LOW_THRESHOLD := 0.3
const NAME_COLOR := Color(0.95, 0.9, 0.85, 1.0)
const NAME_FONT_SIZE := 12

var _pending_name: String = ""
var _bg: ColorRect = null
var _fill: ColorRect = null
var _name_label: Label = null


## base_boss._ready()에서 호출. _ready()에서 실제 노드 생성 시 사용.
func setup(display_name: String) -> void:
	_pending_name = display_name
	if _name_label:
		_name_label.text = display_name


func _ready() -> void:
	z_index = 100
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var bar_x: float = (viewport_size.x - BAR_WIDTH) * 0.5
	var bar_y: float = viewport_size.y - BAR_BOTTOM_MARGIN - BAR_HEIGHT

	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.position = Vector2(bar_x, bar_y)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.color = HP_COLOR
	_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fill.position = Vector2(bar_x, bar_y)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	_name_label = Label.new()
	_name_label.text = _pending_name
	_name_label.add_theme_color_override("font_color", NAME_COLOR)
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	_name_label.position = Vector2(bar_x, bar_y - 18)
	_name_label.size = Vector2(BAR_WIDTH, 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)


func on_health_changed(current_hp: float, max_hp: float) -> void:
	if _fill == null:
		return
	var ratio: float = current_hp / max_hp if max_hp > 0.0 else 0.0
	_fill.size.x = BAR_WIDTH * ratio
	_fill.color = HP_COLOR_LOW if ratio < LOW_THRESHOLD else HP_COLOR

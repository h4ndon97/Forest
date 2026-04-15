extends Node2D

## 적 머리 위 HP 바 컴포넌트.
## 데미지를 받으면 표시, HP가 최대치로 돌아오면 숨김.

const BAR_WIDTH := 24.0
const BAR_HEIGHT := 3.0
const BAR_OFFSET_Y := -32.0
const BG_COLOR := Color(0.1, 0.1, 0.1, 0.6)
const HP_COLOR := Color(0.8, 0.2, 0.2, 0.8)
const HP_COLOR_LOW := Color(1.0, 0.3, 0.1, 0.9)
const LOW_THRESHOLD := 0.3

var _bg: ColorRect
var _fill: ColorRect


func _ready() -> void:
	position = Vector2(0, BAR_OFFSET_Y)
	z_index = 10

	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.position = Vector2(-BAR_WIDTH * 0.5, 0)
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.color = HP_COLOR
	_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fill.position = Vector2(-BAR_WIDTH * 0.5, 0)
	add_child(_fill)

	visible = false


func on_health_changed(current_hp: float, max_hp: float) -> void:
	var ratio := current_hp / max_hp if max_hp > 0.0 else 0.0
	_fill.size.x = BAR_WIDTH * ratio
	_fill.color = HP_COLOR_LOW if ratio < LOW_THRESHOLD else HP_COLOR
	visible = ratio < 1.0

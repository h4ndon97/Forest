extends Node2D

## 광 센서 교보재 아트 - 룬 스톤 디텍터 + 상태별 코어 + 활성화 시 펄스 halo.
## 크기: 32×32 (Area2D CollisionShape2D와 동일).
## 색상은 LightSensorData.color_on / color_off 기반 — 부모가 configure() 호출.

const RADIUS: float = 14.0
const CORE_RADIUS: float = 6.0
const RUNE_COUNT: int = 6
const RUNE_INNER: float = 10.0
const RUNE_OUTER: float = 13.0

const COLOR_STONE_BASE := Color(0.34, 0.31, 0.29, 1.0)
const COLOR_STONE_HIGHLIGHT := Color(0.48, 0.44, 0.40, 1.0)
const COLOR_STONE_SHADOW := Color(0.20, 0.18, 0.16, 1.0)
const COLOR_RUNE_OFF := Color(0.18, 0.16, 0.14, 1.0)

const PULSE_PERIOD: float = 1.6

@export var sprite_path: String = ""

var _t: float = 0.0
var _active: bool = false
var _color_on: Color = Color(1.0, 0.9, 0.4)
var _color_off: Color = Color(0.3, 0.3, 0.3)
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	if _sprite == null or not _sprite.visible:
		if _active:
			queue_redraw()


func configure(color_off: Color, color_on: Color) -> void:
	_color_off = color_off
	_color_on = color_on
	queue_redraw()


func set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	if not _active:
		_t = 0.0
	queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	if _active:
		_draw_halo()
	_draw_stone_ring()
	_draw_runes()
	_draw_core()


func _draw_halo() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / PULSE_PERIOD)
	var halo_r: float = RADIUS + 2.0 + pulse * 4.0
	var halo: Color = _color_on
	halo.a = 0.18 + 0.18 * pulse
	draw_circle(Vector2.ZERO, halo_r, halo)
	var mid: Color = _color_on
	mid.a = 0.28 + 0.22 * pulse
	draw_circle(Vector2.ZERO, RADIUS + 1.0, mid)


func _draw_stone_ring() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR_STONE_BASE)
	draw_arc(
		Vector2.ZERO, RADIUS - 0.5, PI + 0.2, TAU - 0.2, 16, COLOR_STONE_HIGHLIGHT, 1.0, false
	)
	draw_arc(
		Vector2.ZERO, RADIUS - 0.5, 0.2, PI - 0.2, 16, COLOR_STONE_SHADOW, 1.0, false
	)


func _draw_runes() -> void:
	var rune_color: Color = _color_on if _active else COLOR_RUNE_OFF
	if _active:
		var pulse: float = 0.6 + 0.4 * sin(_t * TAU / PULSE_PERIOD)
		rune_color.a *= pulse
	for i in range(RUNE_COUNT):
		var theta: float = TAU * float(i) / float(RUNE_COUNT) - PI * 0.5
		var inner := Vector2(cos(theta) * RUNE_INNER, sin(theta) * RUNE_INNER)
		var outer := Vector2(cos(theta) * RUNE_OUTER, sin(theta) * RUNE_OUTER)
		draw_line(inner, outer, rune_color, 1.5)


func _draw_core() -> void:
	var core_color: Color = _color_on if _active else _color_off
	if _active:
		var pulse: float = 0.75 + 0.25 * sin(_t * TAU / PULSE_PERIOD)
		var outer: Color = core_color
		outer.a *= pulse
		draw_circle(Vector2.ZERO, CORE_RADIUS + 1.5, outer)
	draw_circle(Vector2.ZERO, CORE_RADIUS, core_color)
	# 코어 하이라이트 (좌상단 광택)
	var hl_color: Color = Color(1.0, 1.0, 1.0, 0.55 if _active else 0.22)
	draw_circle(Vector2(-1.5, -1.5), CORE_RADIUS * 0.45, hl_color)


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "LightSensorSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

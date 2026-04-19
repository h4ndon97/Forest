extends Node2D

## 반사 바닥 교보재 아트 - 얕은 수면/거울 풀 + 잔물결 + 하이라이트 밴드.
## 원점 = 바닥 중심. 크기는 부모가 configure()로 전달.

const WIDTH_DEFAULT: float = 192.0
const HEIGHT_DEFAULT: float = 32.0
const RIPPLE_COUNT: int = 3

const COLOR_WATER_BASE := Color(0.16, 0.29, 0.35, 0.78)
const COLOR_WATER_DEEP := Color(0.08, 0.18, 0.24, 0.85)
const COLOR_WATER_EDGE := Color(0.24, 0.40, 0.50, 1.0)
const COLOR_WATER_HIGHLIGHT := Color(0.62, 0.82, 0.90, 0.55)
const COLOR_RIPPLE := Color(0.75, 0.88, 0.95, 0.35)

const RIPPLE_PERIOD: float = 2.8

@export var sprite_path: String = ""

var _t: float = 0.0
var _size: Vector2 = Vector2(WIDTH_DEFAULT, HEIGHT_DEFAULT)
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	if _sprite == null or not _sprite.visible:
		queue_redraw()


func configure(size: Vector2) -> void:
	_size = size
	queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	_draw_water_body()
	_draw_edges()
	_draw_ripples()
	_draw_highlight_band()


func _draw_water_body() -> void:
	var half_w: float = _size.x * 0.5
	var half_h: float = _size.y * 0.5
	draw_rect(Rect2(-half_w, -half_h, _size.x, _size.y), COLOR_WATER_BASE, true)
	var deep_h: float = _size.y * 0.5
	draw_rect(
		Rect2(-half_w + 6.0, -deep_h * 0.5, _size.x - 12.0, deep_h),
		COLOR_WATER_DEEP,
		true
	)


func _draw_edges() -> void:
	var half_w: float = _size.x * 0.5
	var half_h: float = _size.y * 0.5
	draw_line(
		Vector2(-half_w, -half_h), Vector2(half_w, -half_h), COLOR_WATER_EDGE, 1.0
	)
	draw_line(
		Vector2(-half_w, half_h), Vector2(half_w, half_h), COLOR_WATER_EDGE, 1.0
	)


func _draw_ripples() -> void:
	var half_w: float = _size.x * 0.5
	var cycle: float = _t / RIPPLE_PERIOD
	for i in range(RIPPLE_COUNT):
		var seed_x: float = sin(float(i) * 2.4 + cycle * TAU) * (half_w - 16.0)
		var phase: float = fposmod(cycle + float(i) * 0.33, 1.0)
		var radius: float = phase * 18.0
		var alpha_scale: float = 1.0 - phase
		if alpha_scale <= 0.0:
			continue
		var color: Color = COLOR_RIPPLE
		color.a *= alpha_scale
		draw_arc(Vector2(seed_x, 0.0), radius, 0.0, TAU, 16, color, 1.0, false)


func _draw_highlight_band() -> void:
	var half_w: float = _size.x * 0.5
	var band_y: float = -_size.y * 0.25
	var wobble: float = 0.8
	var segments: int = 16
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var tt: float = float(i) / float(segments)
		var x: float = lerpf(-half_w + 8.0, half_w - 8.0, tt)
		var y: float = band_y + sin(tt * TAU * 2.0 + _t * 1.4) * wobble
		points.append(Vector2(x, y))
	draw_polyline(points, COLOR_WATER_HIGHLIGHT, 1.2, false)


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "ReflectiveFloorSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

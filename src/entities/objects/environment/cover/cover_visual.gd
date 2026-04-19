extends Node2D

## 차폐물 교보재 아트 - 석판 기둥 + 균열 + 이끼.
## 원점 = 차폐물 중심. 크기는 부모가 configure()로 전달.

const WIDTH_DEFAULT: float = 24.0
const HEIGHT_DEFAULT: float = 64.0

const COLOR_STONE_BASE := Color(0.40, 0.38, 0.35, 1.0)
const COLOR_STONE_HIGHLIGHT := Color(0.52, 0.50, 0.46, 1.0)
const COLOR_STONE_SHADOW := Color(0.24, 0.22, 0.20, 1.0)
const COLOR_CRACK := Color(0.14, 0.13, 0.12, 1.0)
const COLOR_MOSS_DARK := Color(0.20, 0.34, 0.18, 1.0)
const COLOR_MOSS_LIGHT := Color(0.36, 0.52, 0.28, 1.0)

@export var sprite_path: String = ""

var _size: Vector2 = Vector2(WIDTH_DEFAULT, HEIGHT_DEFAULT)
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func configure(size: Vector2) -> void:
	_size = size
	queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	_draw_body()
	_draw_edges()
	_draw_cracks()
	_draw_moss()


func _draw_body() -> void:
	var half_w: float = _size.x * 0.5
	var half_h: float = _size.y * 0.5
	draw_rect(Rect2(-half_w, -half_h, _size.x, _size.y), COLOR_STONE_BASE, true)


func _draw_edges() -> void:
	var half_w: float = _size.x * 0.5
	var half_h: float = _size.y * 0.5
	draw_rect(Rect2(-half_w, -half_h, 1.5, _size.y), COLOR_STONE_HIGHLIGHT, true)
	draw_rect(Rect2(-half_w, -half_h, _size.x, 1.5), COLOR_STONE_HIGHLIGHT, true)
	draw_rect(
		Rect2(half_w - 1.5, -half_h, 1.5, _size.y), COLOR_STONE_SHADOW, true
	)
	draw_rect(
		Rect2(-half_w, half_h - 1.5, _size.x, 1.5), COLOR_STONE_SHADOW, true
	)


func _draw_cracks() -> void:
	var half_w: float = _size.x * 0.5
	var half_h: float = _size.y * 0.5
	var crack_x: float = half_w * 0.3
	var crack_top := Vector2(crack_x, -half_h * 0.6)
	var crack_mid := Vector2(crack_x - 2.0, -half_h * 0.1)
	var crack_bot := Vector2(crack_x + 1.0, half_h * 0.4)
	draw_line(crack_top, crack_mid, COLOR_CRACK, 1.0)
	draw_line(crack_mid, crack_bot, COLOR_CRACK, 1.0)
	draw_line(crack_mid, Vector2(crack_x + 3.0, -half_h * 0.05), COLOR_CRACK, 1.0)


func _draw_moss() -> void:
	var half_w: float = _size.x * 0.5
	var half_h: float = _size.y * 0.5
	var moss_h: float = clampf(_size.y * 0.15, 4.0, 10.0)
	for i in range(5):
		var x: float = lerpf(-half_w + 2.0, half_w - 2.0, (float(i) + 0.5) / 5.0)
		var bump: float = 1.5 + float(i % 2)
		draw_rect(
			Rect2(x - 2.0, -half_h - 1.0, 4.0, moss_h + bump),
			COLOR_MOSS_DARK,
			true
		)
	for i in range(3):
		var x: float = lerpf(-half_w + 4.0, half_w - 4.0, (float(i) + 0.5) / 3.0)
		draw_circle(Vector2(x, -half_h + moss_h * 0.5), 1.3, COLOR_MOSS_LIGHT)
	draw_circle(Vector2(-half_w + 3.0, half_h - 2.0), 2.0, COLOR_MOSS_DARK)
	draw_circle(Vector2(half_w - 4.0, half_h - 3.0), 1.8, COLOR_MOSS_DARK)


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "CoverSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

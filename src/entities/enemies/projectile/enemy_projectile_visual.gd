extends Node2D

## 적 투사체(돌 파편) 교보재 프로그래밍 아트.
## 원점(0,0) = 투사체 중심. 기본 비행 방향 = +X (오른쪽).
## 좌향 비행 시 부모가 scale.x = -1.0으로 플립.

const BODY_WIDTH: float = 16.0
const BODY_HEIGHT: float = 10.0

const COLOR_ROCK_BASE := Color(0.420, 0.400, 0.376, 1.0)
const COLOR_ROCK_HIGHLIGHT := Color(0.580, 0.560, 0.530, 1.0)
const COLOR_ROCK_SHADOW := Color(0.250, 0.230, 0.210, 1.0)
const COLOR_CRACK := Color(0.150, 0.130, 0.110, 1.0)
const COLOR_DUST := Color(0.600, 0.570, 0.530, 1.0)

const TRAIL_SEGMENTS: int = 3
const TRAIL_STEP: float = 4.0
const SPIN_PERIOD: float = 0.4
const SPIN_AMPLITUDE: float = 0.18

@export var sprite_path: String = ""

var _t: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	if _sprite == null or not _sprite.visible:
		queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	_draw_trail()
	_draw_shard()


func _draw_trail() -> void:
	for i in range(TRAIL_SEGMENTS):
		var step: float = float(i + 1)
		var x: float = -BODY_WIDTH * 0.4 - step * TRAIL_STEP
		var wobble: float = sin(_t * TAU * 4.0 + step * 1.3) * 0.8
		var radius: float = lerpf(2.2, 0.8, step / float(TRAIL_SEGMENTS + 1))
		var dust: Color = COLOR_DUST
		dust.a = lerpf(0.55, 0.12, step / float(TRAIL_SEGMENTS + 1))
		draw_circle(Vector2(x, wobble), radius, dust)


func _draw_shard() -> void:
	var tilt: float = sin(_t * TAU / SPIN_PERIOD) * SPIN_AMPLITUDE
	var half_w: float = BODY_WIDTH * 0.5
	var half_h: float = BODY_HEIGHT * 0.5

	var tip := _rot(Vector2(half_w, 0.0), tilt)
	var top_back := _rot(Vector2(-half_w + 2.0, -half_h + 1.0), tilt)
	var top_front := _rot(Vector2(half_w - 4.0, -half_h + 2.0), tilt)
	var bot_front := _rot(Vector2(half_w - 5.0, half_h - 1.0), tilt)
	var bot_back := _rot(Vector2(-half_w + 3.0, half_h - 2.0), tilt)

	var body := PackedVector2Array([
		tip, top_front, top_back, bot_back, bot_front
	])
	draw_colored_polygon(body, COLOR_ROCK_BASE)

	# 상단 하이라이트 (팁 → 상단 뒤쪽)
	draw_line(top_front, tip, COLOR_ROCK_HIGHLIGHT, 1.0)
	draw_line(top_back, top_front, COLOR_ROCK_HIGHLIGHT, 1.0)

	# 하단 섀도우 (팁 → 하단 뒤쪽)
	draw_line(bot_front, tip, COLOR_ROCK_SHADOW, 1.0)
	draw_line(bot_back, bot_front, COLOR_ROCK_SHADOW, 1.0)

	# 균열 — 중앙에서 상단으로 짧게
	var crack_start := _rot(Vector2(1.0, -1.0), tilt)
	var crack_end := _rot(Vector2(-3.0, -half_h + 2.5), tilt)
	draw_line(crack_start, crack_end, COLOR_CRACK, 1.0)


# --- 내부 ---

func _rot(p: Vector2, angle: float) -> Vector2:
	var c: float = cos(angle)
	var s: float = sin(angle)
	return Vector2(p.x * c - p.y * s, p.x * s + p.y * c)


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "ProjectileSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

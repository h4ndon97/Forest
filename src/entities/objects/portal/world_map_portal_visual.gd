extends Node2D

## 월드맵 포탈 나무 심벌 (F-10) 프로그래밍 아트.
## portals_checkpoints.md §3 준수.

const HALO_RADIUS: float = 22.0
const TRUNK_WIDTH: float = 6.0
const TRUNK_HEIGHT: float = 20.0
const ROOT_LENGTH: float = 8.0

const COLOR_HALO := Color(0.949, 0.8, 0.4, 0.2)
const COLOR_TRUNK := Color(0.353, 0.290, 0.188, 1.0)
const COLOR_LEAF_BASE := Color(0.420, 0.561, 0.290, 1.0)
const COLOR_LEAF_ACTIVE := Color(0.949, 0.8, 0.4, 1.0)
const COLOR_FIREFLY := Color(1.0, 0.957, 0.8, 1.0)

const HALO_PERIOD: float = 1.8
const HALO_MIN_A: float = 0.15
const HALO_MAX_A: float = 0.25
const NEAR_LERP_SPEED: float = 3.0

@export var sprite_path: String = ""

var player_nearby: bool = false

var _t: float = 0.0
var _near_mix: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	var target: float = 1.0 if player_nearby else 0.0
	_near_mix = move_toward(_near_mix, target, delta * NEAR_LERP_SPEED)
	if _sprite == null or not _sprite.visible:
		queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return

	_draw_halo()
	_draw_trunk()
	_draw_roots()
	_draw_leaves()
	_draw_fireflies()


func _draw_halo() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / HALO_PERIOD)
	var alpha: float = lerpf(HALO_MIN_A, HALO_MAX_A, pulse)
	var c: Color = COLOR_HALO
	c.a = alpha
	# 원형 그라데이션 근사: 반경을 3단계로 나누어 알파 감쇠
	draw_circle(Vector2.ZERO, HALO_RADIUS, Color(c.r, c.g, c.b, alpha * 0.3))
	draw_circle(Vector2.ZERO, HALO_RADIUS * 0.7, Color(c.r, c.g, c.b, alpha * 0.55))
	draw_circle(Vector2.ZERO, HALO_RADIUS * 0.45, Color(c.r, c.g, c.b, alpha))


func _draw_trunk() -> void:
	var half_w: float = TRUNK_WIDTH * 0.5
	draw_rect(Rect2(-half_w, -2.0, TRUNK_WIDTH, TRUNK_HEIGHT), COLOR_TRUNK, true)


func _draw_roots() -> void:
	var base_y: float = TRUNK_HEIGHT - 2.0
	var angles: Array[float] = [-PI * 0.85, -PI * 0.5, -PI * 0.15]
	for a in angles:
		var dx: float = cos(a) * ROOT_LENGTH
		var dy: float = -sin(a) * ROOT_LENGTH  # -sin: 아래로 뻗기
		draw_line(Vector2(0, base_y), Vector2(dx, base_y + dy), COLOR_TRUNK, 2.0)


func _draw_leaves() -> void:
	var leaf_color: Color = COLOR_LEAF_BASE.lerp(COLOR_LEAF_ACTIVE, _near_mix)
	# 상단 3개
	_draw_leaf(Vector2(0, -6), leaf_color, 3.5)
	_draw_leaf(Vector2(-5, -3), leaf_color, 3.0)
	_draw_leaf(Vector2(5, -3), leaf_color, 3.0)
	# 측면 2개
	_draw_leaf(Vector2(-7, 4), leaf_color, 2.5)
	_draw_leaf(Vector2(7, 4), leaf_color, 2.5)


func _draw_leaf(pos: Vector2, color: Color, r: float) -> void:
	draw_circle(pos, r, color)
	# 하이라이트 1px
	draw_circle(pos + Vector2(-0.5, -0.8), 0.6, Color(1.0, 0.957, 0.8, 0.7))


func _draw_fireflies() -> void:
	if _near_mix < 0.1:
		return
	var count: int = int(roundf(_near_mix * 3.0))
	for i in count:
		var phase: float = float(i) / 3.0
		var tt: float = fmod(_t * 0.6 + phase, 1.0)
		var a: float = sin(tt * PI) * _near_mix
		var pos := Vector2(
			cos((tt + phase) * TAU) * 9.0,
			-6.0 + sin((tt + phase) * TAU) * 5.0
		)
		var c: Color = COLOR_FIREFLY
		c.a *= a
		draw_circle(pos, 1.0, c)


func set_player_nearby(value: bool) -> void:
	player_nearby = value


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "PortalSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

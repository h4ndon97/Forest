extends Node2D

## 거점 세이브 마커 — 나무 심벌 (F-10, 거점 버전).
## portals_checkpoints.md §4 준수.
## 월드맵 포탈보다 안정적이고 존재감 있는 버전.

const TRUNK_WIDTH: float = 5.0
const TRUNK_HEIGHT: float = 24.0
const BRANCH_LENGTH: float = 10.0
const BRANCH_ANGLE_DEG: float = 35.0

const COLOR_GROUND_SHADOW := Color(0.353, 0.290, 0.188, 0.6)
const COLOR_TRUNK := Color(0.353, 0.290, 0.188, 1.0)
const COLOR_TRUNK_BASE := Color(0.278, 0.227, 0.149, 1.0)   # 아랫쪽 살짝 어둡게
const COLOR_LEAF := Color(0.420, 0.561, 0.290, 1.0)
const COLOR_LEAF_HIGHLIGHT := Color(1.0, 0.957, 0.8, 0.9)
const COLOR_GLOW_NEAR := Color(0.949, 0.8, 0.4, 0.4)

const COLOR_FLASH_GOLD := Color(0.949, 0.8, 0.4, 1.0)
const COLOR_FLASH_CYAN := Color(0.4, 0.85, 0.95, 1.0)
const FLASH_DURATION: float = 0.5
const FLASH_COUNT: int = 2
const NEAR_LERP_SPEED: float = 3.5

@export var sprite_path: String = ""

var player_nearby: bool = false

var _t: float = 0.0
var _near_mix: float = 0.0
var _flash_t: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	var target: float = 1.0 if player_nearby else 0.0
	_near_mix = move_toward(_near_mix, target, delta * NEAR_LERP_SPEED)
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
	if _sprite == null or not _sprite.visible:
		queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return

	_draw_ground_shadow()
	if _near_mix > 0.01:
		_draw_base_glow()
	_draw_trunk_and_branches()
	_draw_leaves()


func _draw_ground_shadow() -> void:
	var segments: int = 12
	var pts := PackedVector2Array()
	var rx: float = 12.0
	var ry: float = 3.0
	var cy: float = TRUNK_HEIGHT - 1.0
	for i in segments:
		var a: float = float(i) / segments * TAU
		pts.append(Vector2(cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, COLOR_GROUND_SHADOW)


func _draw_base_glow() -> void:
	var c: Color = COLOR_GLOW_NEAR
	c.a *= _near_mix
	var cy: float = TRUNK_HEIGHT - 2.0
	draw_circle(Vector2(0, cy), 6.0, Color(c.r, c.g, c.b, c.a * 0.4))
	draw_circle(Vector2(0, cy), 4.0, c)


func _draw_trunk_and_branches() -> void:
	var half_w: float = TRUNK_WIDTH * 0.5
	# 메인 줄기 (위쪽)
	draw_rect(Rect2(-half_w, -12.0, TRUNK_WIDTH, TRUNK_HEIGHT - 8.0), COLOR_TRUNK, true)
	# 줄기 밑동 (살짝 두껍고 어둡게)
	var base_w: float = TRUNK_WIDTH + 2.0
	draw_rect(Rect2(-base_w * 0.5, TRUNK_HEIGHT - 8.0, base_w, 6.0), COLOR_TRUNK_BASE, true)
	# 가지 2개
	var a_rad: float = deg_to_rad(BRANCH_ANGLE_DEG)
	var branch_base_y: float = -6.0
	draw_line(
		Vector2(0, branch_base_y),
		Vector2(-sin(a_rad) * BRANCH_LENGTH, branch_base_y - cos(a_rad) * BRANCH_LENGTH),
		COLOR_TRUNK,
		2.0
	)
	draw_line(
		Vector2(0, branch_base_y),
		Vector2(sin(a_rad) * BRANCH_LENGTH, branch_base_y - cos(a_rad) * BRANCH_LENGTH),
		COLOR_TRUNK,
		2.0
	)


func _draw_leaves() -> void:
	var leaf_color: Color = COLOR_LEAF
	# 플래시 오버라이드 (세이브 완료 이중 플래시)
	if _flash_t > 0.0:
		var phase: float = _flash_t / FLASH_DURATION
		var alternate: int = int(phase * FLASH_COUNT * 2.0) % 2
		leaf_color = COLOR_FLASH_GOLD if alternate == 0 else COLOR_FLASH_CYAN

	var positions: Array[Vector2] = [
		Vector2(0, -18),
		Vector2(-4, -15),
		Vector2(4, -15),
		Vector2(-7, -12),
		Vector2(7, -12),
		Vector2(-9, -9),
		Vector2(9, -9),
	]
	for p in positions:
		draw_circle(p, 2.8, leaf_color)
		draw_circle(p + Vector2(-0.5, -0.8), 0.7, COLOR_LEAF_HIGHLIGHT)


func set_player_nearby(value: bool) -> void:
	player_nearby = value


func trigger_save_flash() -> void:
	_flash_t = FLASH_DURATION


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "MarkerSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

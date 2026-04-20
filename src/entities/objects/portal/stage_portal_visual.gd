extends Node2D

## 스테이지 포탈 아치형 벽돌 구조물 + 덩굴 프로그래밍 아트.
## 폭 48 × 높이 75, Node2D 원점 중심.
## portals_checkpoints.md §2 준수.

const PORTAL_WIDTH: float = 48.0
const PORTAL_HEIGHT: float = 75.0
const WALL_THICKNESS: float = 8.0
const PILLAR_HEIGHT: float = 50.0
const ARCH_RADIUS_OUTER: float = 24.0
const ARCH_RADIUS_MID: float = 20.0
const ARCH_THICKNESS: float = 8.0

# Node2D 원점 = 포탈 바닥(지면 접지점). 포탈은 원점에서 위로 뻗는다.
const Y_BOTTOM: float = 0.0
const Y_TOP: float = -PORTAL_HEIGHT
const Y_PILLAR_TOP: float = Y_BOTTOM - PILLAR_HEIGHT

const COLOR_STONE_BASE := Color(0.420, 0.400, 0.376, 1.0)
const COLOR_STONE_HIGHLIGHT := Color(0.541, 0.522, 0.498, 1.0)
const COLOR_STONE_SHADOW := Color(0.290, 0.271, 0.247, 1.0)
const COLOR_MORTAR := Color(0.165, 0.145, 0.125, 1.0)
const COLOR_VINE := Color(0.290, 0.353, 0.188, 1.0)
const COLOR_LEAF := Color(0.420, 0.561, 0.290, 1.0)
const COLOR_PORTAL_GLOW := Color(0.949, 0.8, 0.4, 0.35)
const COLOR_PORTAL_CORE := Color(1.0, 0.957, 0.8, 0.25)

const GLOW_PERIOD: float = 2.4
const NEAR_LERP_SPEED: float = 3.0
const NEAR_GLOW_BOOST: float = 1.4

# 스프라이트 모드 코어 글로우 — 포탈 개구부 위에 덮이는 방사형 그라디언트
const GLOW_WIDTH: int = 32
const GLOW_HEIGHT: int = 48
const GLOW_ALPHA_BASE: float = 0.35
const GLOW_ALPHA_AMP: float = 0.25

@export var sprite_path: String = "res://assets/sprites/objects/portal_stage.png"

var player_nearby: bool = false

var _t: float = 0.0
var _near_mix: float = 0.0
var _sprite: Sprite2D
var _core_glow: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	var target: float = 1.0 if player_nearby else 0.0
	_near_mix = move_toward(_near_mix, target, delta * NEAR_LERP_SPEED)
	if _sprite != null and _sprite.visible:
		_update_core_glow()
	else:
		queue_redraw()


func _update_core_glow() -> void:
	if _core_glow == null:
		return
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / GLOW_PERIOD)
	var base_a: float = GLOW_ALPHA_BASE + GLOW_ALPHA_AMP * (pulse * 2.0 - 1.0)
	var near_boost: float = lerpf(1.0, NEAR_GLOW_BOOST, _near_mix)
	_core_glow.modulate.a = clampf(base_a * near_boost, 0.0, 1.0)


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return

	_draw_portal_interior()
	_draw_pillars()
	_draw_arch_top()
	_draw_stone_edges()
	_draw_vines()


func _draw_portal_interior() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / GLOW_PERIOD)
	var base_intensity: float = lerpf(0.7, 1.0, pulse)
	var near_boost: float = lerpf(1.0, NEAR_GLOW_BOOST, _near_mix)
	var intensity: float = base_intensity * near_boost
	var center := Vector2(0, (Y_PILLAR_TOP + Y_BOTTOM) * 0.5)

	var halo: Color = COLOR_PORTAL_GLOW
	halo.a *= intensity * 0.4
	draw_circle(center, 18.0, halo)

	var mid: Color = COLOR_PORTAL_GLOW
	mid.a *= intensity
	draw_circle(center, 12.0, mid)

	var core: Color = COLOR_PORTAL_CORE
	core.a *= intensity
	draw_circle(center, 6.0, core)


func _draw_pillars() -> void:
	_draw_one_pillar(-PORTAL_WIDTH * 0.5)
	_draw_one_pillar(PORTAL_WIDTH * 0.5 - WALL_THICKNESS)


func _draw_one_pillar(x_left: float) -> void:
	draw_rect(Rect2(x_left, Y_PILLAR_TOP, WALL_THICKNESS, PILLAR_HEIGHT), COLOR_STONE_BASE, true)
	var course_count: int = 5
	var course_h: float = PILLAR_HEIGHT / float(course_count)
	for i in range(1, course_count):
		var y: float = Y_PILLAR_TOP + i * course_h
		draw_line(
			Vector2(x_left, y),
			Vector2(x_left + WALL_THICKNESS, y),
			COLOR_MORTAR,
			1.0
		)


func _draw_arch_top() -> void:
	var center := Vector2(0, Y_PILLAR_TOP)
	draw_arc(center, ARCH_RADIUS_MID, PI, TAU, 28, COLOR_STONE_BASE, ARCH_THICKNESS, false)
	var mortar_count: int = 5
	for i in range(1, mortar_count + 1):
		var t: float = float(i) / float(mortar_count + 1)
		var a: float = lerpf(PI, TAU, t)
		var p0: Vector2 = center + Vector2(cos(a), sin(a)) * (ARCH_RADIUS_MID - ARCH_THICKNESS * 0.5)
		var p1: Vector2 = center + Vector2(cos(a), sin(a)) * (ARCH_RADIUS_MID + ARCH_THICKNESS * 0.5)
		draw_line(p0, p1, COLOR_MORTAR, 1.0)


func _draw_stone_edges() -> void:
	var hl_w: float = 1.0
	draw_rect(
		Rect2(-PORTAL_WIDTH * 0.5, Y_PILLAR_TOP, hl_w, PILLAR_HEIGHT),
		COLOR_STONE_HIGHLIGHT,
		true
	)
	draw_rect(
		Rect2(PORTAL_WIDTH * 0.5 - hl_w, Y_PILLAR_TOP, hl_w, PILLAR_HEIGHT),
		COLOR_STONE_SHADOW,
		true
	)
	var center := Vector2(0, Y_PILLAR_TOP)
	draw_arc(
		center,
		ARCH_RADIUS_MID + ARCH_THICKNESS * 0.5 - 0.5,
		PI + 0.15,
		PI + 1.0,
		10,
		COLOR_STONE_HIGHLIGHT,
		1.0,
		false
	)


func _draw_vines() -> void:
	_draw_vine_segment(
		Vector2(-PORTAL_WIDTH * 0.5 - 2, Y_BOTTOM),
		Vector2(-PORTAL_WIDTH * 0.5 - 2, Y_PILLAR_TOP),
		4
	)
	_draw_vine_segment(
		Vector2(PORTAL_WIDTH * 0.5 + 2, Y_BOTTOM),
		Vector2(PORTAL_WIDTH * 0.5 + 2, Y_PILLAR_TOP),
		4
	)
	_draw_arch_vine()


func _draw_vine_segment(start: Vector2, end_p: Vector2, leaf_count: int) -> void:
	var direction: Vector2 = end_p - start
	if direction.length() < 1.0:
		return
	var normal: Vector2 = direction.rotated(PI * 0.5).normalized()
	var segments: int = 12
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var wobble: float = sin(t * PI * 3.0) * 2.0
		points.append(start.lerp(end_p, t) + normal * wobble)
	draw_polyline(points, COLOR_VINE, 1.5, false)

	for i in range(leaf_count):
		var t2: float = float(i + 1) / float(leaf_count + 1)
		var wobble2: float = sin(t2 * PI * 3.0) * 2.0
		var leaf_pos: Vector2 = start.lerp(end_p, t2) + normal * (wobble2 + 1.5)
		draw_circle(leaf_pos, 1.8, COLOR_LEAF)


func _draw_arch_vine() -> void:
	var center := Vector2(0, Y_PILLAR_TOP)
	var base_r: float = ARCH_RADIUS_OUTER + 1.0
	var segments: int = 20
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var a: float = lerpf(PI, TAU, t)
		var wobble: float = sin(t * PI * 4.0) * 1.5
		var r: float = base_r + wobble
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_polyline(points, COLOR_VINE, 1.5, false)

	var leaf_count: int = 4
	for i in range(leaf_count):
		var t: float = float(i + 1) / float(leaf_count + 1)
		var a: float = lerpf(PI, TAU, t)
		var pos: Vector2 = center + Vector2(cos(a), sin(a)) * (base_r + 2.5)
		draw_circle(pos, 1.8, COLOR_LEAF)


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
	# PNG 중심이 포탈 중앙이라 가정 — Node2D 원점(바닥)에서 위로 반 높이만큼 오프셋
	_sprite.position = Vector2(0, -PORTAL_HEIGHT * 0.5)
	add_child(_sprite)
	_core_glow = _make_radial_glow()
	_core_glow.position = Vector2(0, (Y_PILLAR_TOP + Y_BOTTOM) * 0.5)
	add_child(_core_glow)


func _make_radial_glow() -> Sprite2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.30),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	var gtex := GradientTexture2D.new()
	gtex.gradient = gradient
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	gtex.width = GLOW_WIDTH
	gtex.height = GLOW_HEIGHT
	var spr := Sprite2D.new()
	spr.name = "PortalCoreGlow"
	spr.texture = gtex
	spr.centered = true
	spr.modulate = Color(COLOR_PORTAL_GLOW.r, COLOR_PORTAL_GLOW.g, COLOR_PORTAL_GLOW.b, 0.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	return spr

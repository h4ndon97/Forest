extends Node2D

## 거울 교보재 아트 - 금속 프레임 다이아몬드 + 반사 빔.
## RotationPivot 하위 배치 (회전 적용).
## 본체 24×40 (원점 중심), 빔은 원점에서 +x 방향 128픽셀 발산.

const MIRROR_WIDTH: float = 24.0
const MIRROR_HEIGHT: float = 40.0
const BEAM_LENGTH: float = 128.0
const BEAM_HALF_WIDTH: float = 64.0

const COLOR_FRAME_BASE := Color(0.44, 0.40, 0.29, 1.0)
const COLOR_FRAME_HIGHLIGHT := Color(0.62, 0.56, 0.38, 1.0)
const COLOR_FRAME_SHADOW := Color(0.29, 0.25, 0.18, 1.0)
const COLOR_GLASS_CORE := Color(0.85, 0.92, 0.98, 1.0)
const COLOR_GLASS_HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.75)
const COLOR_GLASS_DEEP := Color(0.45, 0.55, 0.70, 1.0)
const COLOR_BEAM_INNER := Color(1.0, 0.95, 0.6, 0.32)
const COLOR_BEAM_OUTER := Color(1.0, 0.82, 0.4, 0.16)

const SHIMMER_PERIOD: float = 2.2

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
	_draw_beam()
	_draw_frame()
	_draw_glass()


func _draw_beam() -> void:
	var pulse: float = 0.85 + 0.15 * sin(_t * TAU / SHIMMER_PERIOD)
	var outer: Color = COLOR_BEAM_OUTER
	outer.a *= pulse
	var inner: Color = COLOR_BEAM_INNER
	inner.a *= pulse
	var outer_fan := PackedVector2Array(
		[
			Vector2(0, 0),
			Vector2(BEAM_LENGTH * 0.78, -BEAM_HALF_WIDTH),
			Vector2(BEAM_LENGTH, -BEAM_HALF_WIDTH * 0.5),
			Vector2(BEAM_LENGTH, BEAM_HALF_WIDTH * 0.5),
			Vector2(BEAM_LENGTH * 0.78, BEAM_HALF_WIDTH),
		]
	)
	draw_colored_polygon(outer_fan, outer)
	var inner_fan := PackedVector2Array(
		[
			Vector2(0, 0),
			Vector2(BEAM_LENGTH * 0.85, -BEAM_HALF_WIDTH * 0.5),
			Vector2(BEAM_LENGTH, -BEAM_HALF_WIDTH * 0.22),
			Vector2(BEAM_LENGTH, BEAM_HALF_WIDTH * 0.22),
			Vector2(BEAM_LENGTH * 0.85, BEAM_HALF_WIDTH * 0.5),
		]
	)
	draw_colored_polygon(inner_fan, inner)


func _draw_frame() -> void:
	var half_w: float = MIRROR_WIDTH * 0.5
	var half_h: float = MIRROR_HEIGHT * 0.5
	var outer := PackedVector2Array(
		[
			Vector2(0, -half_h),
			Vector2(half_w, 0),
			Vector2(0, half_h),
			Vector2(-half_w, 0),
		]
	)
	draw_colored_polygon(outer, COLOR_FRAME_BASE)
	draw_line(Vector2(0, -half_h), Vector2(-half_w, 0), COLOR_FRAME_HIGHLIGHT, 1.5)
	draw_line(Vector2(-half_w, 0), Vector2(0, half_h), COLOR_FRAME_HIGHLIGHT, 1.0)
	draw_line(Vector2(0, -half_h), Vector2(half_w, 0), COLOR_FRAME_SHADOW, 1.0)
	draw_line(Vector2(half_w, 0), Vector2(0, half_h), COLOR_FRAME_SHADOW, 1.5)


func _draw_glass() -> void:
	var half_w: float = (MIRROR_WIDTH - 6.0) * 0.5
	var half_h: float = (MIRROR_HEIGHT - 6.0) * 0.5
	var glass := PackedVector2Array(
		[
			Vector2(0, -half_h),
			Vector2(half_w, 0),
			Vector2(0, half_h),
			Vector2(-half_w, 0),
		]
	)
	draw_colored_polygon(glass, COLOR_GLASS_CORE)
	var deep := PackedVector2Array(
		[
			Vector2(half_w, 0),
			Vector2(0, half_h),
			Vector2(-half_w * 0.3, half_h * 0.3),
			Vector2(half_w * 0.3, -half_h * 0.3),
		]
	)
	draw_colored_polygon(deep, COLOR_GLASS_DEEP)
	var shimmer_offset: float = sin(_t * TAU / SHIMMER_PERIOD) * 1.5
	var hl_start := Vector2(-half_w * 0.4 + shimmer_offset * 0.3, -half_h * 0.4)
	var hl_end := Vector2(-half_w * 0.1, -half_h * 0.1 + shimmer_offset * 0.3)
	draw_line(hl_start, hl_end, COLOR_GLASS_HIGHLIGHT, 1.5)


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "MirrorSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

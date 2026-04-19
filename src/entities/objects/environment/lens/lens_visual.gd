extends Node2D

## 렌즈 교보재 아트 - 12각 크리스탈 본체 + 원뿔 수렴 빔 + 집광 영역.
## RotationPivot 하위 배치 (회전 적용).
## 크기는 LensData에서 파생 — 부모 스크립트가 configure() 호출.

const BEAM_LENGTH_DEFAULT: float = 160.0
const BODY_SIZE_DEFAULT: float = 24.0
const FOCUS_LENGTH_DEFAULT: float = 48.0
const FOCUS_WIDTH_DEFAULT: float = 24.0
const BEAM_BODY_HALF_DEFAULT: float = 12.0

const COLOR_FRAME_BASE := Color(0.55, 0.48, 0.29, 1.0)
const COLOR_CRYSTAL_BASE := Color(0.78, 0.92, 0.95, 1.0)
const COLOR_CRYSTAL_DEEP := Color(0.48, 0.66, 0.75, 1.0)
const COLOR_CRYSTAL_HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.85)
const COLOR_BEAM := Color(1.0, 0.92, 0.4, 0.22)
const COLOR_FOCUS_CORE := Color(1.0, 1.0, 0.65, 0.35)
const COLOR_FOCUS_RING := Color(1.0, 0.88, 0.45, 0.55)

const GLOW_PERIOD: float = 2.6

@export var sprite_path: String = ""

var _t: float = 0.0
var _beam_length: float = BEAM_LENGTH_DEFAULT
var _body_size: float = BODY_SIZE_DEFAULT
var _focus_length: float = FOCUS_LENGTH_DEFAULT
var _focus_width: float = FOCUS_WIDTH_DEFAULT
var _beam_body_half: float = BEAM_BODY_HALF_DEFAULT
var _sprite: Sprite2D


func _ready() -> void:
	_setup_sprite_fallback()


func _process(delta: float) -> void:
	_t += delta
	if _sprite == null or not _sprite.visible:
		queue_redraw()


func configure(
	beam_length: float,
	body_size: float,
	focus_length: float,
	focus_width: float,
	beam_body_half: float
) -> void:
	_beam_length = beam_length
	_body_size = body_size
	_focus_length = focus_length
	_focus_width = focus_width
	_beam_body_half = beam_body_half
	queue_redraw()


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	_draw_beam()
	_draw_focus_zone()
	_draw_crystal_body()


func _draw_beam() -> void:
	var focus_start: float = _beam_length - _focus_length
	var focus_half: float = _focus_width * 0.5
	var body_half: float = _beam_body_half
	var beam := PackedVector2Array(
		[
			Vector2(0, -body_half),
			Vector2(focus_start, -focus_half),
			Vector2(_beam_length, -focus_half),
			Vector2(_beam_length, focus_half),
			Vector2(focus_start, focus_half),
			Vector2(0, body_half),
		]
	)
	draw_colored_polygon(beam, COLOR_BEAM)


func _draw_focus_zone() -> void:
	var focus_start: float = _beam_length - _focus_length
	var focus_half: float = _focus_width * 0.5
	var pulse: float = 0.75 + 0.25 * sin(_t * TAU / GLOW_PERIOD)
	var core: Color = COLOR_FOCUS_CORE
	core.a *= pulse
	draw_rect(Rect2(focus_start, -focus_half, _focus_length, _focus_width), core, true)
	var ring: Color = COLOR_FOCUS_RING
	ring.a *= pulse
	draw_rect(
		Rect2(focus_start, -focus_half, _focus_length, _focus_width), ring, false, 1.0
	)


func _draw_crystal_body() -> void:
	var radius: float = _body_size * 0.5
	var segments: int = 12
	var points := PackedVector2Array()
	for i in range(segments):
		var theta: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(theta) * radius, sin(theta) * radius))
	draw_colored_polygon(points, COLOR_CRYSTAL_BASE)

	var deep_points := PackedVector2Array()
	var half_seg: int = int(segments / 2)
	for i in range(half_seg + 1):
		var idx: int = half_seg + i
		var theta: float = TAU * float(idx) / float(segments)
		deep_points.append(Vector2(cos(theta) * radius, sin(theta) * radius))
	deep_points.append(Vector2(0, 0))
	if deep_points.size() >= 3:
		draw_colored_polygon(deep_points, COLOR_CRYSTAL_DEEP)

	var border := points.duplicate()
	border.append(points[0])
	draw_polyline(border, COLOR_FRAME_BASE, 1.5, false)

	var shimmer: float = sin(_t * TAU / GLOW_PERIOD) * 1.5
	draw_arc(
		Vector2(-1, -1 + shimmer * 0.2),
		radius - 3.0,
		PI + 0.35,
		TAU - 0.5,
		12,
		COLOR_CRYSTAL_HIGHLIGHT,
		1.2,
		true
	)


func _setup_sprite_fallback() -> void:
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return
	var tex := load(sprite_path) as Texture2D
	if tex == null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "LensSprite"
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)

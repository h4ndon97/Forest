extends Node2D

## 차폐물 교보재 아트 - 고대 룬 코어 + 부유 파편 4.
## 스프라이트 모드: cover_rune.png 로드 시 활성. 각 파츠가 위상차 bob + 회전.
## Fallback: 스프라이트 부재 시 _draw로 단일 석판 교보재.

const WIDTH_DEFAULT: float = 24.0
const HEIGHT_DEFAULT: float = 64.0

# Fallback — 기존 교보재 색상
const COLOR_STONE_BASE := Color(0.40, 0.38, 0.35, 1.0)
const COLOR_STONE_HIGHLIGHT := Color(0.52, 0.50, 0.46, 1.0)
const COLOR_STONE_SHADOW := Color(0.24, 0.22, 0.20, 1.0)
const COLOR_CRACK := Color(0.14, 0.13, 0.12, 1.0)
const COLOR_MOSS_DARK := Color(0.20, 0.34, 0.18, 1.0)
const COLOR_MOSS_LIGHT := Color(0.36, 0.52, 0.28, 1.0)

# 룬 발광 (형광 하늘색) — 외곽 halo + 내부 룬 마크 글로우 2레이어
const GLOW_COLOR := Color(0.48, 0.87, 1.0, 1.0)
const GLOW_PERIOD: float = 2.8

# 외곽 halo — 방사형 그라디언트 타원 (실루엣 없음)
const GLOW_OUTER_WIDTH: int = 40
const GLOW_OUTER_HEIGHT: int = 80
const GLOW_OUTER_ALPHA_BASE: float = 0.35
const GLOW_OUTER_ALPHA_AMP: float = 0.25

# 내부 글로우 — 룬 마크 자체 발광 (RuneSprite 위에 덮어쓰기)
const GLOW_INNER_SCALE: float = 1.10
const GLOW_INNER_ALPHA_BASE: float = 0.25
const GLOW_INNER_ALPHA_AMP: float = 0.18
const GLOW_INNER_PHASE_OFFSET: float = PI * 0.25

# 모션 — 룬
const RUNE_AMP: float = 1.0
const RUNE_PERIOD: float = 3.6

# 모션 — 파편 (pos, amp, period, phase, rot_amp, rot_period)
# Fragment 1 — 좌상단 (좌우반전 ㄱ자 형태: 좌측 수직 + 상단 수평)
const FRAG1_POS := Vector2(-14.0, -14.0)
const FRAG1_AMP: float = 0.7
const FRAG1_PERIOD: float = 2.4
const FRAG1_PHASE: float = 0.0
const FRAG1_ROT_AMP: float = 0.008
const FRAG1_ROT_PERIOD: float = 3.3

# Fragment 2 — 우상단 (작은 크기 → 룬에 가깝게 배치)
const FRAG2_POS := Vector2(13.0, -17.0)
const FRAG2_AMP: float = 0.7
const FRAG2_PERIOD: float = 2.6
const FRAG2_PHASE: float = PI
const FRAG2_ROT_AMP: float = 0.010
const FRAG2_ROT_PERIOD: float = 3.1

# Fragment 3 — 좌하단
const FRAG3_POS := Vector2(-16.0, 17.0)
const FRAG3_AMP: float = 0.65
const FRAG3_PERIOD: float = 3.0
const FRAG3_PHASE: float = PI / 3.0
const FRAG3_ROT_AMP: float = 0.006
const FRAG3_ROT_PERIOD: float = 3.6

# Fragment 4 — 우하단
const FRAG4_POS := Vector2(13.0, 14.0)
const FRAG4_AMP: float = 0.7
const FRAG4_PERIOD: float = 2.8
const FRAG4_PHASE: float = PI * 1.4
const FRAG4_ROT_AMP: float = 0.008
const FRAG4_ROT_PERIOD: float = 3.4

const SPRITE_DIR := "res://assets/sprites/objects/cover/"

@export var sprite_path_rune: String = SPRITE_DIR + "cover_rune.png"
@export var sprite_path_fragment_1: String = SPRITE_DIR + "cover_fragment_1.png"
@export var sprite_path_fragment_2: String = SPRITE_DIR + "cover_fragment_2.png"
@export var sprite_path_fragment_3: String = SPRITE_DIR + "cover_fragment_3.png"
@export var sprite_path_fragment_4: String = SPRITE_DIR + "cover_fragment_4.png"

var _size: Vector2 = Vector2(WIDTH_DEFAULT, HEIGHT_DEFAULT)
var _t: float = 0.0
var _sprite_mode: bool = false

var _rune_anchor: Node2D
var _rune_glow_outer: Sprite2D
var _rune_glow_inner: Sprite2D
var _frag1_anchor: Node2D
var _frag2_anchor: Node2D
var _frag3_anchor: Node2D
var _frag4_anchor: Node2D


func _ready() -> void:
	_try_enter_sprite_mode()
	if not _sprite_mode:
		set_process(false)


func configure(size: Vector2) -> void:
	_size = size
	if not _sprite_mode:
		queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_update_rune()
	_update_fragment(
		_frag1_anchor,
		FRAG1_POS,
		FRAG1_AMP,
		FRAG1_PERIOD,
		FRAG1_PHASE,
		FRAG1_ROT_AMP,
		FRAG1_ROT_PERIOD
	)
	_update_fragment(
		_frag2_anchor,
		FRAG2_POS,
		FRAG2_AMP,
		FRAG2_PERIOD,
		FRAG2_PHASE,
		FRAG2_ROT_AMP,
		FRAG2_ROT_PERIOD
	)
	_update_fragment(
		_frag3_anchor,
		FRAG3_POS,
		FRAG3_AMP,
		FRAG3_PERIOD,
		FRAG3_PHASE,
		FRAG3_ROT_AMP,
		FRAG3_ROT_PERIOD
	)
	_update_fragment(
		_frag4_anchor,
		FRAG4_POS,
		FRAG4_AMP,
		FRAG4_PERIOD,
		FRAG4_PHASE,
		FRAG4_ROT_AMP,
		FRAG4_ROT_PERIOD
	)


func _update_rune() -> void:
	if _rune_anchor == null:
		return
	var phase: float = _t * TAU / RUNE_PERIOD
	_rune_anchor.position = Vector2(0.0, sin(phase) * RUNE_AMP)
	var glow_phase: float = _t * TAU / GLOW_PERIOD
	if _rune_glow_outer != null:
		var outer_a: float = GLOW_OUTER_ALPHA_BASE + GLOW_OUTER_ALPHA_AMP * sin(glow_phase)
		_rune_glow_outer.modulate.a = clampf(outer_a, 0.0, 1.0)
	if _rune_glow_inner != null:
		var inner_a: float = (
			GLOW_INNER_ALPHA_BASE + GLOW_INNER_ALPHA_AMP * sin(glow_phase + GLOW_INNER_PHASE_OFFSET)
		)
		_rune_glow_inner.modulate.a = clampf(inner_a, 0.0, 1.0)


func _update_fragment(
	anchor: Node2D,
	base_pos: Vector2,
	amp: float,
	period: float,
	phase: float,
	rot_amp: float,
	rot_period: float
) -> void:
	if anchor == null:
		return
	var bob_phase: float = _t * TAU / period + phase
	anchor.position = base_pos + Vector2(0.0, sin(bob_phase) * amp)
	var rot_phase: float = _t * TAU / rot_period + phase * 0.5
	anchor.rotation = sin(rot_phase) * rot_amp


# --- Sprite mode setup ---


func _try_enter_sprite_mode() -> void:
	var rune_tex: Texture2D = _load_tex(sprite_path_rune)
	if rune_tex == null:
		return
	_sprite_mode = true
	_build_rune(rune_tex)
	_frag1_anchor = _build_fragment(FRAG1_POS, sprite_path_fragment_1)
	_frag2_anchor = _build_fragment(FRAG2_POS, sprite_path_fragment_2)
	_frag3_anchor = _build_fragment(FRAG3_POS, sprite_path_fragment_3)
	_frag4_anchor = _build_fragment(FRAG4_POS, sprite_path_fragment_4)


func _load_tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _build_rune(tex: Texture2D) -> void:
	_rune_anchor = Node2D.new()
	_rune_anchor.name = "RuneAnchor"
	add_child(_rune_anchor)

	# 1. 외곽 halo — 방사형 그라디언트 타원 (맨 뒤)
	_rune_glow_outer = _make_radial_glow()
	_rune_anchor.add_child(_rune_glow_outer)

	# 2. 룬 스프라이트 (중간, 선명)
	var rune_sprite := Sprite2D.new()
	rune_sprite.name = "RuneSprite"
	rune_sprite.texture = tex
	rune_sprite.centered = true
	_rune_anchor.add_child(rune_sprite)

	# 3. 내부 글로우 — 룬 마크 자체를 밝힘 (최상단, additive)
	_rune_glow_inner = _make_texture_glow(tex, "RuneGlowInner", GLOW_INNER_SCALE)
	_rune_anchor.add_child(_rune_glow_inner)


func _make_radial_glow() -> Sprite2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray(
		[Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.30), Color(1.0, 1.0, 1.0, 0.0)]
	)
	var gtex := GradientTexture2D.new()
	gtex.gradient = gradient
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	gtex.width = GLOW_OUTER_WIDTH
	gtex.height = GLOW_OUTER_HEIGHT

	var spr := Sprite2D.new()
	spr.name = "RuneGlowOuter"
	spr.texture = gtex
	spr.centered = true
	spr.modulate = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	return spr


func _make_texture_glow(tex: Texture2D, node_name: String, scale_value: float) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.name = node_name
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2(scale_value, scale_value)
	spr.modulate = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, 0.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	return spr


func _build_fragment(base_pos: Vector2, path: String) -> Node2D:
	var anchor := Node2D.new()
	anchor.name = "FragmentAnchor"
	anchor.position = base_pos
	add_child(anchor)
	var tex: Texture2D = _load_tex(path)
	if tex == null:
		return anchor
	var spr := Sprite2D.new()
	spr.name = "FragmentSprite"
	spr.texture = tex
	spr.centered = true
	anchor.add_child(spr)
	return anchor


# --- Fallback _draw (스프라이트 부재 시 단일 석판 교보재) ---


func _draw() -> void:
	if _sprite_mode:
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
	draw_rect(Rect2(half_w - 1.5, -half_h, 1.5, _size.y), COLOR_STONE_SHADOW, true)
	draw_rect(Rect2(-half_w, half_h - 1.5, _size.x, 1.5), COLOR_STONE_SHADOW, true)


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
		draw_rect(Rect2(x - 2.0, -half_h - 1.0, 4.0, moss_h + bump), COLOR_MOSS_DARK, true)
	for i in range(3):
		var x: float = lerpf(-half_w + 4.0, half_w - 4.0, (float(i) + 0.5) / 3.0)
		draw_circle(Vector2(x, -half_h + moss_h * 0.5), 1.3, COLOR_MOSS_LIGHT)
	draw_circle(Vector2(-half_w + 3.0, half_h - 2.0), 2.0, COLOR_MOSS_DARK)
	draw_circle(Vector2(half_w - 4.0, half_h - 3.0), 1.8, COLOR_MOSS_DARK)

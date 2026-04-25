extends Control

## B-6 일식 링 전용 렌더러 — child Control + ShaderMaterial로 글로우 + 아크 마스크 처리.
## time_core_renderer가 child로 추가하고 update_state()로 동기화.
## Pass 1.5 코드 draw_arc 기반 마스킹을 셰이더로 격상 (Phase 4-0 / Pass 5).

const RING_SPRITE_PATH := "res://assets/ui/hud/hud_time_gauge_ring.png"
const SHADOW_SPRITE_PATH := "res://assets/ui/hud/hud_time_gauge_shadow.png"
const WARNING_SPRITE_PATH := "res://assets/ui/hud/hud_time_gauge_warning.png"
const SHADER_PATH := "res://assets/shaders/effects/hud_eclipse_ring.gdshader"

const CENTER_X: float = 595.0
const CENTER_Y: float = 45.0
const ECLIPSE_RADIUS: float = 40.0
const ECLIPSE_THICKNESS: float = 6.0
const COLOR_ECLIPSE_SHADOW := Color(0.2, 0.2, 0.25, 0.85)
const COLOR_ECLIPSE_FALLBACK := Color(0.949, 0.8, 0.4, 1.0)

const LOW_RESOURCE_THRESHOLD: float = 0.2
const LOW_RESOURCE_PERIOD: float = 0.8

var resource_ratio: float = 1.0
var ring_alpha: float = 1.0

var _ring_tex: Texture2D
var _shadow_tex: Texture2D
var _warning_tex: Texture2D
var _material: ShaderMaterial
var _pulse_t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true  # B-5 시계·해·달이 위에 그려지도록
	_setup_material()
	_load_textures()


func _setup_material() -> void:
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		return
	_material = ShaderMaterial.new()
	_material.shader = shader
	material = _material


func _load_textures() -> void:
	if ResourceLoader.exists(RING_SPRITE_PATH):
		_ring_tex = load(RING_SPRITE_PATH) as Texture2D
	if ResourceLoader.exists(SHADOW_SPRITE_PATH):
		_shadow_tex = load(SHADOW_SPRITE_PATH) as Texture2D
		if _material != null:
			_material.set_shader_parameter("shadow_tex", _shadow_tex)
			_material.set_shader_parameter("has_shadow_tex", true)
	if ResourceLoader.exists(WARNING_SPRITE_PATH):
		_warning_tex = load(WARNING_SPRITE_PATH) as Texture2D


func _process(delta: float) -> void:
	_pulse_t += delta
	if resource_ratio > 0.0 and resource_ratio < LOW_RESOURCE_THRESHOLD:
		queue_redraw()  # warning 펄스 유지


func _draw() -> void:
	if _ring_tex == null:
		_draw_fallback()
		return
	if material == null and _material != null:
		material = _material
	if _material != null:
		_material.set_shader_parameter("resource_ratio", resource_ratio)
	var center := Vector2(CENTER_X, CENTER_Y)
	var ring_top: Vector2 = center - _ring_tex.get_size() * 0.5
	draw_texture(_ring_tex, ring_top, Color(1.0, 1.0, 1.0, ring_alpha))
	if _warning_tex != null and _is_warning_active():
		var pulse: float = 0.5 + 0.5 * sin(_pulse_t * TAU / LOW_RESOURCE_PERIOD)
		var warn_top: Vector2 = center - _warning_tex.get_size() * 0.5
		draw_texture(_warning_tex, warn_top, Color(1.0, 1.0, 1.0, pulse * ring_alpha))


func _is_warning_active() -> bool:
	return resource_ratio > 0.0 and resource_ratio < LOW_RESOURCE_THRESHOLD


func _draw_fallback() -> void:
	# PNG 없을 때 도형 기반 fallback (셰이더 비활성, 단순 호 렌더).
	material = null
	var center := Vector2(CENTER_X, CENTER_Y)
	draw_arc(center, ECLIPSE_RADIUS, 0.0, TAU, 64, COLOR_ECLIPSE_SHADOW, ECLIPSE_THICKNESS, false)
	if resource_ratio <= 0.0:
		return
	var start_angle: float = -PI / 2.0
	var end_angle: float = start_angle + resource_ratio * TAU
	var fill_color := COLOR_ECLIPSE_FALLBACK
	fill_color.a = ring_alpha
	draw_arc(
		center, ECLIPSE_RADIUS, start_angle, end_angle, 64, fill_color, ECLIPSE_THICKNESS, false
	)


func update_state(p_resource_ratio: float, p_alpha: float) -> void:
	resource_ratio = p_resource_ratio
	ring_alpha = p_alpha
	queue_redraw()

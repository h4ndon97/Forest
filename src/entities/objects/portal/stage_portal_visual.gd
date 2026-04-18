extends Node2D

## 스테이지 포탈 세로 빛 기둥 프로그래밍 아트.
## portals_checkpoints.md §2 준수.
## sprite_path가 설정되고 리소스 존재 시 Sprite2D로 폴백 전환.

const PILLAR_HEIGHT: float = 360.0
const PILLAR_HALF: float = 180.0
const AURA_WIDTH: float = 32.0
const MID_WIDTH: float = 16.0
const CORE_WIDTH: float = 2.0
const BOTTOM_FADE: float = 80.0

const COLOR_AURA := Color(0.949, 0.8, 0.4, 0.15)
const COLOR_MID := Color(0.949, 0.8, 0.4, 0.45)
const COLOR_CORE := Color(1.0, 0.957, 0.8, 0.9)

const PULSE_PERIOD: float = 2.4
const PULSE_AMPLITUDE: float = 0.15
const NEAR_PULSE_PERIOD: float = 1.2
const NEAR_CORE_SCALE: float = 1.5

const PARTICLE_COUNT: int = 4
const PARTICLE_PERIOD: float = 3.2

@export var sprite_path: String = ""

var player_nearby: bool = false

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

	var pulse_period: float = NEAR_PULSE_PERIOD if player_nearby else PULSE_PERIOD
	var pulse: float = 0.5 + 0.5 * sin(_t * TAU / pulse_period)
	var core_w: float = CORE_WIDTH * (NEAR_CORE_SCALE if player_nearby else 1.0)
	var core_alpha_mul: float = lerpf(1.0 - PULSE_AMPLITUDE, 1.0, pulse)

	_draw_vertical_band(AURA_WIDTH, COLOR_AURA, 1.0)
	_draw_vertical_band(MID_WIDTH, COLOR_MID, 1.0)
	_draw_vertical_band(core_w, COLOR_CORE, core_alpha_mul)

	_draw_particles()


func _draw_vertical_band(width: float, color: Color, alpha_mul: float) -> void:
	var half: float = width * 0.5
	var segments: int = 18
	for i in segments:
		var t0: float = float(i) / segments
		var t1: float = float(i + 1) / segments
		var y0: float = -PILLAR_HALF + t0 * PILLAR_HEIGHT
		var y1: float = -PILLAR_HALF + t1 * PILLAR_HEIGHT
		var fade: float = _fade_for_y((y0 + y1) * 0.5)
		var c: Color = color
		c.a *= fade * alpha_mul
		draw_rect(Rect2(-half, y0, width, y1 - y0), c, true)


func _fade_for_y(y: float) -> float:
	var from_bottom: float = PILLAR_HALF - y
	if from_bottom < BOTTOM_FADE:
		return clampf(from_bottom / BOTTOM_FADE, 0.0, 1.0)
	var from_top: float = y + PILLAR_HALF
	if from_top < 24.0:
		return clampf(from_top / 24.0, 0.0, 1.0)
	return 1.0


func _draw_particles() -> void:
	for i in PARTICLE_COUNT:
		var phase: float = float(i) / PARTICLE_COUNT
		var tt: float = fmod(_t / PARTICLE_PERIOD + phase, 1.0)
		var y: float = PILLAR_HALF - 40.0 - tt * (PILLAR_HEIGHT - 80.0)
		var alpha_env: float = sin(tt * PI)
		var x: float = sin((tt + phase) * TAU) * 3.0
		var r: float = 1.0 + 0.5 * sin((tt + phase) * TAU * 2.0)
		var c: Color = COLOR_CORE
		c.a *= alpha_env
		draw_circle(Vector2(x, y), r, c)


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

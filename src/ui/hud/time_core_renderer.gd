extends Control

## B-5 궤도 시계 + B-6 일식 링 + B-7 전파 배지 드로잉 (time_hud.gd가 queue_redraw 호출).
## 명세: ui_design_master.md §B-5/B-6/B-7, UI_IMPLEMENTATION_PLAN.md §1.4.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

const CENTER_X: float = 595.0
const CENTER_Y: float = 45.0
const BADGE_CENTER_Y: float = 95.0  # 시계 코어 하단 여백 (80×80 일식 링 정합)

const ECLIPSE_RADIUS: float = 40.0
const ECLIPSE_THICKNESS: float = 6.0
const CLOCK_RADIUS: float = 32.0
const CLOCK_THICKNESS: float = 4.0
const ORBIT_RADIUS: float = 21.0
const SUN_MOON_RADIUS: float = 7.0
const BADGE_DOT_RADIUS: float = 3.0
const BADGE_DOT_SPACING: float = 5.5

const COLOR_ECLIPSE_FULL := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66
const COLOR_ECLIPSE_SHADOW := Color(0.2, 0.2, 0.25, 0.85)
const COLOR_CLOCK_FLOWING := Color(0.949, 0.8, 0.4, 1.0)
const COLOR_CLOCK_STOPPED := Color(0.55, 0.55, 0.6, 0.7)
const COLOR_CLOCK_MANIPULATING := Color(0.3, 0.5, 1.0, 1.0)
const COLOR_SUN := Color(1.0, 0.9, 0.5, 1.0)
const COLOR_MOON := Color(0.75, 0.7, 0.9, 1.0)
const COLOR_BADGE_ORIGIN := Color(0.949, 0.8, 0.4, 1.0)
const COLOR_BADGE_PROPAGATED := Color(0.545, 0.184, 0.776, 1.0)  # #8B2FC6
const COLOR_LOW_RESOURCE_PULSE := Color(0.9, 0.3, 0.3, 1.0)  # Pass 2용 참조

const LOW_RESOURCE_THRESHOLD: float = 0.2
const DIM_ALPHA_STOPPED: float = 0.5

# A-10/B-5 펄스 (§2.3): FLOWING 호흡 1.0s, 저자원(<20%) 0.8s 맥동 — A-7과 리듬 동조
const BREATH_PERIOD: float = 1.0
const BREATH_AMPLITUDE: float = 0.05
const LOW_RESOURCE_PERIOD: float = 0.8

# B-5 스프라이트 드롭인 (파일 없으면 도형 fallback 유지)
const RING_SPRITE_PATH := "res://assets/ui/hud/hud_time_clock_ring.png"
const SUN_SPRITE_PATH := "res://assets/ui/hud/hud_time_sun.png"
const MOON_SPRITE_PATH := "res://assets/ui/hud/hud_time_moon.png"
const ORBIT_FRAME_SIZE: int = 32
const ORBIT_FRAME_PERIOD: float = 0.25  # 4 × 0.25s = 1.0s 루프, BREATH_PERIOD와 동조

# B-6 일식 링 스프라이트 드롭인 (Pass 1.5: ring PNG + 코드 shadow 아크 + warning PNG)
const GAUGE_RING_SPRITE_PATH := "res://assets/ui/hud/hud_time_gauge_ring.png"
const GAUGE_SHADOW_SPRITE_PATH := "res://assets/ui/hud/hud_time_gauge_shadow.png"
const GAUGE_WARNING_SPRITE_PATH := "res://assets/ui/hud/hud_time_gauge_warning.png"

# B-5 폴리시: STOPPED 펄스 / 낮↔밤 전환 플래시 / 단판 호흡
const STOPPED_PULSE_PERIOD: float = 1.0
const STOPPED_PULSE_ALPHA_MIN: float = 0.55
const STOPPED_PULSE_ALPHA_MAX: float = 0.75
const FLASH_DURATION: float = 0.3
const FLASH_INTENSITY: float = 0.7
const ORBIT_BREATH_ALPHA_MIN: float = 0.7
const COLOR_FLASH_GOLD := Color(0.949, 0.8, 0.4, 1.0)  # 밤→낮 (해 상단 도달)
const COLOR_FLASH_PURPLE := Color(0.545, 0.184, 0.776, 1.0)  # 낮→밤 (해 하단 도달)

var hour_value: float = 12.0
var time_state: int = TimeStateMachine.TimeState.STOPPED
var resource_ratio: float = 1.0
var is_origin: bool = false
var flow_rate: float = 1.0

var _pulse_t: float = 0.0
var _ring_tex: Texture2D
var _sun_tex: Texture2D
var _moon_tex: Texture2D
var _gauge_ring_tex: Texture2D
var _gauge_shadow_tex: Texture2D
var _gauge_warning_tex: Texture2D
var _prev_hour: float = -1.0
var _flash_t: float = 0.0
var _flash_color: Color = COLOR_FLASH_GOLD


func _ready() -> void:
	_load_clock_sprites()


func _load_clock_sprites() -> void:
	if ResourceLoader.exists(RING_SPRITE_PATH):
		_ring_tex = load(RING_SPRITE_PATH) as Texture2D
	if ResourceLoader.exists(SUN_SPRITE_PATH):
		_sun_tex = load(SUN_SPRITE_PATH) as Texture2D
	if ResourceLoader.exists(MOON_SPRITE_PATH):
		_moon_tex = load(MOON_SPRITE_PATH) as Texture2D
	if ResourceLoader.exists(GAUGE_RING_SPRITE_PATH):
		_gauge_ring_tex = load(GAUGE_RING_SPRITE_PATH) as Texture2D
	if ResourceLoader.exists(GAUGE_SHADOW_SPRITE_PATH):
		_gauge_shadow_tex = load(GAUGE_SHADOW_SPRITE_PATH) as Texture2D
	if ResourceLoader.exists(GAUGE_WARNING_SPRITE_PATH):
		_gauge_warning_tex = load(GAUGE_WARNING_SPRITE_PATH) as Texture2D


func _process(delta: float) -> void:
	_pulse_t += delta
	_check_day_night_flash()
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - delta)
	if _needs_animated_redraw():
		queue_redraw()


func _check_day_night_flash() -> void:
	# 해가 상단 도달(hour=12) = 밤→낮 금색 / 하단 도달(hour 24→0 랩) = 낮→밤 보라.
	if _prev_hour < 0.0:
		_prev_hour = hour_value
		return
	if _prev_hour < 12.0 and hour_value >= 12.0:
		_trigger_flash(COLOR_FLASH_GOLD)
	elif _prev_hour > 20.0 and hour_value < 4.0:
		_trigger_flash(COLOR_FLASH_PURPLE)
	_prev_hour = hour_value


func _trigger_flash(color: Color) -> void:
	_flash_t = FLASH_DURATION
	_flash_color = color


func _needs_animated_redraw() -> bool:
	if resource_ratio > 0.0 and resource_ratio < LOW_RESOURCE_THRESHOLD:
		return true
	if time_state == TimeStateMachine.TimeState.FLOWING and resource_ratio > 0.0:
		return true
	if time_state == TimeStateMachine.TimeState.STOPPED:
		return true  # STOPPED 링 미세 펄스
	if _flash_t > 0.0:
		return true
	return (
		_sun_tex != null
		or _moon_tex != null
		or _gauge_ring_tex != null
		or _gauge_warning_tex != null
	)


func _draw() -> void:
	_draw_eclipse_ring()
	_draw_clock_ring()
	_draw_sun_moon()
	_draw_badge()


func _draw_eclipse_ring() -> void:
	var center := Vector2(CENTER_X, CENTER_Y)
	# PNG 모드: ring PNG를 베이스로 깔고 소모 구간에 code shadow 아크 덮기 (Pass 1.5 — 셰이더 도입은 Pass 2).
	if _gauge_ring_tex != null:
		_draw_eclipse_ring_png(center)
		_draw_eclipse_warning_overlay(center)
		return
	draw_arc(center, ECLIPSE_RADIUS, 0.0, TAU, 64, COLOR_ECLIPSE_SHADOW, ECLIPSE_THICKNESS, false)
	if resource_ratio <= 0.0:
		return
	var start_angle: float = -PI / 2.0
	var end_angle: float = start_angle + resource_ratio * TAU
	var fill_color: Color = _eclipse_fill_color()
	draw_arc(
		center, ECLIPSE_RADIUS, start_angle, end_angle, 64, fill_color, ECLIPSE_THICKNESS, false
	)


func _draw_eclipse_ring_png(center: Vector2) -> void:
	var top_left: Vector2 = center - _gauge_ring_tex.get_size() * 0.5
	draw_texture(_gauge_ring_tex, top_left, _eclipse_fill_color())
	if resource_ratio >= 1.0:
		return
	# 소모 구간 (시계방향 12시부터 역방향) 을 shadow로 마스킹. 해상도 = 소모 비율에 비례.
	var consumed_start: float = -PI / 2.0 + resource_ratio * TAU
	var consumed_end: float = -PI / 2.0 + TAU
	var segments: int = maxi(4, int(64.0 * (1.0 - resource_ratio)))
	draw_arc(
		center,
		ECLIPSE_RADIUS,
		consumed_start,
		consumed_end,
		segments,
		COLOR_ECLIPSE_SHADOW,
		ECLIPSE_THICKNESS + 1.0,
		false
	)


func _draw_eclipse_warning_overlay(center: Vector2) -> void:
	if _gauge_warning_tex == null:
		return
	if resource_ratio <= 0.0 or resource_ratio >= LOW_RESOURCE_THRESHOLD:
		return
	var pulse: float = 0.5 + 0.5 * sin(_pulse_t * TAU / LOW_RESOURCE_PERIOD)
	var tint := Color(1.0, 1.0, 1.0, pulse)
	var top_left: Vector2 = center - _gauge_warning_tex.get_size() * 0.5
	draw_texture(_gauge_warning_tex, top_left, tint)


func _eclipse_fill_color() -> Color:
	if resource_ratio < LOW_RESOURCE_THRESHOLD:
		var k: float = 0.5 + 0.5 * sin(_pulse_t * TAU / LOW_RESOURCE_PERIOD)
		return COLOR_ECLIPSE_FULL.lerp(COLOR_LOW_RESOURCE_PULSE, k)
	if time_state == TimeStateMachine.TimeState.STOPPED:
		var dimmed := COLOR_ECLIPSE_FULL
		dimmed.a *= DIM_ALPHA_STOPPED
		return dimmed
	if time_state == TimeStateMachine.TimeState.FLOWING:
		var breath: float = 0.5 + 0.5 * sin(_pulse_t * TAU / BREATH_PERIOD)
		var pulsed := COLOR_ECLIPSE_FULL
		pulsed.a = lerpf(1.0 - BREATH_AMPLITUDE, 1.0, breath)
		return pulsed
	return COLOR_ECLIPSE_FULL


func _draw_clock_ring() -> void:
	var center := Vector2(CENTER_X, CENTER_Y)
	var color: Color = _clock_color_for_state()
	if _ring_tex != null:
		var top_left: Vector2 = center - _ring_tex.get_size() * 0.5
		draw_texture(_ring_tex, top_left, color)
		return
	draw_arc(center, CLOCK_RADIUS, 0.0, TAU, 48, color, CLOCK_THICKNESS, false)


func _clock_color_for_state() -> Color:
	var base: Color
	match time_state:
		TimeStateMachine.TimeState.FLOWING:
			base = COLOR_CLOCK_FLOWING
		TimeStateMachine.TimeState.MANIPULATING:
			base = COLOR_CLOCK_MANIPULATING
		_:
			base = COLOR_CLOCK_STOPPED
			var breath: float = 0.5 + 0.5 * sin(_pulse_t * TAU / STOPPED_PULSE_PERIOD)
			base.a = lerpf(STOPPED_PULSE_ALPHA_MIN, STOPPED_PULSE_ALPHA_MAX, breath)
	if _flash_t > 0.0:
		var k: float = (_flash_t / FLASH_DURATION) * FLASH_INTENSITY
		base = base.lerp(_flash_color, k)
	return base


func _draw_sun_moon() -> void:
	var center := Vector2(CENTER_X, CENTER_Y)
	var sun_angle: float = PI / 2.0 - (hour_value / 24.0) * TAU
	var moon_angle: float = sun_angle + PI
	var sun_pos: Vector2 = center + Vector2(cos(sun_angle), sin(sun_angle)) * ORBIT_RADIUS
	var moon_pos: Vector2 = center + Vector2(cos(moon_angle), sin(moon_angle)) * ORBIT_RADIUS
	_draw_orbit_body(_sun_tex, sun_pos, COLOR_SUN)
	_draw_orbit_body(_moon_tex, moon_pos, COLOR_MOON)


func _draw_orbit_body(tex: Texture2D, pos: Vector2, fallback_color: Color) -> void:
	if tex == null:
		draw_circle(pos, SUN_MOON_RADIUS, fallback_color)
		return
	var frame_count: int = maxi(1, tex.get_width() / ORBIT_FRAME_SIZE)
	var frame: int = int(_pulse_t / ORBIT_FRAME_PERIOD) % frame_count
	var region := Rect2(
		Vector2(frame * ORBIT_FRAME_SIZE, 0), Vector2(ORBIT_FRAME_SIZE, ORBIT_FRAME_SIZE)
	)
	var dst := Rect2(
		pos - Vector2(ORBIT_FRAME_SIZE, ORBIT_FRAME_SIZE) * 0.5,
		Vector2(ORBIT_FRAME_SIZE, ORBIT_FRAME_SIZE)
	)
	# 단판(1프레임) 제공 시 코드가 알파 호흡 펄스로 "발광 루프" 보완.
	var tint := Color.WHITE
	if frame_count == 1:
		var breath: float = 0.5 + 0.5 * sin(_pulse_t * TAU / BREATH_PERIOD)
		tint.a = lerpf(ORBIT_BREATH_ALPHA_MIN, 1.0, breath)
	draw_texture_rect_region(tex, dst, region, tint)


func _draw_badge() -> void:
	var dot_count: int = 0
	var dot_color: Color = COLOR_BADGE_ORIGIN
	if is_origin:
		dot_count = 1
		dot_color = COLOR_BADGE_ORIGIN
	elif flow_rate < 0.999:
		dot_count = _rate_to_dot_count(flow_rate)
		dot_color = COLOR_BADGE_PROPAGATED

	if dot_count <= 0:
		return

	var total_width: float = (dot_count - 1) * BADGE_DOT_SPACING
	var start_x: float = CENTER_X - total_width / 2.0
	for i in dot_count:
		var dot_pos := Vector2(start_x + i * BADGE_DOT_SPACING, BADGE_CENTER_Y)
		draw_circle(dot_pos, BADGE_DOT_RADIUS, dot_color)


func _rate_to_dot_count(rate: float) -> int:
	if rate >= 0.5 - 0.01:
		return 2
	if rate >= 0.25 - 0.01:
		return 3
	if rate >= 0.125 - 0.01:
		return 4
	return 0

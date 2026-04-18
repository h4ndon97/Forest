extends Control

## B-5 궤도 시계 + B-6 일식 링 + B-7 전파 배지 드로잉.
## time_hud.gd가 상태 변수를 갱신한 후 queue_redraw()를 호출한다.
## ui_design_master.md §B-5/B-6/B-7 / UI_IMPLEMENTATION_PLAN.md §1.4.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

const CENTER_X: float = 608.0
const CENTER_Y: float = 32.0
const BADGE_CENTER_Y: float = 62.0  # 시계 코어 하단 5px 여백 (Issue 3 해결)

const ECLIPSE_RADIUS: float = 20.0
const ECLIPSE_THICKNESS: float = 3.0
const CLOCK_RADIUS: float = 14.0
const CLOCK_THICKNESS: float = 2.0
const ORBIT_RADIUS: float = 10.0
const SUN_MOON_RADIUS: float = 3.0
const BADGE_DOT_RADIUS: float = 1.5
const BADGE_DOT_SPACING: float = 3.0

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

var hour_value: float = 12.0
var time_state: int = TimeStateMachine.TimeState.STOPPED
var resource_ratio: float = 1.0
var is_origin: bool = false
var flow_rate: float = 1.0

var _pulse_t: float = 0.0


func _process(delta: float) -> void:
	_pulse_t += delta
	if _needs_animated_redraw():
		queue_redraw()


func _needs_animated_redraw() -> bool:
	if resource_ratio > 0.0 and resource_ratio < LOW_RESOURCE_THRESHOLD:
		return true
	if time_state == TimeStateMachine.TimeState.FLOWING and resource_ratio > 0.0:
		return true
	return false


func _draw() -> void:
	_draw_eclipse_ring()
	_draw_clock_ring()
	_draw_sun_moon()
	_draw_badge()


func _draw_eclipse_ring() -> void:
	var center := Vector2(CENTER_X, CENTER_Y)
	draw_arc(center, ECLIPSE_RADIUS, 0.0, TAU, 64, COLOR_ECLIPSE_SHADOW, ECLIPSE_THICKNESS, false)
	if resource_ratio <= 0.0:
		return
	var start_angle: float = -PI / 2.0
	var end_angle: float = start_angle + resource_ratio * TAU
	var fill_color: Color = _eclipse_fill_color()
	draw_arc(
		center, ECLIPSE_RADIUS, start_angle, end_angle, 64, fill_color, ECLIPSE_THICKNESS, false
	)


func _eclipse_fill_color() -> Color:
	# 저자원 > STOPPED dim > FLOWING 호흡 > 기본(FULL).
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
	draw_arc(center, CLOCK_RADIUS, 0.0, TAU, 48, color, CLOCK_THICKNESS, false)


func _clock_color_for_state() -> Color:
	match time_state:
		TimeStateMachine.TimeState.FLOWING:
			return COLOR_CLOCK_FLOWING
		TimeStateMachine.TimeState.MANIPULATING:
			return COLOR_CLOCK_MANIPULATING
		_:
			return COLOR_CLOCK_STOPPED


func _draw_sun_moon() -> void:
	var center := Vector2(CENTER_X, CENTER_Y)
	var sun_angle: float = PI / 2.0 - (hour_value / 24.0) * TAU
	var moon_angle: float = sun_angle + PI
	var sun_pos: Vector2 = center + Vector2(cos(sun_angle), sin(sun_angle)) * ORBIT_RADIUS
	var moon_pos: Vector2 = center + Vector2(cos(moon_angle), sin(moon_angle)) * ORBIT_RADIUS
	draw_circle(sun_pos, SUN_MOON_RADIUS, COLOR_SUN)
	draw_circle(moon_pos, SUN_MOON_RADIUS, COLOR_MOON)


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

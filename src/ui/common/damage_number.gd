extends Node2D

## 플로팅 데미지 숫자 (D7-4 사양).
## 티어:
##   - 일반       : 흰색, 12px
##   - 크리티컬    : 노랑, 14px, scale 1.4 오버슛 Tween
##   - 피니시      : 속성색(light/shadow/hybrid), 14px, 가로 쉐이크
## 폰트: Galmuri11 (프로젝트 UI 일관성). 아웃라인: shadow offset 1px.
## 생성 후 위로 떠오르며 페이드아웃되고 자동 제거된다.

const FONT_PATH: String = "res://assets/fonts/galmuri/Galmuri11.ttf"
const FLOAT_DISTANCE: float = 24.0
const DURATION: float = 0.6
const FONT_SIZE_NORMAL: int = 12
const FONT_SIZE_STRONG: int = 14
const COLOR_NORMAL := Color(1.0, 1.0, 1.0)
const COLOR_CRITICAL := Color(1.0, 0.92, 0.35)
const SHADOW_OFFSET := Vector2(1, 1)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.85)
const CRITICAL_POP_SCALE: float = 1.4
const CRITICAL_POP_TIME: float = 0.12
const FINISH_SHAKE_AMP: float = 2.0
const FINISH_SHAKE_PERIOD: float = 0.06
const FINISH_SHAKE_TIME: float = 0.24

static var _font_cache: FontFile = null

var _label: Label
var _shake_anchor: Node2D
var _finish_shake_t: float = 0.0
var _finish_shake_base: Vector2 = Vector2.ZERO


func setup(
	amount: float, is_finish: bool = false, is_critical: bool = false, finish_attribute: String = ""
) -> void:
	_shake_anchor = Node2D.new()
	add_child(_shake_anchor)

	_label = Label.new()
	_label.text = str(int(amount))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var is_strong: bool = is_finish or is_critical
	var font_size: int = FONT_SIZE_STRONG if is_strong else FONT_SIZE_NORMAL
	var font_color: Color = _resolve_color(is_finish, is_critical, finish_attribute)
	_label.label_settings = _build_label_settings(font_size, font_color)

	_label.position = Vector2(-20, -10)
	_label.size = Vector2(40, 20)
	_shake_anchor.add_child(_label)

	position.x += randf_range(-6.0, 6.0)

	var float_tween: Tween = create_tween()
	float_tween.set_parallel(true)
	float_tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, DURATION)
	float_tween.tween_property(_label, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.4)
	float_tween.chain().tween_callback(queue_free)

	if is_critical and not is_finish:
		_play_critical_pop()
	if is_finish:
		_start_finish_shake()


func _resolve_color(is_finish: bool, is_critical: bool, finish_attribute: String) -> Color:
	if is_finish and finish_attribute != "" and EffectsSystem:
		var c: Color = EffectsSystem.get_finish_color(finish_attribute)
		# get_finish_color는 HDR(2.x) 값을 반환할 수 있으므로 LDR로 클램프.
		return Color(minf(c.r, 1.0), minf(c.g, 1.0), minf(c.b, 1.0), 1.0)
	if is_critical:
		return COLOR_CRITICAL
	return COLOR_NORMAL


func _build_label_settings(font_size: int, font_color: Color) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = _get_font()
	settings.font_size = font_size
	settings.font_color = font_color
	settings.shadow_color = SHADOW_COLOR
	settings.shadow_offset = SHADOW_OFFSET
	settings.shadow_size = 0
	return settings


func _get_font() -> FontFile:
	if _font_cache == null and ResourceLoader.exists(FONT_PATH):
		_font_cache = load(FONT_PATH) as FontFile
	return _font_cache


func _play_critical_pop() -> void:
	_shake_anchor.scale = Vector2(CRITICAL_POP_SCALE, CRITICAL_POP_SCALE)
	var pop_tween: Tween = create_tween()
	(
		pop_tween
		. tween_property(_shake_anchor, "scale", Vector2.ONE, CRITICAL_POP_TIME)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


func _start_finish_shake() -> void:
	set_process(true)
	_finish_shake_t = 0.0
	_finish_shake_base = _label.position


func _process(delta: float) -> void:
	if _shake_anchor == null or _label == null:
		return
	_finish_shake_t += delta
	if _finish_shake_t >= FINISH_SHAKE_TIME:
		_label.position = _finish_shake_base
		set_process(false)
		return
	var phase: float = _finish_shake_t / FINISH_SHAKE_PERIOD * TAU
	var decay: float = 1.0 - (_finish_shake_t / FINISH_SHAKE_TIME)
	var offset_x: float = sin(phase) * FINISH_SHAKE_AMP * decay
	_label.position = _finish_shake_base + Vector2(offset_x, 0.0)

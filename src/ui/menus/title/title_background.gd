extends Node

## 타이틀 배경 렌더.
## title_bg.png가 있으면 Sprite2D로 표시, 없으면 ColorRect + 반딧불 점멸로 fallback.
## Phase 3-7에서 리소스 드롭 시 코드 수정 없이 자동 반영.

const BG_PATH := "res://assets/ui/meta/title/title_bg.png"
const COLOR_BG := Color("1A1410")
const COLOR_FIREFLY := Color("F2CC66")
const VIEWPORT_SIZE := Vector2(640, 360)
const FIREFLY_COUNT: int = 12
const FIREFLY_PERIOD_MIN: float = 1.8
const FIREFLY_PERIOD_MAX: float = 3.6
const FIREFLY_ALPHA_MIN: float = 0.15
const FIREFLY_ALPHA_MAX: float = 0.65

var _bg_rect: ColorRect
var _fireflies: Array[ColorRect] = []
var _firefly_phases: Array[float] = []
var _firefly_periods: Array[float] = []
var _time: float = 0.0
var _using_sprite: bool = false


func _ready() -> void:
	if ResourceLoader.exists(BG_PATH):
		_build_sprite_background()
	else:
		_build_fallback_background()
		_build_fireflies()


func _process(delta: float) -> void:
	if _using_sprite:
		return
	_time += delta
	_update_fireflies()


func _build_sprite_background() -> void:
	var tex: Texture2D = load(BG_PATH) as Texture2D
	if not tex:
		_build_fallback_background()
		_build_fireflies()
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	add_child(sprite)
	_using_sprite = true


func _build_fallback_background() -> void:
	_bg_rect = ColorRect.new()
	_bg_rect.color = COLOR_BG
	_bg_rect.anchor_left = 0.0
	_bg_rect.anchor_right = 1.0
	_bg_rect.anchor_top = 0.0
	_bg_rect.anchor_bottom = 1.0
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)


func _build_fireflies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5F3DE
	for _i in FIREFLY_COUNT:
		var dot := ColorRect.new()
		dot.color = COLOR_FIREFLY
		dot.size = Vector2(2, 2)
		var x: float = rng.randf_range(16.0, VIEWPORT_SIZE.x - 16.0)
		var y: float = rng.randf_range(20.0, VIEWPORT_SIZE.y - 80.0)
		dot.position = Vector2(x, y)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_fireflies.append(dot)
		_firefly_phases.append(rng.randf() * TAU)
		_firefly_periods.append(rng.randf_range(FIREFLY_PERIOD_MIN, FIREFLY_PERIOD_MAX))


func _update_fireflies() -> void:
	for i in _fireflies.size():
		var period: float = _firefly_periods[i]
		var phase: float = _firefly_phases[i]
		var s: float = 0.5 + 0.5 * sin(_time * TAU / period + phase)
		var alpha: float = lerpf(FIREFLY_ALPHA_MIN, FIREFLY_ALPHA_MAX, s)
		_fireflies[i].color.a = alpha

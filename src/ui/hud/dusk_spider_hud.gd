extends CanvasLayer

## 땅거미 접근 경고 HUD — 가장 가까운 땅거미의 거리를 표시한다.
## 2맵 이내 접근 시 보라색 맥동, 1맵 이내 시 긴급 경고.
## EventBus 시그널만 수신하여 갱신한다.

const WARNING_THRESHOLD := 2
const SPRITE_PATH := "res://assets/sprites/effects/fx_spider_warning.png"

# 거리별 맥동 설정 — [최소 알파, 최대 알파, 주기(초), 아이콘 색상]
const TIER_FAR := {
	"alpha_min": 0.5,
	"alpha_max": 0.8,
	"pulse_duration": 2.0,
	"color": Color(0.4, 0.1, 0.55, 0.9),
	"label_color": Color(0.6, 0.2, 0.8),
}
const TIER_NEAR := {
	"alpha_min": 0.7,
	"alpha_max": 1.0,
	"pulse_duration": 0.8,
	"color": Color(0.6, 0.15, 0.8, 1.0),
	"label_color": Color(0.8, 0.3, 1.0),
}
const ARRIVAL_COLOR := Color(1.0, 0.4, 0.8, 1.0)
const ARRIVAL_FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _pulse_tween: Tween
var _arrival_tween: Tween
var _current_distance: int = -1
var _is_arriving: bool = false
var _base_icon_color := Color.WHITE

@onready var warning_container: HBoxContainer = $MarginContainer/WarningContainer
@onready var warning_icon: Control = $MarginContainer/WarningContainer/WarningIcon
@onready var distance_label: Label = $MarginContainer/WarningContainer/DistanceLabel


func _ready() -> void:
	EventBus.dusk_spider_approached.connect(_on_approached)
	EventBus.dusk_spider_arrived.connect(_on_arrived)
	_try_load_sprite()


func _on_approached(distance: int) -> void:
	_current_distance = distance
	if _is_arriving:
		return
	if distance < 0 or distance > WARNING_THRESHOLD:
		_hide_warning()
	elif distance <= 1:
		_show_warning(distance, TIER_NEAR)
	else:
		_show_warning(distance, TIER_FAR)


func _on_arrived(_stage_id: String) -> void:
	_is_arriving = true
	_stop_pulse()
	warning_container.visible = true
	distance_label.text = "!"
	distance_label.add_theme_color_override("font_color", ARRIVAL_COLOR)

	if _arrival_tween:
		_arrival_tween.kill()
	_arrival_tween = create_tween()
	# 플래시 3회 (modulate — ColorRect/TextureRect 무관)
	for i in range(3):
		_arrival_tween.tween_property(warning_icon, "modulate", ARRIVAL_FLASH_COLOR, 0.05)
		_arrival_tween.tween_property(warning_icon, "modulate", Color.WHITE, 0.05)
	# 스케일 펄스 (순차)
	(
		_arrival_tween
		. tween_property(warning_container, "scale", Vector2(1.5, 1.5), 0.15)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)
	_arrival_tween.tween_property(warning_container, "scale", Vector2.ONE, 0.15).set_ease(
		Tween.EASE_IN
	)
	# 대기 후 복귀
	_arrival_tween.tween_interval(0.5)
	_arrival_tween.tween_callback(_on_arrival_finished)


# --- 내부 ---


func _show_warning(distance: int, tier: Dictionary) -> void:
	warning_container.visible = true
	distance_label.text = str(distance)
	distance_label.add_theme_color_override("font_color", tier.label_color)
	_set_icon_color(tier.color)
	_start_pulse(tier.alpha_min, tier.alpha_max, tier.pulse_duration)


func _hide_warning() -> void:
	warning_container.visible = false
	_stop_pulse()


func _start_pulse(alpha_min: float, alpha_max: float, duration: float) -> void:
	_stop_pulse()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(warning_container, "modulate:a", alpha_min, duration * 0.5)
	_pulse_tween.tween_property(warning_container, "modulate:a", alpha_max, duration * 0.5)


func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	warning_container.modulate.a = 1.0


func _on_arrival_finished() -> void:
	_is_arriving = false
	warning_container.scale = Vector2.ONE
	warning_icon.modulate = Color.WHITE
	# 현재 거리 상태에 따라 경고 복귀 또는 숨김
	_on_approached(_current_distance)


func _set_icon_color(color: Color) -> void:
	_base_icon_color = color
	if warning_icon is ColorRect:
		warning_icon.color = color
	else:
		warning_icon.modulate = color


func _try_load_sprite() -> void:
	if not ResourceLoader.exists(SPRITE_PATH):
		return
	var texture := load(SPRITE_PATH) as Texture2D
	if not texture:
		return
	var tex_rect := TextureRect.new()
	tex_rect.name = "WarningIcon"
	tex_rect.texture = texture
	tex_rect.custom_minimum_size = Vector2(12, 12)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.layout_mode = 2
	var idx: int = warning_icon.get_index()
	warning_container.remove_child(warning_icon)
	warning_icon.free()
	warning_container.add_child(tex_rect)
	warning_container.move_child(tex_rect, idx)
	warning_icon = tex_rect

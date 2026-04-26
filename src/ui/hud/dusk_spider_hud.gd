extends CanvasLayer

## 땅거미 접근 경고 HUD — 가장 가까운 땅거미의 거리를 표시한다.
## 2맵 이내 접근 시 보라색 맥동, 1맵 이내 시 긴급 경고.
## EventBus 시그널만 수신하여 갱신한다.
##
## REC-MECH-005 (2026-04-26): 화면 가장자리 발자국 5단계 침투 추가.
## 거리 -1: 모두 숨김 / 거리 2: 2개 가장자리 / 거리 1: 4개 + 안쪽 이동 / 거리 0: 5개 풀.
## 보라색 맥동 작은 아이콘은 유지(중복 표시 — 환경 가시화 + 명시 카운터 둘 다).
## sprite 자동 교체: assets/sprites/ui/dusk_footprint.png 도착 시 자동 반영.

const WARNING_THRESHOLD := 2
const SPRITE_PATH := "res://assets/sprites/effects/fx_spider_warning.png"
const FOOTPRINT_SPRITE_PATH := "res://assets/sprites/ui/dusk_footprint.png"
const _CONFIG_PATH := "res://data/effects/effects_config.tres"

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

# REC-MECH-005: 발자국 풀
var _footprint_pool: Array = []  # Array[Control]
var _footprint_tween: Tween
var _footprint_config: EffectsConfigData
var _footprint_texture: Texture2D = null

@onready var warning_container: HBoxContainer = $MarginContainer/WarningContainer
@onready var warning_icon: Control = $MarginContainer/WarningContainer/WarningIcon
@onready var distance_label: Label = $MarginContainer/WarningContainer/DistanceLabel


func _ready() -> void:
	EventBus.dusk_spider_approached.connect(_on_approached)
	EventBus.dusk_spider_arrived.connect(_on_arrived)
	_try_load_sprite()
	_setup_footprints()


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
	_apply_footprint_stage(distance)


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


# === REC-MECH-005: 화면 가장자리 발자국 5단계 ===


func _setup_footprints() -> void:
	if ResourceLoader.exists(_CONFIG_PATH):
		_footprint_config = load(_CONFIG_PATH) as EffectsConfigData
	if _footprint_config == null:
		_footprint_config = EffectsConfigData.new()
	if ResourceLoader.exists(FOOTPRINT_SPRITE_PATH):
		_footprint_texture = load(FOOTPRINT_SPRITE_PATH) as Texture2D
	# 발자국 풀 생성 — 가장자리 좌측에서 우측으로 일렬 (기본 좌측 침투).
	var pool_size: int = _footprint_config.footprint_pool_size
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	for i in range(pool_size):
		var node: Control = _create_footprint_node(i, pool_size, viewport_size)
		add_child(node)
		_footprint_pool.append(node)


func _create_footprint_node(index: int, pool_size: int, viewport_size: Vector2) -> Control:
	var size: Vector2 = _footprint_config.footprint_size
	var node: Control
	if _footprint_texture != null:
		var tex_rect := TextureRect.new()
		tex_rect.texture = _footprint_texture
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		node = tex_rect
	else:
		var rect := ColorRect.new()
		rect.color = _footprint_config.footprint_color
		node = rect
	node.name = "Footprint%d" % index
	node.size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.modulate.a = 0.0
	# 가장자리 좌측 — index 별로 약간씩 안쪽 이동(자연스러운 군집).
	var x: float = _footprint_config.footprint_edge_margin + float(index) * 4.0
	var step_y: float = (viewport_size.y - 32.0) / float(max(pool_size - 1, 1))
	var y: float = 16.0 + float(index) * step_y
	node.position = Vector2(x, y)
	return node


func _apply_footprint_stage(distance: int) -> void:
	if _footprint_pool.is_empty():
		return
	if _footprint_tween != null and _footprint_tween.is_valid():
		_footprint_tween.kill()
	_footprint_tween = create_tween().set_parallel(true)
	var visible_count: int = _stage_visible_count(distance)
	var inward: float = _stage_inward_drift(distance)
	var fade: float = _footprint_config.footprint_fade_duration
	for i in range(_footprint_pool.size()):
		var node: Control = _footprint_pool[i]
		var should_show: bool = i < visible_count
		var target_alpha: float = (
			_stage_alpha(distance, i, visible_count) if should_show else 0.0
		)
		_footprint_tween.tween_property(node, "modulate:a", target_alpha, fade)
		var base_x: float = _footprint_config.footprint_edge_margin + float(i) * 4.0
		var target_x: float = base_x + inward
		_footprint_tween.tween_property(node, "position:x", target_x, fade)


static func _stage_visible_count(distance: int) -> int:
	# 거리 -1: 0개 / 거리 2: 2개 / 거리 1: 4개 / 거리 0: 5개
	match distance:
		2:
			return 2
		1:
			return 4
		0:
			return 5
		_:
			return 0


func _stage_inward_drift(distance: int) -> float:
	# 거리 1부터 안쪽으로 이동 시작, 거리 0에서 풀 침투.
	var base: float = _footprint_config.footprint_inward_drift
	match distance:
		1:
			return base * 0.5
		0:
			return base
		_:
			return 0.0


func _stage_alpha(distance: int, index: int, visible_count: int) -> float:
	# 거리 2 = 희미(0.4), 거리 1 = 중간(0.7), 거리 0 = 강함(1.0). 뒷쪽 발자국은 좀 더 흐림.
	var base: float = 0.4
	match distance:
		1:
			base = 0.7
		0:
			base = 1.0
	# 군집 끝쪽은 살짝 더 흐림(자연스러움).
	var fade_ratio: float = 1.0 - 0.2 * float(index) / float(max(visible_count - 1, 1))
	return base * fade_ratio

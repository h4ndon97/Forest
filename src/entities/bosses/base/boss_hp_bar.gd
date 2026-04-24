extends Node2D

## 보스 HP 바 — 화면 상단 풀너비.
## CanvasLayer 자식으로 배치되어 카메라 무관.
##
## 페이즈 표현 (2026-04-23 결정 A):
## - 임계 마커 없음. 페이즈마다 HP 바 자체가 0%→100%로 리셋되며 색상 변환.
## - 점 인디케이터로 전체 페이즈 카운트 + 현재 페이즈 표시.
##
## 위치 (2026-04-23 사용자 피드백): 화면 상단 임시 배치.
## 추후 Phase 3-7 Pass 5 (UI/환경/컷인 폴리시) 단계에서 최종 위치/스타일 재검토.

const BAR_WIDTH := 384.0
const BAR_HEIGHT := 12.0
## 화면 상단 마진. 플레이어 HUD(CombatHud MarginContainer y=16~40) 아래 15px 여백.
## 임시 — Pass 5에서 최종 디자인 재결정.
const BAR_TOP_MARGIN := 55.0
const BG_COLOR := Color(0.05, 0.05, 0.05, 0.85)
const LOW_THRESHOLD := 0.3
const NAME_COLOR := Color(0.95, 0.9, 0.85, 1.0)
const NAME_FONT_SIZE := 12

## 페이즈별 HP 바 색상 — 빨강(P1) → 보라(말기) 그라데이션 (그림자 왕가 모티프).
## phase_count > 배열 길이면 마지막 색 재사용.
const PHASE_COLORS: Array[Color] = [
	Color(0.9, 0.25, 0.2, 0.95),  # P1 빨강 (기본 위협)
	Color(0.75, 0.2, 0.5, 0.95),  # P2 자주
	Color(0.55, 0.15, 0.7, 0.95),  # P3 보라 (그림자 왕가)
	Color(0.4, 0.1, 0.55, 0.95),  # P4 짙은 보라
]
## 페이즈 무관 빈사 색상.
const HP_COLOR_LOW := Color(1.0, 0.4, 0.1, 1.0)

## 점 인디케이터 — HP 바 아래(상단 배치이므로 양수 오프셋).
const DOT_SIZE := 6.0
const DOT_SPACING := 6.0
const DOT_OFFSET_Y := 6.0
const DOT_ACTIVE_COLOR := Color(0.95, 0.9, 0.85, 1.0)
const DOT_INACTIVE_COLOR := Color(0.95, 0.9, 0.85, 0.35)

## 페이즈 전환 시 HP 바 채우기.
## 보스 phase_transition_duration(1.8s) 내 완료되도록 1.7s 사용.
const REFILL_DELAY := 0.3
const REFILL_DURATION := 1.4

var _pending_name: String = ""
var _pending_phase_count: int = 1
var _pending_thresholds: PackedFloat32Array = PackedFloat32Array()
var _bg: ColorRect = null
var _fill: ColorRect = null
var _name_label: Label = null
var _phase_indicators: Array = []
var _refill_tween: Tween = null
var _current_phase: int = 0
## 페이즈 전환 중 HP 바 표시는 _refill_tween이 전담 — 이 시간엔 health_changed 무시.
var _is_transitioning: bool = false


## base_boss._ready()에서 호출. 페이즈 정보 주입.
func setup(
	display_name: String,
	phase_count: int = 1,
	phase_thresholds: PackedFloat32Array = PackedFloat32Array()
) -> void:
	_pending_name = display_name
	_pending_phase_count = max(phase_count, 1)
	_pending_thresholds = phase_thresholds
	if _name_label:
		_name_label.text = display_name
	_rebuild_phase_indicators()


func _ready() -> void:
	z_index = 100
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var bar_x: float = (viewport_size.x - BAR_WIDTH) * 0.5
	var bar_y: float = BAR_TOP_MARGIN

	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bg.position = Vector2(bar_x, bar_y)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_fill = ColorRect.new()
	_fill.color = _phase_color(0)
	_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fill.position = Vector2(bar_x, bar_y)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	_name_label = Label.new()
	_name_label.text = _pending_name
	_name_label.add_theme_color_override("font_color", NAME_COLOR)
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	# 상단 배치이므로 보스명은 HP 바 아래에 표시.
	_name_label.position = Vector2(bar_x, bar_y + BAR_HEIGHT + 4)
	_name_label.size = Vector2(BAR_WIDTH, 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	_rebuild_phase_indicators()


## stats_comp.health_changed 핸들러. 현재 페이즈의 (start, end) 구간을 0~100%로 정규화.
func on_health_changed(current_hp: float, max_hp: float) -> void:
	if _fill == null or _is_transitioning:
		return
	var current_ratio: float = current_hp / max_hp if max_hp > 0.0 else 0.0
	var bounds: Vector2 = _phase_bounds(_current_phase)
	var span: float = bounds.x - bounds.y
	var phase_ratio: float = (
		clamp((current_ratio - bounds.y) / span, 0.0, 1.0) if span > 0.0 else 0.0
	)
	_fill.size.x = BAR_WIDTH * phase_ratio
	_fill.color = HP_COLOR_LOW if phase_ratio < LOW_THRESHOLD else _phase_color(_current_phase)


## boss_phase_controller.phase_entered → 활성 페이즈 점 갱신 + 전환 종료.
func on_phase_entered(phase_index: int) -> void:
	_current_phase = phase_index
	_refresh_phase_indicator_colors()
	# phase_transition_duration 종료 후 emit되므로 안전하게 transition 종료.
	_is_transitioning = false
	# 시간 정지로 중단된 전환 케이스: 리필 tween이 아직 돌고 있으면 kill.
	# (정상 종료 시엔 이미 끝나 있어 kill은 no-op)
	if _refill_tween != null and _refill_tween.is_valid():
		_refill_tween.kill()


## boss_phase_controller.phase_transition_started → HP 바 0→100% 리필.
func on_phase_transition_started(_from_phase: int, to_phase: int) -> void:
	_is_transitioning = true
	_refill_to_phase(to_phase)


# === 내부 ===


## 페이즈 i의 HP 비율 구간을 (start, end)로 반환. 모두 0~1 범위.
## 예: phase_count=2, thresholds=[0.5] → P0(0): (1.0, 0.5) / P1(1): (0.5, 0.0).
func _phase_bounds(phase_index: int) -> Vector2:
	var thresholds: PackedFloat32Array = _pending_thresholds
	var start_ratio: float = 1.0 if phase_index == 0 else thresholds[phase_index - 1]
	var end_ratio: float = thresholds[phase_index] if phase_index < thresholds.size() else 0.0
	return Vector2(start_ratio, end_ratio)


func _phase_color(phase_index: int) -> Color:
	if PHASE_COLORS.is_empty():
		return Color.WHITE
	var clamped: int = clamp(phase_index, 0, PHASE_COLORS.size() - 1)
	return PHASE_COLORS[clamped]


func _refill_to_phase(to_phase: int) -> void:
	if _fill == null:
		return
	if _refill_tween != null and _refill_tween.is_valid():
		_refill_tween.kill()
	# 즉시 0%로 리셋 → 잠시 후 채우기 (전환 충격 시각화).
	_fill.size.x = 0.0
	_fill.color = _phase_color(to_phase)
	_refill_tween = create_tween().set_ignore_time_scale(true)
	_refill_tween.tween_interval(REFILL_DELAY)
	_refill_tween.tween_property(_fill, "size:x", BAR_WIDTH, REFILL_DURATION)


func _rebuild_phase_indicators() -> void:
	for dot in _phase_indicators:
		if is_instance_valid(dot):
			dot.queue_free()
	_phase_indicators.clear()
	if _bg == null or _pending_phase_count <= 1:
		return
	var total_width: float = (
		(DOT_SIZE * _pending_phase_count) + (DOT_SPACING * (_pending_phase_count - 1))
	)
	var start_x: float = _bg.position.x + _bg.size.x - total_width
	var dot_y: float = _bg.position.y + _bg.size.y + DOT_OFFSET_Y
	for i in _pending_phase_count:
		var dot := ColorRect.new()
		dot.color = DOT_ACTIVE_COLOR if i == _current_phase else DOT_INACTIVE_COLOR
		dot.size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.position = Vector2(start_x + i * (DOT_SIZE + DOT_SPACING), dot_y)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)
		_phase_indicators.append(dot)


func _refresh_phase_indicator_colors() -> void:
	for i in _phase_indicators.size():
		if not is_instance_valid(_phase_indicators[i]):
			continue
		_phase_indicators[i].color = (
			DOT_ACTIVE_COLOR if i == _current_phase else DOT_INACTIVE_COLOR
		)

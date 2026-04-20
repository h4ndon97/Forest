extends Node

## 월드맵 그래프 노드/연결선 생성을 담당하는 헬퍼.
## 극좌표(radius_ring, angle_deg, radius_offset)를 화면 좌표로 변환하고,
## 같은 링 위 인접 노드는 호(arc), 다른 링/오프셋은 직선으로 연결한다.
## WorldMapUI의 자식으로 동작한다.

const CLEAR_COLORS := {
	0: Color(0.5, 0.5, 0.5),  # UNCLEARED — 회색
	1: Color(0.9, 0.8, 0.2),  # HALF_CLEARED — 노랑
	2: Color(0.3, 0.9, 0.3),  # FULLY_CLEARED — 초록
}
const CHECKPOINT_COLOR := Color(0.9, 0.75, 0.3)
const CURRENT_COLOR := Color(0.4, 0.8, 1.0)
const LOCKED_COLOR := Color(0.6, 0.3, 0.3)

# 시간 오버레이 톤 (D11: 채도 0 방식 — time_stopped 시 HSV S=0 적용)
const DAY_TINT := Color(0.58, 0.48, 0.22)  # 12시 중심 따뜻한 톤
const NIGHT_TINT := Color(0.12, 0.14, 0.28)  # 0시 중심 차가운 톤
const CHECKPOINT_TINT := Color(0.20, 0.17, 0.12)

# 동심 극좌표 레이아웃 (Step 2 / 아이콘화)
const RING_CENTER := Vector2(320, 180)
const RING_RADII := {1: 140, 2: 110, 3: 85, 4: 60, 5: 35}
const ARC_SAMPLES := 12
const LINE_COLOR := Color(0.5, 0.5, 0.5, 0.6)

# 오버뷰 노드(작은 원형 아이콘 + 방사 라벨)
const DOT_SIZE := 16.0
const DOT_LABEL_SIZE := Vector2(64, 10)
const DOT_LABEL_GAP := 4.0
const DOT_LABEL_FONT := 7


## 극좌표 필드가 유효해서 월드맵에 그려야 하는 스테이지인지 판정한다.
## radius_ring <= 0 은 test_* 등 비표시 대상.
func is_polar(data: StageData) -> bool:
	return data != null and data.radius_ring > 0 and RING_RADII.has(data.radius_ring)


## StageData의 극좌표를 화면 좌표(Vector2)로 변환한다.
## 시계 기준(0°=12시, 시계방향 +) → 수학 기준(0°=3시, 반시계 +) 변환: angle - 90°.
func compute_node_position(data: StageData) -> Vector2:
	if not is_polar(data):
		return Vector2.ZERO
	var r: float = float(RING_RADII[data.radius_ring]) + data.radius_offset
	var math_rad: float = deg_to_rad(data.angle_deg - 90.0)
	return RING_CENTER + Vector2(cos(math_rad), sin(math_rad)) * r


## 스테이지 오버뷰 노드(작은 원형 dot + 방사 이름 라벨)를 parent 하위에 생성한다.
## 반환값: dot PanelContainer (StyleBoxFlat "panel" override 적용됨).
## time_stopped=true면 dot 배경에 채도 0 필터 적용(D11).
func create_stage_node(
	stage_id: String, pos: Vector2, time_stopped: bool, parent: Control
) -> PanelContainer:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if not data:
		return null

	var dot := PanelContainer.new()
	dot.position = pos - Vector2(DOT_SIZE, DOT_SIZE) / 2.0
	dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = compute_node_bg_color(stage_id, time_stopped)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = get_border_color(stage_id, data)
	var radius: int = int(DOT_SIZE / 2.0)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	dot.add_theme_stylebox_override("panel", style)
	parent.add_child(dot)

	var label := Label.new()
	label.text = data.display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", DOT_LABEL_FONT)
	label.size = DOT_LABEL_SIZE
	# 라벨은 dot 중심에서 방사 방향으로 떨어진 위치. offset < 0 (숨겨진 leaf) 는 안쪽으로.
	var out_dir: Vector2 = (pos - RING_CENTER).normalized()
	if out_dir == Vector2.ZERO:
		out_dir = Vector2(0, 1)
	if data.radius_offset < 0.0:
		out_dir = -out_dir
	var radial: float = DOT_SIZE / 2.0 + DOT_LABEL_GAP + DOT_LABEL_SIZE.y / 2.0
	var label_center: Vector2 = pos + out_dir * radial
	label.position = label_center - DOT_LABEL_SIZE / 2.0
	parent.add_child(label)

	return dot


## 땅거미 위치 아이콘(placeholder)을 생성한다. D12: 단일 "⚠" 스타일.
## Phase 3-7에서 실제 거미 실루엣으로 교체 예정.
func create_spider_icon(pos: Vector2) -> Label:
	var label := Label.new()
	label.text = "⚠"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	var icon_size := Vector2(14, 14)
	label.size = icon_size
	# 작은 dot 우상단에 살짝 겹치기
	label.position = pos + Vector2(DOT_SIZE / 2.0 - 4.0, -DOT_SIZE / 2.0 - icon_size.y + 4.0)
	label.z_index = 1
	return label


## 두 스테이지 사이 연결선을 생성한다.
## 같은 링 + 같은 오프셋(즉 동일 반경) 이면 호, 아니면 직선.
func create_connection(from_data: StageData, to_data: StageData) -> Line2D:
	if not is_polar(from_data) or not is_polar(to_data):
		return null
	var same_ring: bool = from_data.radius_ring == to_data.radius_ring
	var same_offset: bool = is_equal_approx(from_data.radius_offset, to_data.radius_offset)
	if same_ring and same_offset:
		return _create_arc_line(from_data, to_data)
	return _create_radial_line(from_data, to_data)


## 스테이지 노드의 테두리 색상을 결정한다.
func get_border_color(stage_id: String, data: StageData) -> Color:
	var current: String = StageSystem.get_current_stage_id()
	if stage_id == current:
		return CURRENT_COLOR
	if data.is_checkpoint:
		var discovered: Array = StageSystem.get_discovered_checkpoints()
		if stage_id in discovered:
			return CHECKPOINT_COLOR
		return LOCKED_COLOR
	if data.lock_type != StageData.LockType.NONE:
		if not StageSystem.is_stage_accessible(stage_id):
			return LOCKED_COLOR
	var clear_state: int = StageSystem.get_clear_state(stage_id)
	return CLEAR_COLORS.get(clear_state, CLEAR_COLORS[0])


# --- 시간 오버레이 (3-5-a) ---


## 시간(hour)을 낮/밤 그라디언트 색으로 매핑한다. 6시 이전/18시 이후는 밤,
## 6~7시(새벽)/17~18시(황혼)는 블렌드, 7~17시는 한낮.
func compute_hour_tint(hour: float) -> Color:
	hour = fmod(hour, 24.0)
	if hour < 0.0:
		hour += 24.0
	var day_factor: float
	if hour >= 6.0 and hour < 18.0:
		if hour < 7.0:
			day_factor = hour - 6.0
		elif hour > 17.0:
			day_factor = 18.0 - hour
		else:
			day_factor = 1.0
	else:
		day_factor = 0.0
	return NIGHT_TINT.lerp(DAY_TINT, day_factor)


## 색의 채도만 0으로 만든다(명도/색상 유지). D11: 시간 정지 오버레이.
func desaturate(c: Color) -> Color:
	return Color.from_hsv(c.h, 0.0, c.v, c.a)


## 특정 스테이지의 현재 bg_color를 계산 (stop_flag 포함). UI의 증분 업데이트에서 호출.
func compute_node_bg_color(stage_id: String, time_stopped: bool) -> Color:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if not data:
		return CLEAR_COLORS[0]
	var base: Color = _get_bg_color(stage_id, data)
	if time_stopped:
		return desaturate(base)
	return base


# --- 내부 ---


## 같은 링 + 같은 오프셋 상의 두 점을 짧은쪽 호를 따라 12샘플로 연결한다.
func _create_arc_line(from_data: StageData, to_data: StageData) -> Line2D:
	var r: float = float(RING_RADII[from_data.radius_ring]) + from_data.radius_offset
	var a0: float = from_data.angle_deg
	var a1: float = to_data.angle_deg
	var delta: float = a1 - a0
	# 최단 호 방향 선택 (|delta| <= 180)
	while delta > 180.0:
		delta -= 360.0
	while delta < -180.0:
		delta += 360.0
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = LINE_COLOR
	for i in range(ARC_SAMPLES + 1):
		var t: float = float(i) / float(ARC_SAMPLES)
		var ang: float = a0 + delta * t
		var math_rad: float = deg_to_rad(ang - 90.0)
		var p: Vector2 = RING_CENTER + Vector2(cos(math_rad), sin(math_rad)) * r
		line.add_point(p)
	return line


## 다른 링/오프셋 조합 두 점을 직선으로 연결한다.
func _create_radial_line(from_data: StageData, to_data: StageData) -> Line2D:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = LINE_COLOR
	line.add_point(compute_node_position(from_data))
	line.add_point(compute_node_position(to_data))
	return line


func _get_bg_color(stage_id: String, data: StageData) -> Color:
	if data.is_checkpoint:
		return CHECKPOINT_TINT
	var hour: float = StageSystem.get_stage_hour(stage_id)
	return compute_hour_tint(hour)


func _build_info_text(stage_id: String, data: StageData) -> String:
	var parts: Array = []
	var clear_state: int = StageSystem.get_clear_state(stage_id)
	match clear_state:
		0:
			parts.append("미클리어")
		1:
			parts.append("절반")
		2:
			parts.append("완전")

	var hour: float = StageSystem.get_stage_hour(stage_id)
	var hour_int: int = int(hour)
	parts.append("%02d:00" % hour_int)

	if data.lock_type != StageData.LockType.NONE:
		if not StageSystem.is_stage_accessible(stage_id):
			match data.lock_type:
				1:
					parts.append("빛잠금")
				2:
					parts.append("정화잠금")
				3:
					parts.append("환경잠금")
				4:
					parts.append("능력잠금")

	if data.is_checkpoint:
		parts.clear()
		parts.append("거점")
		parts.append("%02d:00" % hour_int)

	return " | ".join(parts)

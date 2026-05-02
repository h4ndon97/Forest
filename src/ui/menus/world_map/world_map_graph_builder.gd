extends Node

## 월드맵 그래프 노드/연결선 생성을 담당하는 헬퍼.
## 좌표 — StageData.world_map_pos (normalized 0~1, 화면 640x360 비율) 우선.
## 미설정(-1,-1)이면 기존 극좌표(radius_ring/angle_deg/radius_offset) 자동 변환 fallback.
## 연결선은 단순 직선 (REC-UX-007 Stage 1 직사각형 톱뷰 채택, 호 폐기).
## WorldMapUI의 자식으로 동작한다.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

const CLEAR_COLORS := {
	0: Color(0.5, 0.5, 0.5),  # UNCLEARED — 회색
	1: Color(0.9, 0.8, 0.2),  # HALF_CLEARED — 노랑
	2: Color(0.3, 0.9, 0.3),  # FULLY_CLEARED — 초록
}
const CHECKPOINT_COLOR := Color(0.9, 0.75, 0.3)
const CURRENT_COLOR := Color(0.4, 0.8, 1.0)
const LOCKED_COLOR := Color(0.6, 0.3, 0.3)

# 미발견 스테이지 fog (REC-UX-007 Stage 0.5)
const FOG_BG_COLOR := Color(0.10, 0.10, 0.12)
const FOG_BORDER_COLOR := Color(0.20, 0.20, 0.22)

# 시간 오버레이 톤 (D11: 채도 0 방식 — time_stopped 시 HSV S=0 적용)
const DAY_TINT := Color(0.58, 0.48, 0.22)  # 12시 중심 따뜻한 톤
const NIGHT_TINT := Color(0.12, 0.14, 0.28)  # 0시 중심 차가운 톤
const CHECKPOINT_TINT := Color(0.20, 0.17, 0.12)

# 화면 영역 (월드맵 좌표 normalized → 픽셀 변환용)
const SCREEN_SIZE := Vector2(640.0, 360.0)

# 극좌표 fallback (world_map_pos 미설정 시 자동 변환).
# ring → zone *띠 중심선* 사각형 (normalized 0~1). 노드는 zone 영역 *내부* 분포.
# 띠 중심선 = (zone_N 외곽 + zone_{N+1} 외곽) / 2. zone_5는 가장 안쪽 단일 사각형.
const RING_RECTS := {
	1: Rect2(0.15, 0.15, 0.70, 0.70),
	2: Rect2(0.25, 0.25, 0.50, 0.50),
	3: Rect2(0.35, 0.35, 0.30, 0.30),
	4: Rect2(0.43, 0.43, 0.14, 0.14),
	5: Rect2(0.50, 0.50, 0.0, 0.0),
}

# offset 픽셀 → normalized depth 변환. 기존 RING_RADII 간격 30px ≈ 띠 두께 절반 0.05.
const OFFSET_TO_NORM := 0.05 / 30.0

const LINE_COLOR := Color(0.5, 0.5, 0.5, 0.6)

# 오버뷰 노드(작은 원형 아이콘) — 노드 라벨은 detail panel로 이전 (REC-UX-007 Stage 0 fix)
const DOT_SIZE := 16.0


## 월드맵에 그려야 하는 스테이지인지 판정.
## world_map_pos 설정되어 있거나, 극좌표 fallback이 가능한 경우 true.
## test_* 등은 둘 다 미설정 → false.
func has_world_map_node(data: StageData) -> bool:
	if data == null:
		return false
	if data.world_map_pos.x >= 0.0 and data.world_map_pos.y >= 0.0:
		return true
	return data.radius_ring > 0 and RING_RECTS.has(data.radius_ring)


## StageData의 월드맵 위치(픽셀 화면 좌표)를 반환한다.
## world_map_pos 우선, 미설정(-1,-1)이면 극좌표 → 동심 사각형 띠 중심 자동 변환 fallback.
func compute_node_position(data: StageData) -> Vector2:
	if data.world_map_pos.x >= 0.0 and data.world_map_pos.y >= 0.0:
		return data.world_map_pos * SCREEN_SIZE
	if not RING_RECTS.has(data.radius_ring):
		return Vector2.ZERO
	var pos: Vector2 = _polar_to_rect_band(data.radius_ring, data.angle_deg, data.radius_offset)
	return pos * SCREEN_SIZE


## ring 인덱스의 띠 중심선 사각형 둘레 위에 angle 기준 점을 매핑.
## offset(픽셀) → normalized depth로 변환해 같은 ring·angle 노드를 띠 두께 안에서 분리.
## angle 0°=12시(상단 중앙), 시계방향.
func _polar_to_rect_band(ring: int, angle_deg: float, offset: float) -> Vector2:
	var rect: Rect2 = RING_RECTS[ring]
	var cx: float = rect.position.x + rect.size.x / 2.0
	var cy: float = rect.position.y + rect.size.y / 2.0
	# offset depth: 양수=띠 외곽 방향, 음수=띠 안쪽 방향. 띠 절반 두께 0.05 한도.
	var depth: float = clamp(offset * OFFSET_TO_NORM, -0.045, 0.045)
	var hw: float = rect.size.x / 2.0 + depth
	var hh: float = rect.size.y / 2.0 + depth
	if hw <= 0.0 or hh <= 0.0:
		return Vector2(cx, cy)
	var rad: float = deg_to_rad(angle_deg - 90.0)
	var dx: float = cos(rad)
	var dy: float = sin(rad)
	var t_x: float = INF if abs(dx) < 0.0001 else hw / abs(dx)
	var t_y: float = INF if abs(dy) < 0.0001 else hh / abs(dy)
	var t: float = min(t_x, t_y)
	return Vector2(cx + dx * t, cy + dy * t)


## 스테이지 오버뷰 노드(작은 원형 dot)를 parent 하위에 생성한다.
## 반환값: dot PanelContainer (StyleBoxFlat "panel" override 적용됨).
## time_stopped=true면 dot 배경에 채도 0 필터 적용(D11).
## 노드 라벨은 표시하지 않는다 — 스테이지 명칭은 detail panel에서만 노출.
func create_stage_node(
	stage_id: String, pos: Vector2, time_stopped: bool, parent: Control
) -> PanelContainer:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if not data:
		return null

	var dot := PanelContainer.new()
	dot.position = pos - Vector2(DOT_SIZE, DOT_SIZE) / 2.0
	dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
	dot.mouse_filter = Control.MOUSE_FILTER_PASS  # 호버 감지 위해 PASS (REC-UX-007 Stage 0.5)

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


## 두 스테이지 사이 연결선(단순 직선)을 생성한다.
func create_connection(from_data: StageData, to_data: StageData) -> Line2D:
	if not has_world_map_node(from_data) or not has_world_map_node(to_data):
		return null
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = LINE_COLOR
	line.add_point(compute_node_position(from_data))
	line.add_point(compute_node_position(to_data))
	return line


## 스테이지 노드의 테두리 색상을 결정한다.
func get_border_color(stage_id: String, data: StageData) -> Color:
	if not StageSystem.is_stage_discovered(stage_id):
		return FOG_BORDER_COLOR
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
	if not StageSystem.is_stage_discovered(stage_id):
		return FOG_BG_COLOR
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if not data:
		return CLEAR_COLORS[0]
	var base: Color = _get_bg_color(stage_id, data)
	if time_stopped:
		return desaturate(base)
	return base


## TimeSystem의 정지 여부를 반환한다. UI/내부에서 한 곳으로 통합.
func is_time_stopped() -> bool:
	return TimeSystem.get_time_state() == TimeStateMachine.TimeState.STOPPED


## 모든 노드의 배경색을 현재 시간 상태에 맞춰 갱신한다(테두리/크기는 유지).
func refresh_all_node_bg_colors(stage_nodes: Dictionary) -> void:
	var stopped: bool = is_time_stopped()
	for stage_id in stage_nodes:
		var panel: PanelContainer = stage_nodes[stage_id]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = compute_node_bg_color(stage_id, stopped)


## 땅거미 아이콘 컨테이너를 비우고 활성 스테이지 위에 ⚠ 아이콘을 재배치한다.
func refresh_spider_icons(container: Control, stage_positions: Dictionary) -> Dictionary:
	for child in container.get_children():
		child.queue_free()
	var spider_icons: Dictionary = {}
	for stage_id in DuskSpiderSystem.get_active_stages():
		if not stage_positions.has(stage_id):
			continue
		var icon: Label = create_spider_icon(stage_positions[stage_id])
		container.add_child(icon)
		spider_icons[stage_id] = icon
	return spider_icons


## 모든 표시 가능 스테이지의 노드 + 연결선을 한번에 생성한다.
## 미발견 스테이지 사이의 연결선은 표시하지 않는다(fog).
## 결과: {"stage_nodes": Dict, "stage_positions": Dict, "zone_populated": Dict}
func build_all(node_container: Control, line_container: Control) -> Dictionary:
	var stage_nodes: Dictionary = {}
	var stage_positions: Dictionary = {}
	var zone_populated: Dictionary = {}
	var stopped: bool = is_time_stopped()
	var visible_ids: Array = []

	for stage_id in StageSystem.get_all_stage_ids():
		var data: StageData = StageSystem.get_stage_data(stage_id)
		if not has_world_map_node(data):
			continue
		var pos: Vector2 = compute_node_position(data)
		stage_positions[stage_id] = pos
		visible_ids.append(stage_id)
		if not data.zone_id.is_empty():
			zone_populated[data.zone_id] = true
		var dot: PanelContainer = create_stage_node(stage_id, pos, stopped, node_container)
		if dot:
			stage_nodes[stage_id] = dot

	for stage_id in visible_ids:
		var data: StageData = StageSystem.get_stage_data(stage_id)
		var src_known: bool = StageSystem.is_stage_discovered(stage_id)
		for adj_id in data.adjacent_stages:
			if stage_id >= adj_id or not stage_positions.has(adj_id):
				continue
			if not src_known or not StageSystem.is_stage_discovered(adj_id):
				continue
			var adj_data: StageData = StageSystem.get_stage_data(adj_id)
			var line: Line2D = create_connection(data, adj_data)
			if line:
				line_container.add_child(line)

	return {
		"stage_nodes": stage_nodes,
		"stage_positions": stage_positions,
		"zone_populated": zone_populated,
	}


# --- 내부 ---


func _get_bg_color(stage_id: String, data: StageData) -> Color:
	if data.is_checkpoint:
		return CHECKPOINT_TINT
	var hour: float = StageSystem.get_stage_hour(stage_id)
	return compute_hour_tint(hour)

extends Node

## 월드맵 그래프 노드/연결선 생성 및 BFS 토폴로지 정렬을 담당하는 헬퍼.
## WorldMapUI의 자식으로 동작한다.

const CLEAR_COLORS := {
	0: Color(0.5, 0.5, 0.5),  # UNCLEARED — 회색
	1: Color(0.9, 0.8, 0.2),  # HALF_CLEARED — 노랑
	2: Color(0.3, 0.9, 0.3),  # FULLY_CLEARED — 초록
}
const CHECKPOINT_COLOR := Color(0.9, 0.75, 0.3)
const CURRENT_COLOR := Color(0.4, 0.8, 1.0)
const LOCKED_COLOR := Color(0.6, 0.3, 0.3)
const NODE_SIZE := Vector2(80, 48)

# 시간 오버레이 톤 (D11: 채도 0 방식 — time_stopped 시 HSV S=0 적용)
const DAY_TINT := Color(0.58, 0.48, 0.22)  # 12시 중심 따뜻한 톤
const NIGHT_TINT := Color(0.12, 0.14, 0.28)  # 0시 중심 차가운 톤
const CHECKPOINT_TINT := Color(0.20, 0.17, 0.12)


## BFS로 토폴로지 순서를 결정한다. 첫 번째 거점부터 시작.
func bfs_order(all_ids: Array) -> Array:
	if all_ids.is_empty():
		return []

	var start_id: String = ""
	for sid in all_ids:
		var data: StageData = StageSystem.get_stage_data(sid)
		if data and data.is_checkpoint:
			start_id = sid
			break
	if start_id.is_empty():
		start_id = all_ids[0]

	var visited: Dictionary = {}
	var queue: Array = [start_id]
	var ordered: Array = []
	visited[start_id] = true

	while not queue.is_empty():
		var current: String = queue.pop_front()
		ordered.append(current)
		var data: StageData = StageSystem.get_stage_data(current)
		if not data:
			continue
		for adj_id in data.adjacent_stages:
			if not visited.has(adj_id) and adj_id in all_ids:
				visited[adj_id] = true
				queue.append(adj_id)

	for sid in all_ids:
		if not visited.has(sid):
			ordered.append(sid)

	return ordered


## 스테이지 노드(PanelContainer)를 생성하여 반환한다.
## time_stopped=true면 배경에 채도 0 필터 적용(D11).
func create_stage_node(
	stage_id: String, pos: Vector2, time_stopped: bool = false
) -> PanelContainer:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if not data:
		return null

	var panel := PanelContainer.new()
	panel.position = pos - NODE_SIZE / 2.0
	panel.custom_minimum_size = NODE_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = compute_node_bg_color(stage_id, time_stopped)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = get_border_color(stage_id, data)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(name_label)

	var info_label := Label.new()
	info_label.text = _build_info_text(stage_id, data)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.clip_text = true
	info_label.add_theme_font_size_override("font_size", 7)
	vbox.add_child(info_label)

	panel.add_child(vbox)
	return panel


## 땅거미 위치 아이콘(placeholder)을 생성한다. D12: 단일 "⚠" 스타일.
## Phase 3-7에서 실제 거미 실루엣으로 교체 예정.
func create_spider_icon(pos: Vector2) -> Label:
	var label := Label.new()
	label.text = "⚠"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	var icon_size := Vector2(18, 18)
	label.size = icon_size
	# 노드 우측 상단에 겹치기
	label.position = pos + Vector2(NODE_SIZE.x / 2.0 - icon_size.x, -NODE_SIZE.y / 2.0)
	label.z_index = 1
	return label


## 인접 스테이지 간 연결선(Line2D)을 생성하여 반환한다.
func create_connection_line(from: Vector2, to: Vector2) -> Line2D:
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = Color(0.5, 0.5, 0.5, 0.6)
	return line


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

extends Node

## 월드맵 그래프 노드/연결선 생성 및 BFS 토폴로지 정렬을 담당하는 헬퍼.
## WorldMapUI의 자식으로 동작한다.

const CLEAR_COLORS := {
	0: Color(0.5, 0.5, 0.5),    # UNCLEARED — 회색
	1: Color(0.9, 0.8, 0.2),    # HALF_CLEARED — 노랑
	2: Color(0.3, 0.9, 0.3),    # FULLY_CLEARED — 초록
}
const CHECKPOINT_COLOR := Color(0.9, 0.75, 0.3)
const CURRENT_COLOR := Color(0.4, 0.8, 1.0)
const LOCKED_COLOR := Color(0.6, 0.3, 0.3)
const NODE_SIZE := Vector2(80, 48)


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
func create_stage_node(stage_id: String, pos: Vector2) -> PanelContainer:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if not data:
		return null

	var panel := PanelContainer.new()
	panel.position = pos - NODE_SIZE / 2.0
	panel.custom_minimum_size = NODE_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = _get_bg_color(stage_id, data)
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


# --- 내부 ---

func _get_bg_color(stage_id: String, data: StageData) -> Color:
	if data.is_checkpoint:
		return Color(0.15, 0.12, 0.08)
	var clear_state: int = StageSystem.get_clear_state(stage_id)
	var base: Color = CLEAR_COLORS.get(clear_state, CLEAR_COLORS[0])
	return base * 0.3


func _build_info_text(stage_id: String, data: StageData) -> String:
	var parts: Array = []
	var clear_state: int = StageSystem.get_clear_state(stage_id)
	match clear_state:
		0: parts.append("미클리어")
		1: parts.append("절반")
		2: parts.append("완전")

	var hour: float = StageSystem.get_stage_hour(stage_id)
	var hour_int: int = int(hour)
	parts.append("%02d:00" % hour_int)

	if data.lock_type != StageData.LockType.NONE:
		if not StageSystem.is_stage_accessible(stage_id):
			match data.lock_type:
				1: parts.append("빛잠금")
				2: parts.append("정화잠금")
				3: parts.append("환경잠금")
				4: parts.append("능력잠금")

	if data.is_checkpoint:
		parts.clear()
		parts.append("거점")
		parts.append("%02d:00" % hour_int)

	return " | ".join(parts)

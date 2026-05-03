extends Node

## 월드맵 stage 간 연결 path 렌더러 — REC-UX-007 Stage 1.5 (영역형, 2026-05-02 결정).
## adjacent_stages 기반 점선. 빛 발광 라인(따뜻한 빛 색).
## graph_builder.create_connection 대체 — 단순 직선 → 점선으로 변경.
## 미발견 영역 사이 path 미표시. 양방향 중복 회피 (stage_id < adj_id 만 그림).
## Phase E에서 속성 컬러 펄스 / 화살표 head 추가 예정.

const DASH_LENGTH: float = 4.0
const GAP_LENGTH: float = 4.0
const PATH_WIDTH: float = 1.5
const PATH_COLOR: Color = Color(0.85, 0.75, 0.45, 0.7)


## 모든 path를 container에 빌드(기존 children 비우고 재빌드).
func build(container: Control, builder: Node) -> void:
	for child in container.get_children():
		child.queue_free()
	for stage_id in StageSystem.get_all_stage_ids():
		var data: StageData = StageSystem.get_stage_data(stage_id)
		if data == null:
			continue
		if not StageSystem.is_stage_discovered(stage_id):
			continue
		for adj_id in data.adjacent_stages:
			if stage_id >= adj_id:
				continue
			if not StageSystem.is_stage_discovered(adj_id):
				continue
			var adj_data: StageData = StageSystem.get_stage_data(adj_id)
			if adj_data == null:
				continue
			if not builder.has_world_map_node(data) or not builder.has_world_map_node(adj_data):
				continue
			var src_pos: Vector2 = builder.compute_node_position(data)
			var dst_pos: Vector2 = builder.compute_node_position(adj_data)
			_add_dashed_segments(container, src_pos, dst_pos)


# === 내부 ===


func _add_dashed_segments(container: Control, from_pos: Vector2, to_pos: Vector2) -> void:
	var diff: Vector2 = to_pos - from_pos
	var dist: float = diff.length()
	if dist <= 0.0:
		return
	var dir: Vector2 = diff / dist
	var step: float = DASH_LENGTH + GAP_LENGTH
	var current: float = 0.0
	while current < dist:
		var dash_end: float = minf(current + DASH_LENGTH, dist)
		var line: Line2D = Line2D.new()
		line.add_point(from_pos + dir * current)
		line.add_point(from_pos + dir * dash_end)
		line.width = PATH_WIDTH
		line.default_color = PATH_COLOR
		line.z_index = 3
		container.add_child(line)
		current += step

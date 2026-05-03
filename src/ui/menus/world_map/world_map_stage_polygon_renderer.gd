extends Node

## 월드맵 stage 영역 polygon 렌더러 — REC-UX-007 Stage 1.5 (영역형, 2026-05-02 (가)+(A) 결정).
## stage별 polygon + 라벨 그리기. StageData.world_map_polygon 우선,
## 없으면 graph_builder의 dot 위치(compute_node_position) 주변에 균일 box fallback.
## 색은 graph_builder.compute_node_bg_color 재사용 — 시간대 톤/시간 정지 desaturate/미발견 fog/클리어 상태 자동.
## 윤곽선은 graph_builder.get_border_color 재사용 — 잠금/현재 위치/거점/클리어 상태 자동.
## 라벨은 발견된 stage만 표시 — 거점은 display_name, 일반 stage는 짧은 코드("1-1", "2-H").

const SCREEN_SIZE := Vector2(640.0, 360.0)
# zone별 box half_size (normalized) — 안쪽 zone일수록 띠 둘레가 짧아 stage 간격이 좁음.
# zone3·4는 stage 11/13 빽빽하게 배치되므로 box도 비례 축소. zone5는 점에 가깝게.
const ZONE_BOX_HALF_SIZES := {
	1: Vector2(0.040, 0.025),
	2: Vector2(0.032, 0.022),
	3: Vector2(0.020, 0.018),
	4: Vector2(0.012, 0.012),
	5: Vector2(0.006, 0.006),
}
const DEFAULT_BOX_HALF_SIZE := Vector2(0.025, 0.020)
const LABEL_FONT_SIZE := 7
const LABEL_SIZE := Vector2(40, 12)
const LABEL_COLOR := Color(0.92, 0.92, 0.88, 0.95)
const LABEL_FOG_COLOR := Color(0.45, 0.45, 0.45, 0.5)


## stage 모든 polygon을 container에 빌드. graph_builder는 색 매핑 + 위치 계산에 재사용.
func build(container: Control, builder: Node) -> void:
	for child in container.get_children():
		child.queue_free()
	var stopped: bool = builder.is_time_stopped()
	for stage_id in StageSystem.get_all_stage_ids():
		_add_stage_polygon(container, stage_id, stopped, builder)


## 시간 변화 시 polygon 색만 갱신(전체 재빌드 회피).
func refresh_colors(container: Control, builder: Node) -> void:
	var stopped: bool = builder.is_time_stopped()
	for child in container.get_children():
		var stage_id_meta: Variant = child.get_meta("stage_id", null)
		if stage_id_meta == null:
			continue
		var stage_id: String = String(stage_id_meta)
		var data: StageData = StageSystem.get_stage_data(stage_id)
		if data == null:
			continue
		if child is Polygon2D:
			(child as Polygon2D).color = builder.compute_node_bg_color(stage_id, stopped)
		elif child is Line2D:
			(child as Line2D).default_color = builder.get_border_color(stage_id, data)


# === 내부 ===


func _add_stage_polygon(
	container: Control, stage_id: String, time_stopped: bool, builder: Node
) -> void:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if data == null:
		return
	var norm_pts: PackedVector2Array = _resolve_polygon(data, builder)
	if norm_pts.size() < 3:
		return
	var pixel_pts: PackedVector2Array = PackedVector2Array()
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	for p in norm_pts:
		var pixel: Vector2 = p * SCREEN_SIZE
		pixel_pts.append(pixel)
		sum_x += pixel.x
		sum_y += pixel.y
	var center_pixel: Vector2 = Vector2(sum_x, sum_y) / float(pixel_pts.size())
	# 영역 채움.
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = pixel_pts
	poly.color = builder.compute_node_bg_color(stage_id, time_stopped)
	poly.z_index = 1  # zone polygon(z=0) 위, line(z=2) 아래.
	poly.set_meta("stage_id", stage_id)
	container.add_child(poly)
	# 영역 윤곽선.
	var outline: Line2D = Line2D.new()
	for pt in pixel_pts:
		outline.add_point(pt)
	outline.add_point(pixel_pts[0])  # 폐쇄.
	outline.width = 1.0
	outline.default_color = builder.get_border_color(stage_id, data)
	outline.z_index = 2
	outline.set_meta("stage_id", stage_id)
	container.add_child(outline)
	# 라벨 — 미발견 stage는 흐릿하게 표시(영역 식별만 가능).
	var label: Label = _create_label(stage_id, data, center_pixel)
	if label != null:
		container.add_child(label)


func _resolve_polygon(data: StageData, builder: Node) -> PackedVector2Array:
	if not data.world_map_polygon.is_empty():
		return data.world_map_polygon
	if not builder.has_world_map_node(data):
		return PackedVector2Array()
	var pos_pixel: Vector2 = builder.compute_node_position(data)
	if pos_pixel == Vector2.ZERO:
		return PackedVector2Array()
	var center_norm: Vector2 = pos_pixel / SCREEN_SIZE
	var zone_index: int = WorldMapPolygonFallback.zone_index_from_id(data.zone_id)
	var half_size: Vector2 = ZONE_BOX_HALF_SIZES.get(zone_index, DEFAULT_BOX_HALF_SIZE)
	return WorldMapPolygonFallback.generate_box_around(center_norm, half_size)


func _create_label(stage_id: String, data: StageData, center: Vector2) -> Label:
	var text: String = _short_label(stage_id, data)
	if text.is_empty():
		return null
	var label: Label = Label.new()
	label.text = text
	label.size = LABEL_SIZE
	label.position = center - LABEL_SIZE * 0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	var color: Color = (
		LABEL_COLOR if StageSystem.is_stage_discovered(stage_id) else LABEL_FOG_COLOR
	)
	label.add_theme_color_override("font_color", color)
	label.z_index = 4  # path(z=3) 위.
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # hover 방해 회피.
	label.set_meta("stage_id", stage_id)
	return label


## 짧은 식별자 — 거점은 display_name 우선, 일반 stage는 "1-1"·"2-H" 형식.
func _short_label(stage_id: String, data: StageData) -> String:
	if data.is_checkpoint and not data.display_name.is_empty():
		return data.display_name
	if stage_id.begins_with("stage_"):
		return stage_id.substr(6).replace("_", "-").to_upper()
	return stage_id

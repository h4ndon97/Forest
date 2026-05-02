extends Node

## 월드맵 영역 polygon 렌더러 — REC-UX-007 Stage 1 (직사각형 톱뷰).
## WorldMapUI 자식 노드. 5 zone .tres를 로드해 Polygon2D 생성.
## polygon_points 빈 .tres에는 zone별 가로 띠 default 자동 생성.
## .tres polygon_points는 normalized 0~1, renderer가 화면 픽셀로 변환.

const SCREEN_SIZE := Vector2(640.0, 360.0)

# 화면 80% 직사각형 영역 (normalized 0~1)
const RECT_AREA := Rect2(0.10, 0.10, 0.80, 0.80)

# zone별 default 동심 사각형 (normalized Rect2). zone_1=가장 큰 외곽, zone_5=중심.
# 같은 z_index 면 tree 순서로 안쪽 zone이 외곽 zone을 덮음 → 양파 껍질 효과.
const ZONE_DEFAULT_RECTS := {
	"zone_1": Rect2(0.10, 0.10, 0.80, 0.80),
	"zone_2": Rect2(0.20, 0.20, 0.60, 0.60),
	"zone_3": Rect2(0.30, 0.30, 0.40, 0.40),
	"zone_4": Rect2(0.40, 0.40, 0.20, 0.20),
	"zone_5": Rect2(0.46, 0.46, 0.08, 0.08),
}

const ZONE_TRES_PATHS := [
	"res://data/world_map/zones/zone_1_polygon.tres",
	"res://data/world_map/zones/zone_2_polygon.tres",
	"res://data/world_map/zones/zone_3_polygon.tres",
	"res://data/world_map/zones/zone_4_polygon.tres",
	"res://data/world_map/zones/zone_5_polygon.tres",
]


## 모든 zone polygon을 container에 빌드한다(기존 children 비우고 재빌드).
func build(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()
	for path in ZONE_TRES_PATHS:
		var data: Resource = load(path)
		if data == null:
			continue
		_add_zone(container, data)


func _add_zone(container: Control, data: Resource) -> void:
	var norm_pts: PackedVector2Array = data.polygon_points
	if norm_pts.is_empty():
		norm_pts = _default_polygon(data.zone_id)
	if norm_pts.size() < 3:
		return
	var pixel_pts := PackedVector2Array()
	for p in norm_pts:
		pixel_pts.append(p * SCREEN_SIZE)
	var poly := Polygon2D.new()
	poly.polygon = pixel_pts
	poly.color = data.base_color
	poly.z_index = data.z_index
	container.add_child(poly)


## zone별 동심 사각형 default (normalized 0~1).
func _default_polygon(zone_id: String) -> PackedVector2Array:
	if not ZONE_DEFAULT_RECTS.has(zone_id):
		return PackedVector2Array()
	var rect: Rect2 = ZONE_DEFAULT_RECTS[zone_id]
	var pts := PackedVector2Array()
	pts.append(rect.position)
	pts.append(Vector2(rect.position.x + rect.size.x, rect.position.y))
	pts.append(rect.position + rect.size)
	pts.append(Vector2(rect.position.x, rect.position.y + rect.size.y))
	return pts

class_name WorldMapPolygonFallback
extends RefCounted

## stage가 world_map_polygon이 비어있을 때 사용할 자동 fallback 폴리곤 생성기.
## REC-UX-007 Stage 1.5 영역형 전환(2026-05-02 확정) Phase B 수준 — 정밀하지 않음.
## zone 외곽 사각형을 stage_count개 가로 띠로 단순 분할. 시각 검증용 placeholder.
## Phase C에서 zone 띠(도넛) 4-변 분배 또는 에디터 도구 입력으로 교체 예정.

# zone별 외곽 사각형 (world_map_zone_polygon_renderer.ZONE_DEFAULT_RECTS와 동일).
const ZONE_RECTS := {
	1: Rect2(0.10, 0.10, 0.80, 0.80),
	2: Rect2(0.20, 0.20, 0.60, 0.60),
	3: Rect2(0.30, 0.30, 0.40, 0.40),
	4: Rect2(0.40, 0.40, 0.20, 0.20),
	5: Rect2(0.46, 0.46, 0.08, 0.08),
}


## stage가 zone N에 있고 그 zone에 stage_count개 stage가 있을 때,
## stage_index(0~stage_count-1)에 해당하는 fallback polygon을 반환한다.
## stage_count<=0 또는 zone_index 범위 외면 빈 배열 반환.
static func generate(
	zone_index: int, stage_index: int, stage_count: int
) -> PackedVector2Array:
	if stage_count <= 0 or stage_index < 0 or stage_index >= stage_count:
		return PackedVector2Array()
	var rect: Rect2 = ZONE_RECTS.get(zone_index, Rect2(0.0, 0.0, 1.0, 1.0))
	var band_height: float = rect.size.y / float(stage_count)
	var top: float = rect.position.y + band_height * float(stage_index)
	var bottom: float = top + band_height
	var left: float = rect.position.x
	var right: float = rect.position.x + rect.size.x
	return PackedVector2Array(
		[Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)]
	)


## stage_data.zone_id ("zone_1", "zone_2", ...) → zone_index(1~5).
## 비표준 zone_id ("checkpoint" 등)는 0 반환 → ZONE_RECTS.get fallback이 (0,0,1,1)으로 처리.
static func zone_index_from_id(zone_id: String) -> int:
	if not zone_id.begins_with("zone_"):
		return 0
	var num_str: String = zone_id.substr(5)
	if not num_str.is_valid_int():
		return 0
	return num_str.to_int()


## stage_data가 비어있으면 fallback 사용, 아니면 본인의 polygon 반환.
## stage_index/stage_count는 호출자(renderer)가 zone별로 집계해 전달.
static func resolve(
	stage_data: StageData, stage_index: int, stage_count: int
) -> PackedVector2Array:
	if stage_data == null:
		return PackedVector2Array()
	if not stage_data.world_map_polygon.is_empty():
		return stage_data.world_map_polygon
	var zone_index: int = zone_index_from_id(stage_data.zone_id)
	return generate(zone_index, stage_index, stage_count)

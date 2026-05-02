extends Node

## 월드맵 오버뷰의 구역(zone) 라벨 — REC-UX-007 Stage 1 (직사각형 톱뷰, 동심 사각형).
## 각 zone 동심 띠의 상단 중앙에 "N구역 — 이름" 라벨을 배치한다.
## 미발견 zone(노드 0개)은 라벨 숨김 (첫 노드 발견 시 자동 표시).

const SCREEN_SIZE := Vector2(640.0, 360.0)
const ZONE_LABEL_COLOR := Color(0.92, 0.88, 0.72)
const LABEL_SIZE := Vector2(120, 12)

const ZONE_NAMES := {
	"zone_1": "1구역 — 빛의 숲",
	"zone_2": "2구역 — 안개 습지",
	"zone_3": "3구역 — 미정",
	"zone_4": "4구역 — 미정",
	"zone_5": "5구역 — 심부",
}

# zone별 라벨 위치 — 각 동심 띠 상단 중앙 (normalized 0~1, 라벨 중심 좌표).
# zone_1=가장 위, zone_5=중심 안쪽. zone_polygon_renderer ZONE_DEFAULT_RECTS.position.y와 일치.
const ZONE_LABEL_CENTER := {
	"zone_1": Vector2(0.50, 0.115),  # 외곽 띠 상단
	"zone_2": Vector2(0.50, 0.215),
	"zone_3": Vector2(0.50, 0.315),
	"zone_4": Vector2(0.50, 0.415),
	"zone_5": Vector2(0.50, 0.475),  # 중심
}


## zone 라벨을 일괄 생성한다. zone_populated[zone_id] = bool (해당 zone에 노드가 있는지).
func build_overlay(container: Control, zone_populated: Dictionary) -> void:
	for zone_id in ZONE_NAMES:
		if not zone_populated.get(zone_id, false):
			continue
		container.add_child(_create_zone_label(zone_id))


func _create_zone_label(zone_id: String) -> Label:
	var label := Label.new()
	label.text = ZONE_NAMES.get(zone_id, zone_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", ZONE_LABEL_COLOR)
	label.size = LABEL_SIZE
	var center_norm: Vector2 = ZONE_LABEL_CENTER.get(zone_id, Vector2.ZERO)
	var center_px: Vector2 = center_norm * SCREEN_SIZE
	label.position = center_px - LABEL_SIZE / 2.0
	return label

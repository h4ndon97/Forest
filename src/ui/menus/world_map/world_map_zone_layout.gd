extends Node

## 월드맵 오버뷰의 구역(zone) 라벨과 미구현 링 placeholder를 담당한다.
## 동심 극좌표 모델: zone_id ↔ radius_ring 을 1:1로 매핑하며,
## 각 링마다 12시 방향 바깥에 "N구역 — 이름" 라벨을, 노드가 없는 링은 점선으로 표시한다.

const ZONE_NAMES := {
	"zone_1": "1구역 — 빛의 숲",
	"zone_2": "2구역 — 안개 습지",
	"zone_3": "3구역 — 미정",
	"zone_4": "4구역 — 미정",
	"zone_5": "5구역 — 심부",
}
const ZONE_RING := {
	"zone_1": 1,
	"zone_2": 2,
	"zone_3": 3,
	"zone_4": 4,
	"zone_5": 5,
}
# 구역 라벨 배치 각도 (시계 기준, 0°=12시 CW). 나선 회전으로 깊이감과 통로 암시.
const ZONE_LABEL_ANGLE := {
	"zone_1": 270.0,
	"zone_2": 240.0,
	"zone_3": 210.0,
	"zone_4": 180.0,
	"zone_5": 150.0,
}
const ZONE_LABEL_COLOR := Color(0.75, 0.70, 0.55)
const PLACEHOLDER_COLOR := Color(0.35, 0.35, 0.35, 0.45)
const PLACEHOLDER_SEGMENTS := 48
const PLACEHOLDER_DASH := 2  # N개마다 1개만 표시 → 점선 느낌
const LABEL_OFFSET := 12.0  # 링 바깥으로 라벨을 얼마나 띄울지
const LABEL_SIZE := Vector2(120, 12)


## 오버레이를 일괄 생성한다. ring_populated[ring] = bool (노드가 있는지).
func build_overlay(
	container: Control,
	ring_center: Vector2,
	ring_radii: Dictionary,
	ring_populated: Dictionary
) -> void:
	for zone_id in ZONE_RING:
		var ring_idx: int = ZONE_RING[zone_id]
		if not ring_radii.has(ring_idx):
			continue
		var radius: float = float(ring_radii[ring_idx])
		var has_nodes: bool = ring_populated.get(ring_idx, false)
		if not has_nodes:
			# 미발견 구역: placeholder 점선만, 라벨은 숨김 (첫 노드 발견 시 자동 표시)
			container.add_child(_create_placeholder_ring(ring_center, radius))
			continue
		container.add_child(_create_leader_tick(zone_id, ring_center, radius))
		container.add_child(_create_zone_label(zone_id, ring_center, radius))


func _create_zone_label(zone_id: String, center: Vector2, radius: float) -> Label:
	var label := Label.new()
	label.text = ZONE_NAMES.get(zone_id, zone_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", ZONE_LABEL_COLOR)
	label.size = LABEL_SIZE
	# 구역별 각도(나선 회전)로 링 바깥에 배치. 라벨이 축정렬 사각형이므로
	# 방사 방향으로의 외접 길이는 |half_w * cos| + |half_h * sin| 로 계산.
	var angle: float = ZONE_LABEL_ANGLE.get(zone_id, 0.0)
	var math_rad: float = deg_to_rad(angle - 90.0)
	var dir := Vector2(cos(math_rad), sin(math_rad))
	var half: Vector2 = LABEL_SIZE / 2.0
	var radial_ext: float = abs(half.x * dir.x) + abs(half.y * dir.y)
	var label_center: Vector2 = center + dir * (radius + LABEL_OFFSET + radial_ext)
	label.position = label_center - half
	return label


## 링 위 해당 zone 각도에서 라벨 방향으로 짧은 tick을 그려 라벨↔링 관계를 시각화.
func _create_leader_tick(zone_id: String, center: Vector2, radius: float) -> Line2D:
	var angle: float = ZONE_LABEL_ANGLE.get(zone_id, 0.0)
	var math_rad: float = deg_to_rad(angle - 90.0)
	var dir := Vector2(cos(math_rad), sin(math_rad))
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = ZONE_LABEL_COLOR
	line.add_point(center + dir * radius)
	line.add_point(center + dir * (radius + LABEL_OFFSET))
	return line


## 노드가 없는 링을 점선 원으로 그린다 (Godot Line2D 다중 세그먼트).
func _create_placeholder_ring(center: Vector2, radius: float) -> Node2D:
	var holder := Node2D.new()
	var seg_angle: float = TAU / float(PLACEHOLDER_SEGMENTS)
	for i in range(PLACEHOLDER_SEGMENTS):
		if i % PLACEHOLDER_DASH != 0:
			continue
		var a0: float = seg_angle * float(i)
		var a1: float = seg_angle * float(i + 1)
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = PLACEHOLDER_COLOR
		line.add_point(center + Vector2(cos(a0), sin(a0)) * radius)
		line.add_point(center + Vector2(cos(a1), sin(a1)) * radius)
		holder.add_child(line)
	return holder

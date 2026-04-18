extends Node

## 월드맵의 구역(zone) 단위 라벨/구분선 레이아웃을 담당한다.
## BFS 정렬 순서에서 같은 zone_id 연속 구간을 그룹핑해 라벨과 구분선을 배치한다.

const ZONE_NAMES := {
	"zone_1": "1구역 — 빛의 숲",
	"zone_2": "2구역 — 안개 습지",
}
const ZONE_LABEL_COLOR := Color(0.75, 0.70, 0.55)
const ZONE_SEPARATOR_COLOR := Color(0.4, 0.4, 0.4, 0.5)


## 구역 라벨과 구분선을 container 하위에 일괄 생성한다.
func build_overlay(
	container: Control,
	ordered: Array,
	positions: Dictionary,
	label_y: float,
	sep_top: float,
	sep_bottom: float
) -> void:
	if ordered.is_empty():
		return
	var group_zone: String = ""
	var group_start_x: float = 0.0
	var group_end_x: float = 0.0
	var prev_zone: String = ""
	var prev_x: float = 0.0
	for stage_id in ordered:
		var data: StageData = StageSystem.get_stage_data(stage_id)
		var zone: String = data.zone_id if data else ""
		var pos: Vector2 = positions.get(stage_id, Vector2.ZERO)
		if zone != prev_zone:
			if not group_zone.is_empty():
				_emit_label(container, group_zone, group_start_x, group_end_x, label_y)
			if not prev_zone.is_empty() and not zone.is_empty():
				var sep_x: float = (prev_x + pos.x) / 2.0
				container.add_child(_create_separator(sep_x, sep_top, sep_bottom))
			group_zone = zone
			group_start_x = pos.x
		group_end_x = pos.x
		prev_zone = zone
		prev_x = pos.x
	if not group_zone.is_empty():
		_emit_label(container, group_zone, group_start_x, group_end_x, label_y)


func _emit_label(parent: Control, zone_id: String, start_x: float, end_x: float, y: float) -> void:
	if not ZONE_NAMES.has(zone_id):
		return
	var label := Label.new()
	label.text = ZONE_NAMES[zone_id]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", ZONE_LABEL_COLOR)
	var label_size := Vector2(160, 14)
	label.size = label_size
	label.position = Vector2((start_x + end_x) / 2.0 - label_size.x / 2.0, y)
	parent.add_child(label)


func _create_separator(x: float, y_top: float, y_bottom: float) -> Line2D:
	var line := Line2D.new()
	line.add_point(Vector2(x, y_top))
	line.add_point(Vector2(x, y_bottom))
	line.width = 1.0
	line.default_color = ZONE_SEPARATOR_COLOR
	return line

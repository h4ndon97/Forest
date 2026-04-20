extends CanvasLayer

## 스테이지 진입 시 display_name + 구역명을 하단 중앙에 페이드 인/아웃으로 표시.
## 메트로배니아 고전 연출. EventBus.stage_entered 구독.

const HOLD := 1.2
const FADE_OUT := 0.8
const ANCHOR_Y := 280.0
const PANEL_SIZE := Vector2(400, 44)
const TITLE_COLOR := Color(0.95, 0.92, 0.85)
const ZONE_COLOR := Color(0.70, 0.65, 0.50)
const CHECKPOINT_ACCENT := Color(0.95, 0.80, 0.35)
# world_map_zone_layout.gd의 ZONE_NAMES와 동기화 필요 (zone 데이터 .tres화 시 단일 소스로 이관)
const ZONE_DISPLAY := {
	"zone_1": "빛의 숲",
	"zone_2": "안개 습지",
	"zone_3": "미정",
	"zone_4": "미정",
	"zone_5": "심부",
}

var _root: Control
var _title_label: Label
var _zone_label: Label
var _tween: Tween


func _ready() -> void:
	layer = 80
	_build_ui()
	EventBus.stage_entered.connect(_on_stage_entered)


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.position = Vector2(320.0 - PANEL_SIZE.x / 2.0, ANCHOR_Y)
	_root.size = PANEL_SIZE
	_root.modulate.a = 0.0
	add_child(_root)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 15)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_title_label.position = Vector2(0, 0)
	_title_label.size = Vector2(PANEL_SIZE.x, 22)
	_root.add_child(_title_label)

	_zone_label = Label.new()
	_zone_label.name = "Zone"
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_label.add_theme_font_size_override("font_size", 9)
	_zone_label.add_theme_color_override("font_color", ZONE_COLOR)
	_zone_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_zone_label.position = Vector2(0, 24)
	_zone_label.size = Vector2(PANEL_SIZE.x, 16)
	_root.add_child(_zone_label)


func _on_stage_entered(stage_id: String) -> void:
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if data == null or data.display_name.is_empty():
		return
	_title_label.text = data.display_name
	_zone_label.text = _format_zone(data)
	var title_color: Color = CHECKPOINT_ACCENT if data.is_checkpoint else TITLE_COLOR
	_title_label.add_theme_color_override("font_color", title_color)
	_play()


func _format_zone(data: StageData) -> String:
	var zone: String = ZONE_DISPLAY.get(data.zone_id, data.zone_id)
	if zone.is_empty():
		return "— 거점 —" if data.is_checkpoint else ""
	if data.is_checkpoint:
		return "— 거점 · %s —" % zone
	return "— %s —" % zone


func _play() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_root.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(HOLD)
	_tween.tween_property(_root, "modulate:a", 0.0, FADE_OUT)

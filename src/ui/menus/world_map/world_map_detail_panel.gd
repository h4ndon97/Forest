extends PanelContainer

## 월드맵 노드 선택 시 상세 정보를 표시하는 우측 패널.
## 이름, 구역, 시각, 클리어 상태, 잠금, 땅거미, 인접 수를 실시간 반영.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")
const PANEL_SIZE := Vector2(140, 150)
const BG_COLOR := Color(0.05, 0.05, 0.07, 0.9)
const BORDER_COLOR := Color(0.35, 0.35, 0.40, 0.8)
const TITLE_COLOR := Color(0.95, 0.92, 0.85)
const ZONE_COLOR := Color(0.7, 0.7, 0.75)
const INFO_COLOR := Color(0.85, 0.85, 0.88)
const LOCK_COLOR := Color(0.95, 0.55, 0.55)
const SPIDER_COLOR := Color(1.0, 0.4, 0.4)

var _title_label: Label
var _zone_label: Label
var _info_container: VBoxContainer


func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	visible = false
	_apply_style()
	_build_children()


## 특정 스테이지의 상세 정보를 표시한다.
func refresh(stage_id: String) -> void:
	if stage_id.is_empty():
		_clear_content()
		return
	var data: StageData = StageSystem.get_stage_data(stage_id)
	if data == null:
		_clear_content()
		return
	visible = true
	if not StageSystem.is_stage_discovered(stage_id):
		_render_fog()
		return
	_title_label.text = data.display_name
	_zone_label.text = _format_zone(data.zone_id)
	_rebuild_info(stage_id, data)


## 미발견 스테이지 — 모든 정보를 ??? 처리 (REC-UX-007 Stage 0.5 fog).
func _render_fog() -> void:
	_title_label.text = "???"
	_zone_label.text = "— ??? —"
	_clear_info()
	_add_info("시각: --:--", INFO_COLOR)
	_add_info("상태: 미발견", LOCK_COLOR)


## 특정 스테이지를 위해 패널을 표시 + 위치 자동 정렬한다.
## position_hint = 노드의 화면 좌표 (640x360 기준).
func show_for(stage_id: String, position_hint: Vector2) -> void:
	if stage_id.is_empty():
		visible = false
		return
	refresh(stage_id)
	var x: float = position_hint.x + 20.0
	if x + size.x > 636.0:
		x = position_hint.x - 20.0 - size.x
	position = Vector2(
		clamp(x, 4.0, 636.0 - size.x),
		clamp(position_hint.y - size.y / 2.0, 4.0, 356.0 - size.y)
	)
	visible = true


func hide_panel() -> void:
	visible = false


## 선택 없음 상태(패널 비워 표시).
func clear_display() -> void:
	_clear_content()


# --- 내부 ---


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.border_color = BORDER_COLOR
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)


func _build_children() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "Column"
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.add_theme_color_override("font_color", TITLE_COLOR)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_title_label)

	_zone_label = Label.new()
	_zone_label.name = "Zone"
	_zone_label.add_theme_font_size_override("font_size", 9)
	_zone_label.add_theme_color_override("font_color", ZONE_COLOR)
	vbox.add_child(_zone_label)

	var separator := HSeparator.new()
	separator.name = "Separator"
	vbox.add_child(separator)

	_info_container = VBoxContainer.new()
	_info_container.name = "Info"
	_info_container.add_theme_constant_override("separation", 3)
	vbox.add_child(_info_container)


func _clear_content() -> void:
	_title_label.text = "(선택 없음)"
	_zone_label.text = ""
	_clear_info()


func _clear_info() -> void:
	for child in _info_container.get_children():
		child.queue_free()


func _rebuild_info(stage_id: String, data: StageData) -> void:
	_clear_info()

	_add_info(_format_hour(stage_id), INFO_COLOR)
	_add_info(_format_clear_state(stage_id, data), INFO_COLOR)

	var lock_text: String = _format_lock(stage_id, data)
	if not lock_text.is_empty():
		_add_info(lock_text, LOCK_COLOR)

	if _has_spider(stage_id):
		_add_info("⚠ 땅거미 접근 중", SPIDER_COLOR)

	_add_info("인접: %d" % data.adjacent_stages.size(), INFO_COLOR)


func _add_info(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_container.add_child(label)


func _format_zone(zone_id: String) -> String:
	if zone_id.is_empty():
		return "— 기타 —"
	return "— %s —" % zone_id


func _format_hour(stage_id: String) -> String:
	if _is_time_stopped():
		return "시각: --:-- (정지)"
	var hour: float = StageSystem.get_stage_hour(stage_id)
	return "시각: %02d:00" % int(hour)


func _format_clear_state(stage_id: String, data: StageData) -> String:
	if data.is_checkpoint:
		return "상태: 거점"
	var clear: int = StageSystem.get_clear_state(stage_id)
	match clear:
		0:
			return "상태: 미클리어"
		1:
			return "상태: 절반 클리어"
		2:
			return "상태: 완전 클리어"
	return "상태: ?"


func _format_lock(stage_id: String, data: StageData) -> String:
	if data.lock_type == StageData.LockType.NONE:
		return ""
	if StageSystem.is_stage_accessible(stage_id):
		return ""
	var text: String = "잠금"
	match data.lock_type:
		1:
			text = "잠금: 빛 (점등 필요)"
		2:
			text = "잠금: 정화 필요"
		3:
			text = "잠금: 환경 조건"
		4:
			var req: String = data.lock_requirement
			if not req.is_empty() and not AbilitySystem.has(req):
				text = "잠금: 능력 — %s" % req
			else:
				text = "잠금: 능력"
	return text


func _has_spider(stage_id: String) -> bool:
	var active: Array = DuskSpiderSystem.get_active_stages()
	return stage_id in active


func _is_time_stopped() -> bool:
	return TimeSystem.get_time_state() == TimeStateMachine.TimeState.STOPPED

extends CanvasLayer

## 월드맵 UI. 발견한 거점과 스테이지를 노드그래프로 표시한다.
## 발견한 거점을 선택하여 패스트트래블할 수 있다.
## 독립 Autoload CanvasLayer로 동작한다.
## pause를 사용하지 않음 — 시간 전파/애니메이션은 유지, 플레이어 입력만 차단.

const GraphBuilderScript = preload("res://src/ui/menus/world_map/world_map_graph_builder.gd")
const ZoneLayoutScript = preload("res://src/ui/menus/world_map/world_map_zone_layout.gd")
const DetailPanelScript = preload("res://src/ui/menus/world_map/world_map_detail_panel.gd")
const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")
const NODE_SPACING := Vector2(88, 0)
const GRAPH_ORIGIN := Vector2(320, 180)
const SELECTED_COLOR := Color(1.0, 1.0, 1.0)
const ZONE_LABEL_Y := 222.0  # 노드 하단(180+24) 아래
const ZONE_SEPARATOR_TOP := 150.0
const ZONE_SEPARATOR_BOTTOM := 210.0

var _visible: bool = false
var _builder: Node
var _zone_layout: Node
var _bg: ColorRect
var _title_label: Label
var _hint_label: Label
var _node_container: Control
var _line_container: Control
var _stage_nodes: Dictionary = {}  # stage_id -> PanelContainer
var _stage_positions: Dictionary = {}  # stage_id -> Vector2 (노드 중심 위치)
var _spider_icons: Dictionary = {}  # stage_id -> Label
var _spider_container: Control
var _zone_container: Control
var _detail_panel: PanelContainer
var _selectable_ids: Array = []  # 이동 가능한 거점 ID 목록
var _selected_index: int = 0


func _ready() -> void:
	layer = 90
	visible = false
	process_priority = -10

	_builder = Node.new()
	_builder.name = "GraphBuilder"
	_builder.set_script(GraphBuilderScript)
	add_child(_builder)

	_zone_layout = Node.new()
	_zone_layout.name = "ZoneLayout"
	_zone_layout.set_script(ZoneLayoutScript)
	add_child(_zone_layout)

	_build_ui_frame()
	EventBus.world_map_opened.connect(_on_open)
	EventBus.time_flow_started.connect(_on_time_flow_changed)
	EventBus.time_flow_stopped.connect(_on_time_flow_changed)
	EventBus.current_hour_changed.connect(_on_current_hour_changed)
	EventBus.dusk_spider_spawned.connect(_on_spider_state_changed)
	EventBus.dusk_spider_arrived.connect(_on_spider_state_changed)
	EventBus.dusk_spider_defeated.connect(_on_spider_state_changed)


func _process(_delta: float) -> void:
	if not _visible:
		return

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
		_close()
		return

	if _selectable_ids.is_empty():
		return

	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_navigate(-1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_navigate(1)
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_accept"):
		_travel_to_selected()


# --- UI 구축 ---


func is_open() -> bool:
	return _visible


func _build_ui_frame() -> void:
	_bg = ColorRect.new()
	_bg.name = "BG"
	_bg.color = Color(0, 0, 0, 0.85)
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "월드맵"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(270, 16)
	_title_label.size = Vector2(100, 24)
	add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.position = Vector2(170, 330)
	_hint_label.size = Vector2(300, 20)
	_hint_label.add_theme_font_size_override("font_size", 8)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(_hint_label)

	_line_container = _make_container("Lines")
	_zone_container = _make_container("ZoneLabels")
	_node_container = _make_container("Nodes")
	_spider_container = _make_container("SpiderIcons")

	_detail_panel = PanelContainer.new()
	_detail_panel.name = "DetailPanel"
	_detail_panel.set_script(DetailPanelScript)
	add_child(_detail_panel)


func _make_container(container_name: String) -> Control:
	var c := Control.new()
	c.name = container_name
	add_child(c)
	return c


func _rebuild_graph() -> void:
	for child in _node_container.get_children():
		child.queue_free()
	for child in _line_container.get_children():
		child.queue_free()
	for child in _spider_container.get_children():
		child.queue_free()
	for child in _zone_container.get_children():
		child.queue_free()
	_stage_nodes.clear()
	_stage_positions.clear()
	_spider_icons.clear()
	_selectable_ids.clear()

	var all_ids: Array = StageSystem.get_all_stage_ids()
	var ordered: Array = _builder.bfs_order(all_ids)

	var total: int = ordered.size()
	var start_x: float = GRAPH_ORIGIN.x - (total - 1) * NODE_SPACING.x / 2.0

	for i in range(total):
		var stage_id: String = ordered[i]
		var pos := Vector2(start_x + i * NODE_SPACING.x, GRAPH_ORIGIN.y)
		_stage_positions[stage_id] = pos
		var panel: PanelContainer = _builder.create_stage_node(stage_id, pos, _is_time_stopped())
		if panel:
			_node_container.add_child(panel)
			_stage_nodes[stage_id] = panel

	for stage_id in ordered:
		var data: StageData = StageSystem.get_stage_data(stage_id)
		if not data:
			continue
		for adj_id in data.adjacent_stages:
			if _stage_positions.has(adj_id) and stage_id < adj_id:
				var line: Line2D = _builder.create_connection_line(
					_stage_positions[stage_id], _stage_positions[adj_id]
				)
				_line_container.add_child(line)

	var discovered: Array = StageSystem.get_discovered_checkpoints()
	var current: String = StageSystem.get_current_stage_id()
	for cp_id in discovered:
		if cp_id != current:
			_selectable_ids.append(cp_id)

	_refresh_spider_icons()
	_zone_layout.build_overlay(
		_zone_container,
		ordered,
		_stage_positions,
		ZONE_LABEL_Y,
		ZONE_SEPARATOR_TOP,
		ZONE_SEPARATOR_BOTTOM
	)
	_selected_index = 0
	_update_selection_highlight()
	_update_hint_label()


# --- 네비게이션 ---


func _navigate(direction: int) -> void:
	if _selectable_ids.is_empty():
		return
	_selected_index = wrapi(_selected_index + direction, 0, _selectable_ids.size())
	_update_selection_highlight()


func _update_selection_highlight() -> void:
	for stage_id in _stage_nodes:
		var panel: PanelContainer = _stage_nodes[stage_id]
		var data: StageData = StageSystem.get_stage_data(stage_id)
		if not data:
			continue
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = _builder.get_border_color(stage_id, data)
			style.set_border_width_all(2)

	if _selectable_ids.is_empty():
		if _detail_panel:
			_detail_panel.clear_display()
		return
	var selected_id: String = _selectable_ids[_selected_index]
	if _stage_nodes.has(selected_id):
		var panel: PanelContainer = _stage_nodes[selected_id]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = SELECTED_COLOR
			style.set_border_width_all(3)
	if _detail_panel:
		_detail_panel.refresh(selected_id)


func _update_hint_label() -> void:
	if _selectable_ids.is_empty():
		_hint_label.text = "[F/ESC] 닫기"
	else:
		_hint_label.text = "[←→] 거점 선택  [↑] 이동  [F/ESC] 닫기"


func _travel_to_selected() -> void:
	if _selectable_ids.is_empty():
		return
	var target_id: String = _selectable_ids[_selected_index]
	_visible = false
	visible = false
	EventBus.world_map_closed.emit()
	EventBus.stage_transition_requested.emit(target_id, "checkpoint")


# --- 열기/닫기 ---


func _on_open() -> void:
	if _visible:
		return
	_visible = true
	visible = true
	_rebuild_graph()


func _close() -> void:
	if not _visible:
		return
	_visible = false
	visible = false
	EventBus.world_map_closed.emit()


# --- 시간 오버레이 갱신 (3-5-a) ---


func _is_time_stopped() -> bool:
	return TimeSystem.get_time_state() == TimeStateMachine.TimeState.STOPPED


func _on_time_flow_changed(_hour: float) -> void:
	if _visible:
		_refresh_bg_colors()


func _on_current_hour_changed(_hour: float) -> void:
	if _visible:
		_refresh_bg_colors()


## 모든 노드의 배경색만 갱신한다(테두리/크기는 유지).
func _refresh_bg_colors() -> void:
	var stopped: bool = _is_time_stopped()
	for stage_id in _stage_nodes:
		var panel: PanelContainer = _stage_nodes[stage_id]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = _builder.compute_node_bg_color(stage_id, stopped)


# --- 땅거미 아이콘 갱신 (3-5-b) ---


func _on_spider_state_changed(_arg) -> void:
	if _visible:
		_refresh_spider_icons()


## 땅거미가 점유한 스테이지 위에 ⚠ 아이콘을 배치한다.
func _refresh_spider_icons() -> void:
	for child in _spider_container.get_children():
		child.queue_free()
	_spider_icons.clear()

	var active: Array = DuskSpiderSystem.get_active_stages()
	for stage_id in active:
		if not _stage_positions.has(stage_id):
			continue
		var icon: Label = _builder.create_spider_icon(_stage_positions[stage_id])
		_spider_container.add_child(icon)
		_spider_icons[stage_id] = icon

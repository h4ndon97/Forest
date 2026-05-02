extends CanvasLayer

## 월드맵 UI. 발견한 거점과 스테이지를 노드그래프로 표시한다.
## 발견한 거점을 선택하여 패스트트래블할 수 있다.
## 독립 Autoload CanvasLayer로 동작한다.
## pause를 사용하지 않음 — 시간 전파/애니메이션은 유지, 플레이어 입력만 차단.

const GraphBuilderScript = preload("res://src/ui/menus/world_map/world_map_graph_builder.gd")
const ZoneLayoutScript = preload("res://src/ui/menus/world_map/world_map_zone_layout.gd")
const DetailPanelScript = preload("res://src/ui/menus/world_map/world_map_detail_panel.gd")
const InputRouterScript = preload("res://src/ui/menus/world_map/world_map_input_router.gd")
const NodeHoverScript = preload("res://src/ui/menus/world_map/world_map_node_hover.gd")
const PolygonRendererScript = preload(
	"res://src/ui/menus/world_map/world_map_zone_polygon_renderer.gd"
)
const SELECTED_COLOR := Color(1.0, 1.0, 1.0)

# 열기 모드 — 거점 포털 진입 시 FAST_TRAVEL, M키 상시 열람 시 VIEW_ONLY.
const MODE_FAST_TRAVEL: int = 0
const MODE_VIEW_ONLY: int = 1

var _visible: bool = false
var _builder: Node
var _zone_layout: Node
var _input_router: Node
var _node_hover: Node
var _polygon_renderer: Node
var _polygon_container: Control
var _bg: ColorRect
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
var _open_mode: int = MODE_FAST_TRAVEL
var _detail_show: bool = false  # view-only 초기엔 숨김. 사용자가 ←→ 누를 때 표시.
var _hover_id: String = ""  # 마우스 호버 중인 stage_id. 비면 selection fallback.


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

	_input_router = Node.new()
	_input_router.name = "InputRouter"
	_input_router.set_script(InputRouterScript)
	add_child(_input_router)

	_node_hover = Node.new()
	_node_hover.name = "NodeHover"
	_node_hover.set_script(NodeHoverScript)
	add_child(_node_hover)

	_polygon_renderer = Node.new()
	_polygon_renderer.name = "PolygonRenderer"
	_polygon_renderer.set_script(PolygonRendererScript)
	add_child(_polygon_renderer)

	_build_ui_frame()
	EventBus.world_map_opened.connect(_on_open)
	EventBus.time_flow_started.connect(_on_time_signal)
	EventBus.time_flow_stopped.connect(_on_time_signal)
	EventBus.current_hour_changed.connect(_on_time_signal)
	EventBus.dusk_spider_spawned.connect(_on_spider_state_changed)
	EventBus.dusk_spider_arrived.connect(_on_spider_state_changed)
	EventBus.dusk_spider_defeated.connect(_on_spider_state_changed)


# --- 공개 API (input_router/portal 호출) ---


func is_open() -> bool:
	return _visible


func has_selectables() -> bool:
	return not _selectable_ids.is_empty()


func get_open_mode() -> int:
	return _open_mode


func set_open_mode(mode: int) -> void:
	_open_mode = mode


func get_hover_id() -> String:
	return _hover_id


func set_hover_id(stage_id: String) -> void:
	if _hover_id == stage_id:
		return
	_hover_id = stage_id
	if _visible:
		_update_selection_highlight()


# --- UI 구축 ---


func _build_ui_frame() -> void:
	_bg = ColorRect.new()
	_bg.name = "BG"
	_bg.color = Color(0, 0, 0, 0.85)
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.position = Vector2(170, 346)
	_hint_label.size = Vector2(300, 12)
	_hint_label.add_theme_font_size_override("font_size", 8)
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(_hint_label)

	_polygon_container = _make_container("ZonePolygons")
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
	var containers: Array = [
		_polygon_container, _node_container, _line_container, _spider_container, _zone_container
	]
	for c in containers:
		for child in c.get_children():
			child.queue_free()
	_stage_nodes.clear()
	_stage_positions.clear()
	_spider_icons.clear()
	_selectable_ids.clear()
	_hover_id = ""

	_polygon_renderer.build(_polygon_container)
	var result: Dictionary = _builder.build_all(_node_container, _line_container)
	_stage_nodes = result["stage_nodes"]
	_stage_positions = result["stage_positions"]
	_node_hover.attach(_stage_nodes)

	var discovered: Array = StageSystem.get_discovered_checkpoints()
	var current: String = StageSystem.get_current_stage_id()
	for cp_id in discovered:
		if cp_id != current and _stage_positions.has(cp_id):
			_selectable_ids.append(cp_id)

	_spider_icons = _builder.refresh_spider_icons(_spider_container, _stage_positions)
	_zone_layout.build_overlay(_zone_container, result["zone_populated"])
	_selected_index = 0
	_update_selection_highlight()
	_update_hint_label()


# --- 네비게이션 ---


func navigate(direction: int) -> void:
	if _selectable_ids.is_empty():
		return
	_detail_show = true
	_selected_index = wrapi(_selected_index + direction, 0, _selectable_ids.size())
	_update_selection_highlight()


func _update_selection_highlight() -> void:
	for stage_id in _stage_nodes:
		var dot: PanelContainer = _stage_nodes[stage_id]
		var data: StageData = StageSystem.get_stage_data(stage_id)
		if not data:
			continue
		var style: StyleBoxFlat = dot.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = _builder.get_border_color(stage_id, data)
			style.set_border_width_all(2)

	var detail_id: String = _resolve_detail_target()
	if detail_id.is_empty():
		_detail_panel.hide_panel()
		return
	if _stage_nodes.has(detail_id):
		var dot: PanelContainer = _stage_nodes[detail_id]
		var style: StyleBoxFlat = dot.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = SELECTED_COLOR
			style.set_border_width_all(3)
	_detail_panel.show_for(detail_id, _stage_positions.get(detail_id, Vector2.ZERO))


func _resolve_detail_target() -> String:
	if not _hover_id.is_empty() and _stage_nodes.has(_hover_id):
		return _hover_id
	if _detail_show and not _selectable_ids.is_empty():
		return _selectable_ids[_selected_index]
	return ""


func _update_hint_label() -> void:
	if _open_mode == MODE_VIEW_ONLY:
		if _selectable_ids.is_empty():
			_hint_label.text = "[F/ESC/M] 닫기"
		else:
			_hint_label.text = "[←→] 거점 보기  [F/ESC/M] 닫기"
	elif _selectable_ids.is_empty():
		_hint_label.text = "[F/ESC/M] 닫기"
	else:
		_hint_label.text = "[←→] 거점 선택  [↑] 이동  [F/ESC/M] 닫기"


func travel_to_selected() -> void:
	if _selectable_ids.is_empty():
		return
	var target_id: String = _selectable_ids[_selected_index]
	_visible = false
	visible = false
	_open_mode = MODE_FAST_TRAVEL
	EventBus.world_map_closed.emit()
	EventBus.stage_transition_requested.emit(target_id, "checkpoint", {})


# --- 열기/닫기 ---


func _on_open() -> void:
	if _visible:
		return
	_visible = true
	visible = true
	_detail_show = (_open_mode == MODE_FAST_TRAVEL)
	_rebuild_graph()


func close_world_map() -> void:
	if not _visible:
		return
	_visible = false
	visible = false
	_open_mode = MODE_FAST_TRAVEL
	EventBus.world_map_closed.emit()


# --- 시간 오버레이 갱신 (graph_builder 위임) ---


func _on_time_signal(_hour: float) -> void:
	if _visible and _builder:
		_builder.refresh_all_node_bg_colors(_stage_nodes)


# --- 땅거미 아이콘 갱신 (graph_builder 위임) ---


func _on_spider_state_changed(_arg) -> void:
	if _visible and _builder:
		_spider_icons = _builder.refresh_spider_icons(_spider_container, _stage_positions)

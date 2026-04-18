extends CanvasLayer

## 디버그용 키맵 확인 HUD. F1(debug_keybind_hud)로 토글.
## InputMap을 자동 순회하여 카테고리별로 표시. 키 변경 시 UI 자동 동기화.

const TOGGLE_ACTION := "debug_keybind_hud"

const CATEGORIES: Array = [
	{
		"title": "이동",
		"actions": ["move_left", "move_right", "move_up", "move_down", "jump", "dash", "light_dash"]
	},
	{"title": "전투 · 스킬", "actions": ["attack", "skill_1", "skill_2", "skill_3", "skill_4"]},
	{"title": "시간 · 등불", "actions": ["time_manipulate", "lantern"]},
	{
		"title": "상호작용 · 소비",
		"actions": ["interact", "interact_environment", "consumable_1", "consumable_2"]
	},
	{
		"title": "메뉴 · 디버그",
		"actions": ["inventory", "map", "debug_delete_save", "debug_keybind_hud"]
	},
]

const ACTION_LABELS: Dictionary = {
	"move_left": "왼쪽 이동",
	"move_right": "오른쪽 이동",
	"move_up": "위 / 사다리 오름",
	"move_down": "아래 / 사다리 내림",
	"jump": "점프",
	"dash": "대쉬",
	"light_dash": "빛 대쉬",
	"attack": "공격",
	"skill_1": "스킬 1",
	"skill_2": "스킬 2",
	"skill_3": "스킬 3",
	"skill_4": "스킬 4",
	"time_manipulate": "시간 조작",
	"lantern": "등불",
	"interact": "상호작용",
	"interact_environment": "환경 조작",
	"consumable_1": "소비 아이템 1",
	"consumable_2": "소비 아이템 2",
	"inventory": "인벤토리",
	"map": "맵",
	"debug_delete_save": "[디버그] 세이브 삭제",
	"debug_keybind_hud": "[디버그] 키맵 토글",
}

var _panel: PanelContainer
var _visible: bool = false


func _ready() -> void:
	layer = 100
	_build_ui()
	set_process_unhandled_input(true)
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		_visible = not _visible
		_panel.visible = _visible
		if _visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.offset_left = -260.0
	_panel.offset_right = -8.0
	_panel.offset_top = 8.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.10, 0.88)
	style.border_color = Color(0.55, 0.62, 0.70, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "Body"
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "키 할당 (F1로 닫기)"
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	title.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title)

	for category: Dictionary in CATEGORIES:
		var header := Label.new()
		header.text = "— " + String(category["title"])
		header.add_theme_color_override("font_color", Color(0.68, 0.80, 0.95))
		header.add_theme_font_size_override("font_size", 9)
		vbox.add_child(header)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 1)
		grid.name = "Grid_" + String(category["title"])
		vbox.add_child(grid)

	add_child(_panel)


func _refresh() -> void:
	for category: Dictionary in CATEGORIES:
		var grid_name := "Grid_" + String(category["title"])
		var grid: GridContainer = _panel.get_node("Body/" + grid_name)
		for child in grid.get_children():
			child.queue_free()

		for action_name: String in category["actions"]:
			if not InputMap.has_action(action_name):
				continue

			var name_label := Label.new()
			name_label.text = ACTION_LABELS.get(action_name, action_name)
			name_label.add_theme_font_size_override("font_size", 8)
			name_label.add_theme_color_override("font_color", Color(0.88, 0.90, 0.93))
			grid.add_child(name_label)

			var key_label := Label.new()
			key_label.text = _format_keys(action_name)
			key_label.add_theme_font_size_override("font_size", 8)
			key_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
			key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(key_label)


func _format_keys(action_name: String) -> String:
	var parts: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event: InputEventKey = event
			var keycode: int = key_event.physical_keycode
			if keycode == 0:
				keycode = key_event.keycode
			parts.append(OS.get_keycode_string(keycode))
	if parts.is_empty():
		return "—"
	return " / ".join(parts)

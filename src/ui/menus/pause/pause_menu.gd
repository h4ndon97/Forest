extends CanvasLayer

## 일시정지 메뉴 Autoload.
## `pause` 액션(ESC)으로 토글. 다른 UI 열려 있거나 대화/전환 중이면 무시.
## 진입 시 get_tree().paused = true + 어두운 베일 + BGM -12dB.
## PROCESS_MODE_ALWAYS로 트리 pause 중에도 입력/UI 갱신.

const ControllerScript = preload("res://src/ui/menus/pause/pause_menu_controller.gd")
const SettingsPanelScript = preload("res://src/ui/menus/title/title_settings_panel.gd")
const MenuFrameScript = preload("res://src/ui/common/menu_frame.gd")
const BGM_DUCK_DB: float = -12.0
const FRAME_SIZE := Vector2(240, 320)
const TITLE_LABEL_TEXT := "일시정지"

var _is_open: bool = false
var _in_settings: bool = false
var _in_game: bool = false
var _in_transition: bool = false
var _dialog_active_count: int = 0
var _frame: MenuFrame
var _controller: Node
var _settings_panel: Node
var _master_bus_index: int = -1
var _original_master_db: float = 0.0


func _ready() -> void:
	layer = 95  # world_map(90) / shop(85) / inventory(80) 위
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master_bus_index = AudioServer.get_bus_index("Master")
	_build_ui()
	EventBus.dialogue_started.connect(_on_dialog_started)
	EventBus.dialogue_finished.connect(_on_dialog_finished)
	EventBus.game_start_requested.connect(_on_game_start_requested)
	EventBus.return_to_title_requested.connect(_on_return_to_title_requested)
	EventBus.stage_transition_started.connect(_on_transition_started)
	EventBus.stage_transition_completed.connect(_on_transition_completed)


func _process(_delta: float) -> void:
	if _in_settings:
		return  # settings panel이 ui_cancel 소비
	if not Input.is_action_just_pressed("pause"):
		return
	if _is_open:
		_close()
		return
	if _is_blocked():
		return
	_open()


func is_open() -> bool:
	return _is_open


# --- 내부 ---


func _is_blocked() -> bool:
	if not _in_game or _in_transition or _dialog_active_count > 0:
		return true
	return InventoryMenu.is_open() or WorldMapUI.is_open() or ShopMenu.is_open()


func _on_dialog_started(_npc_id: String) -> void:
	_dialog_active_count += 1


func _on_dialog_finished(_npc_id: String) -> void:
	_dialog_active_count = max(0, _dialog_active_count - 1)


func _on_game_start_requested(_is_new_game: bool) -> void:
	_in_game = true
	_dialog_active_count = 0
	if _is_open:
		_close()


func _on_return_to_title_requested() -> void:
	_in_game = false


func _on_transition_started(_from: String, _to: String) -> void:
	_in_transition = true


func _on_transition_completed(_stage_id: String) -> void:
	_in_transition = false


func _build_ui() -> void:
	_frame = MenuFrameScript.new() as MenuFrame
	_frame.setup(self, FRAME_SIZE, TITLE_LABEL_TEXT)
	_build_controller()
	_build_settings()


func _build_controller() -> void:
	_controller = Node.new()
	_controller.name = "MenuController"
	_controller.set_script(ControllerScript)
	add_child(_controller)
	_controller.setup(self)
	_controller.resume_selected.connect(_on_resume)
	_controller.settings_selected.connect(_on_settings)
	_controller.return_title_selected.connect(_on_return_title)


func _build_settings() -> void:
	_settings_panel = Node.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.set_script(SettingsPanelScript)
	add_child(_settings_panel)
	_settings_panel.setup(self)
	_settings_panel.closed.connect(_on_settings_closed)


func _open() -> void:
	_is_open = true
	visible = true
	get_tree().paused = true
	if _master_bus_index >= 0:
		_original_master_db = AudioServer.get_bus_volume_db(_master_bus_index)
		AudioServer.set_bus_volume_db(_master_bus_index, _original_master_db + BGM_DUCK_DB)
	_controller.set_input_active(true)
	_controller.set_selected_index(0)
	EventBus.game_paused.emit()


func _close() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false
	_controller.set_input_active(false)
	_restore_bgm()
	EventBus.game_resumed.emit()


func _restore_bgm() -> void:
	if _master_bus_index >= 0:
		AudioServer.set_bus_volume_db(_master_bus_index, _original_master_db)


func _on_resume() -> void:
	_close()


func _on_settings() -> void:
	_controller.set_input_active(false)
	_in_settings = true
	_settings_panel.open()


func _on_settings_closed() -> void:
	_in_settings = false
	_controller.set_input_active(true)


func _on_return_title() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false
	_controller.set_input_active(false)
	_restore_bgm()
	EventBus.game_resumed.emit()
	EventBus.return_to_title_requested.emit()

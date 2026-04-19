extends Node2D

## 타이틀 화면 루트 컨트롤러.
## 배경/로고/메뉴/확인 다이얼로그/설정 패널을 조립하고,
## 메뉴 시그널을 받아 EventBus.game_start_requested 발행 + 페이드 아웃 처리.

const MenuControllerScript = preload("res://src/ui/menus/title/title_menu_controller.gd")
const ConfirmDialogScript = preload("res://src/ui/menus/title/title_confirm_dialog.gd")
const SettingsPanelScript = preload("res://src/ui/menus/title/title_settings_panel.gd")
const BackgroundScript = preload("res://src/ui/menus/title/title_background.gd")

const FADE_DURATION: float = 0.8
const FADE_OUT_DURATION: float = 0.4
const BREATH_PERIOD: float = 1.0
const BREATH_AMPLITUDE: float = 0.05
const LOGO_COLOR := Color("F2CC66")
const LOGO_FONT_SIZE: int = 40

@export var debug_auto_start: bool = false

var _background: Node
var _menu_controller: Node
var _confirm_dialog: Node
var _settings_panel: Node
var _logo_label: Label
var _fade_rect: ColorRect
var _has_save: bool = false
var _logo_time: float = 0.0
var _starting: bool = false


func _ready() -> void:
	_has_save = StageSystem.has_save_file()
	_hide_game_hud.call_deferred()
	_build_background()
	_build_foreground()
	_build_menu()
	_build_overlay()
	_build_settings()
	_menu_controller.set_continue_enabled(_has_save)
	_fade_in()
	if debug_auto_start:
		_start_game(_has_save)


func _hide_game_hud() -> void:
	get_tree().call_group("game_hud", "set_visible", false)


func _process(delta: float) -> void:
	_logo_time += delta
	_update_logo_breath()
	if _starting:
		return
	if Input.is_action_just_pressed("debug_skip_title"):
		_start_game(_has_save)


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BackgroundLayer"
	layer.layer = 0
	add_child(layer)
	_background = Node.new()
	_background.name = "Background"
	_background.set_script(BackgroundScript)
	layer.add_child(_background)


func _build_foreground() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ForegroundLayer"
	layer.layer = 10
	add_child(layer)
	_logo_label = Label.new()
	_logo_label.text = "시간이 멈춘 숲"
	_logo_label.add_theme_font_size_override("font_size", LOGO_FONT_SIZE)
	_logo_label.add_theme_color_override("font_color", LOGO_COLOR)
	_logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_logo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_logo_label.anchor_left = 0.0
	_logo_label.anchor_right = 1.0
	_logo_label.anchor_top = 0.18
	_logo_label.anchor_bottom = 0.18
	_logo_label.offset_top = -40.0
	_logo_label.offset_bottom = 40.0
	layer.add_child(_logo_label)


func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MenuLayer"
	layer.layer = 20
	add_child(layer)
	_menu_controller = Node.new()
	_menu_controller.name = "MenuController"
	_menu_controller.set_script(MenuControllerScript)
	layer.add_child(_menu_controller)
	_menu_controller.setup(layer)
	_menu_controller.new_game_selected.connect(_on_new_game)
	_menu_controller.continue_selected.connect(_on_continue)
	_menu_controller.settings_selected.connect(_on_settings)
	_menu_controller.quit_selected.connect(_on_quit)


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "OverlayLayer"
	layer.layer = 90
	add_child(layer)
	_confirm_dialog = Node.new()
	_confirm_dialog.name = "ConfirmDialog"
	_confirm_dialog.set_script(ConfirmDialogScript)
	layer.add_child(_confirm_dialog)
	_confirm_dialog.setup(layer)
	_confirm_dialog.confirmed.connect(_on_confirm_accepted)
	_confirm_dialog.cancelled.connect(_on_confirm_cancelled)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_settings() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SettingsLayer"
	layer.layer = 30
	add_child(layer)
	_settings_panel = Node.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.set_script(SettingsPanelScript)
	layer.add_child(_settings_panel)
	_settings_panel.setup(layer)
	_settings_panel.closed.connect(_on_settings_closed)


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)


func _update_logo_breath() -> void:
	if not _logo_label:
		return
	var breath: float = 0.5 + 0.5 * sin(_logo_time * TAU / BREATH_PERIOD)
	var alpha: float = lerpf(1.0 - BREATH_AMPLITUDE, 1.0, breath)
	_logo_label.modulate.a = alpha


func _on_new_game() -> void:
	if _has_save:
		_menu_controller.set_input_active(false)
		_confirm_dialog.show_dialog("기존 세이브가 삭제됩니다.\n계속하시겠습니까?")
	else:
		_start_game(false)


func _on_continue() -> void:
	_start_game(true)


func _on_confirm_accepted() -> void:
	_start_game(false)


func _on_confirm_cancelled() -> void:
	_menu_controller.set_input_active(true)


func _on_settings() -> void:
	_menu_controller.set_input_active(false)
	_settings_panel.open()


func _on_settings_closed() -> void:
	_menu_controller.set_input_active(true)


func _on_quit() -> void:
	get_tree().quit()


func _start_game(is_continue: bool) -> void:
	if _starting:
		return
	_starting = true
	_menu_controller.set_input_active(false)
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_OUT_DURATION)
	await tween.finished
	get_tree().call_group("game_hud", "set_visible", true)
	EventBus.game_start_requested.emit(not is_continue)

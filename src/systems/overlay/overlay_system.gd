extends CanvasLayer

## Phase 3-7 Pass 1 — 전역 오버레이 Autoload.
## 최상단 CanvasLayer에 포스트프로세스/비네트/스크린플래시 슬롯을 관리한다.
## Pass 1: 슬롯 구조 + 스크린플래시 즉시 사용 가능. 본격 셰이더는 Pass 3/4에서.

const OverlayVignetteScript = preload("res://src/systems/overlay/overlay_vignette.gd")

const OVERLAY_LAYER: int = 100

var _post_process: ColorRect
var _vignette: ColorRect
var _screen_flash: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_post_process_slot()
	_build_vignette_slot()
	_build_screen_flash_slot()


# === 포스트프로세스 (Pass 3에서 시간정지 톤 적용) ===


func set_post_process_shader(shader: Shader) -> void:
	if _post_process == null:
		return
	if shader == null:
		_post_process.material = null
		_post_process.visible = false
		return
	var mat: ShaderMaterial = _post_process.material
	if mat == null or mat.shader != shader:
		mat = ShaderMaterial.new()
		mat.shader = shader
		_post_process.material = mat
	_post_process.visible = true


func set_post_process_param(param_name: StringName, value: Variant) -> void:
	if _post_process == null or _post_process.material == null:
		return
	(_post_process.material as ShaderMaterial).set_shader_parameter(param_name, value)


# === 비네트 (Pass 4에서 땅거미 거리 보간) ===


func set_vignette_color(color_value: Color, alpha: float) -> void:
	if _vignette == null:
		return
	_vignette.set_vignette(color_value, alpha)


func clear_vignette() -> void:
	if _vignette == null:
		return
	_vignette.clear()


# === 스크린 플래시 (Pass 1에서 즉시 사용) ===


func flash_screen(color_value: Color, duration: float) -> void:
	if _screen_flash == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_screen_flash.color = color_value
	_screen_flash.visible = true
	var clear_color: Color = color_value
	clear_color.a = 0.0
	_flash_tween = create_tween()
	_flash_tween.set_ignore_time_scale(true)
	_flash_tween.tween_property(_screen_flash, "color", clear_color, duration)
	_flash_tween.tween_callback(func() -> void: _screen_flash.visible = false)


# === 내부 ===


func _build_post_process_slot() -> void:
	_post_process = ColorRect.new()
	_post_process.name = "PostProcess"
	_post_process.color = Color(1.0, 1.0, 1.0, 1.0)
	_post_process.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_process.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_post_process.visible = false
	add_child(_post_process)


func _build_vignette_slot() -> void:
	_vignette = ColorRect.new()
	_vignette.name = "Vignette"
	_vignette.set_script(OverlayVignetteScript)
	add_child(_vignette)


func _build_screen_flash_slot() -> void:
	_screen_flash = ColorRect.new()
	_screen_flash.name = "ScreenFlash"
	_screen_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_flash.visible = false
	add_child(_screen_flash)

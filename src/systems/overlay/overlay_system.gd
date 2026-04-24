extends CanvasLayer

## Phase 3-7 Pass 1 — 전역 오버레이 Autoload.
## 최상단 CanvasLayer에 포스트프로세스/비네트/스크린플래시 슬롯을 관리한다.
## Pass 1: 슬롯 구조 + 스크린플래시 즉시 사용 가능. 본격 셰이더는 Pass 3/4에서.

const OverlayVignetteScript = preload("res://src/systems/overlay/overlay_vignette.gd")
const OverlayHpCrackScript = preload("res://src/systems/overlay/overlay_hp_crack.gd")
const DISSOLVE_SHADER: Shader = preload("res://assets/shaders/effects/dissolve_transition.gdshader")

const OVERLAY_LAYER: int = 100
const DISSOLVE_WEIGHT_PARAM: StringName = &"weight"

var _post_process: ColorRect
var _vignette: ColorRect
var _hp_crack: OverlayHpCrack
var _dissolve: ColorRect
var _dissolve_material: ShaderMaterial
var _dissolve_tween: Tween
var _screen_flash: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_post_process_slot()
	_build_vignette_slot()
	_build_hp_crack_slot()
	_build_dissolve_slot()
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


# === HP 크랙 (Pass 5 Step 1 — 빈사 화면 크랙) ===


func set_hp_crack(alpha: float) -> void:
	if _hp_crack == null:
		return
	_hp_crack.set_alpha(alpha)


func clear_hp_crack() -> void:
	if _hp_crack == null:
		return
	_hp_crack.clear()


# === 디졸브 (Pass 5 Step 1 — 메뉴/씬 전환) ===


## cover=true: weight 0→1 (화면 덮기). cover=false: weight 1→0 (화면 걷기).
func play_dissolve(duration: float, cover: bool) -> void:
	if _dissolve == null or _dissolve_material == null:
		return
	if _dissolve_tween != null and _dissolve_tween.is_valid():
		_dissolve_tween.kill()
	_dissolve.visible = true
	var current_raw: Variant = _dissolve_material.get_shader_parameter(DISSOLVE_WEIGHT_PARAM)
	var current_weight: float = float(current_raw) if current_raw != null else 0.0
	var target: float = 1.0 if cover else 0.0
	if duration <= 0.0:
		_apply_dissolve_weight(target)
		_dissolve.visible = cover
		return
	_dissolve_tween = create_tween()
	_dissolve_tween.set_ignore_time_scale(true)
	_dissolve_tween.tween_method(_apply_dissolve_weight, current_weight, target, duration)
	if not cover:
		_dissolve_tween.tween_callback(_on_dissolve_reveal_complete)


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


func _build_hp_crack_slot() -> void:
	_hp_crack = OverlayHpCrackScript.new()
	_hp_crack.name = "HpCrack"
	add_child(_hp_crack)


func _build_dissolve_slot() -> void:
	_dissolve = ColorRect.new()
	_dissolve.name = "Dissolve"
	_dissolve.color = Color.WHITE
	_dissolve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dissolve.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dissolve_material = ShaderMaterial.new()
	_dissolve_material.shader = DISSOLVE_SHADER
	_dissolve_material.set_shader_parameter(DISSOLVE_WEIGHT_PARAM, 0.0)
	_dissolve.material = _dissolve_material
	_dissolve.visible = false
	add_child(_dissolve)


func _apply_dissolve_weight(value: float) -> void:
	if _dissolve_material == null:
		return
	_dissolve_material.set_shader_parameter(DISSOLVE_WEIGHT_PARAM, value)


func _on_dissolve_reveal_complete() -> void:
	if _dissolve != null:
		_dissolve.visible = false


func _build_screen_flash_slot() -> void:
	_screen_flash = ColorRect.new()
	_screen_flash.name = "ScreenFlash"
	_screen_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_flash.visible = false
	add_child(_screen_flash)

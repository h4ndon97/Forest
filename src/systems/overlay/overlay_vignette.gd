class_name OverlayVignette
extends ColorRect

## Phase 3-7 Pass 4 — 비네트 슬롯(원형 그라데이션 셰이더 기반).
## EffectsDuskWarning이 set_vignette(color, alpha)로 색·알파를 갱신한다.
## 색의 alpha는 셰이더 vignette_color.a로 전달되어 가장자리 농도를 제어.

const SHADER: Shader = preload("res://assets/shaders/effects/vignette_radial.gdshader")

const PARAM_COLOR: StringName = &"vignette_color"
const PARAM_INNER: StringName = &"inner_radius"
const PARAM_OUTER: StringName = &"outer_radius"

var _current_color: Color = Color(0.0, 0.0, 0.0, 0.0)
var _material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	_apply_color()


func set_vignette(color_value: Color, alpha: float) -> void:
	_current_color = color_value
	_current_color.a = clampf(alpha, 0.0, 1.0)
	_apply_color()


func set_radius(inner: float, outer: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter(PARAM_INNER, clampf(inner, 0.0, 1.0))
	_material.set_shader_parameter(PARAM_OUTER, clampf(outer, 0.0, 1.5))


func clear() -> void:
	_current_color = Color(0.0, 0.0, 0.0, 0.0)
	_apply_color()


# === 내부 ===


func _apply_color() -> void:
	if _material == null:
		return
	_material.set_shader_parameter(PARAM_COLOR, _current_color)
	visible = _current_color.a > 0.0

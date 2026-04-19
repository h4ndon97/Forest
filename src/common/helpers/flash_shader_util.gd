class_name FlashShaderUtil
extends RefCounted

## Phase 3-7 Pass 1 — 힛플래시 셰이더 머티리얼 유틸.
## CanvasItem(Sprite2D / AnimatedSprite2D 등)에 ShaderMaterial을 부착하고
## flash_amount / flash_color uniform을 조작한다.
## Shader 리소스는 EffectsSystem에서 단일 인스턴스로 보관, 머티리얼은 타겟별로 생성.

const FLASH_AMOUNT_PARAM: StringName = &"flash_amount"
const FLASH_COLOR_PARAM: StringName = &"flash_color"


## 타겟이 flash 셰이더를 사용 중이 아니면 머티리얼을 부착한다.
## 이미 동일 셰이더를 쓰고 있으면 재사용. 다른 머티리얼은 덮어쓴다(Pass 1 단순화).
static func ensure_material(target: CanvasItem, shader: Shader) -> ShaderMaterial:
	if target == null or shader == null:
		return null
	var existing: Material = target.material
	if existing is ShaderMaterial and (existing as ShaderMaterial).shader == shader:
		return existing as ShaderMaterial
	var mat := ShaderMaterial.new()
	mat.shader = shader
	target.material = mat
	return mat


static func set_flash(material: ShaderMaterial, color_value: Color, amount: float) -> void:
	if material == null:
		return
	material.set_shader_parameter(FLASH_COLOR_PARAM, color_value)
	material.set_shader_parameter(FLASH_AMOUNT_PARAM, clampf(amount, 0.0, 1.0))


static func clear_flash(material: ShaderMaterial) -> void:
	if material == null:
		return
	material.set_shader_parameter(FLASH_AMOUNT_PARAM, 0.0)

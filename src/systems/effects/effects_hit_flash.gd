class_name EffectsHitFlash
extends RefCounted

## Phase 3-7 Pass 1 — 힛플래시 실행기.
## CanvasItem 타겟에 ShaderMaterial을 보장하고 flash_amount Tween을 0→peak→0으로 구동.
## 같은 타겟에 진행 중인 Tween이 있으면 kill 후 재시작 (누적 방지).

const FlashUtil = preload("res://src/common/helpers/flash_shader_util.gd")

var _shader: Shader
var _attack_ratio: float
var _intensity_mult: float
## target instance_id → 진행 중인 Tween. 다음 호출 시 kill.
var _active_tweens: Dictionary = {}


func _init(shader: Shader, attack_ratio: float = 0.25, intensity_mult: float = 1.0) -> void:
	_shader = shader
	_attack_ratio = clampf(attack_ratio, 0.05, 0.95)
	_intensity_mult = maxf(intensity_mult, 0.0)


func set_intensity_mult(value: float) -> void:
	_intensity_mult = maxf(value, 0.0)


## 메인 API — target에 flash_amount 0→1→0 Tween 적용.
## owner_node: Tween의 owner (보통 EffectsSystem). target 자체에 만들면 시각 갱신과 충돌 가능.
func play(owner_node: Node, target: CanvasItem, color_value: Color, duration: float) -> void:
	if target == null or _shader == null or duration <= 0.0:
		return
	if _intensity_mult <= 0.0:
		return
	var mat: ShaderMaterial = FlashUtil.ensure_material(target, _shader)
	if mat == null:
		return

	var key: int = target.get_instance_id()
	var prev: Tween = _active_tweens.get(key, null) as Tween
	if prev != null and prev.is_valid():
		prev.kill()

	mat.set_shader_parameter(FlashUtil.FLASH_COLOR_PARAM, color_value)
	mat.set_shader_parameter(FlashUtil.FLASH_AMOUNT_PARAM, 0.0)

	var peak: float = clampf(_intensity_mult, 0.0, 1.0)
	var rise: float = duration * _attack_ratio
	var fall: float = duration - rise

	var tween: Tween = owner_node.create_tween()
	tween.tween_method(_set_amount.bind(mat), 0.0, peak, rise)
	tween.tween_method(_set_amount.bind(mat), peak, 0.0, fall)
	tween.finished.connect(_on_tween_finished.bind(key))
	_active_tweens[key] = tween


func _set_amount(value: float, mat: ShaderMaterial) -> void:
	if mat == null:
		return
	mat.set_shader_parameter(FlashUtil.FLASH_AMOUNT_PARAM, value)


func _on_tween_finished(key: int) -> void:
	_active_tweens.erase(key)

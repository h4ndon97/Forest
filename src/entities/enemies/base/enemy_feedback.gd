extends Node

## 적 피격/경직/사망 시각 반영 (교보재).
##
## 기능:
## - 피격 플래시: EffectsSystem(셰이더 기반)에 위임 (Phase 3-7 Pass 1)
## - 경직 흔들기: X축 랜덤 오프셋 + 감쇠 (0.3s)
## - 사망 디졸브: 페이드 + 축소 (0.4s)
##
## 경직/사망은 modulate / position 만 건드리며 전투 로직과 무관하다.
## 픽셀아트 교체 후에도 동일하게 적용된다.

const SHAKE_DURATION: float = 0.3
const SHAKE_AMPLITUDE: float = 2.5
const SHAKE_INTERVAL: float = 0.04
const DEATH_DURATION: float = 0.4
const DEATH_SCALE := Vector2(0.6, 0.6)

var _owner: CanvasItem
## flash 셰이더는 AnimatedSprite2D에 부착해야 한다 (modulate=대상이 동일 노드)
var _flash_target: CanvasItem
var _animation_comp: Node
var _base_modulate: Color = Color.WHITE
var _shake_tween: Tween
var _death_tween: Tween
var _shake_accum: float = 0.0


func setup(p_owner: CanvasItem, p_animation_comp: Node) -> void:
	_owner = p_owner
	_animation_comp = p_animation_comp
	if _owner != null:
		_base_modulate = _owner.modulate
		_flash_target = _owner.get_node_or_null("AnimatedSprite2D") as CanvasItem
		if _flash_target == null:
			_flash_target = _owner


func play_hit_flash() -> void:
	if _flash_target == null:
		return
	var cfg: EffectsConfigData = EffectsSystem.get_config()
	EffectsSystem.request_hit_flash(_flash_target, cfg.enemy_hit_color, cfg.enemy_hit_duration)


func play_stagger_shake() -> void:
	if _animation_comp == null or not _animation_comp.has_method("set_shake_offset"):
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_accum = 0.0
	_shake_tween = create_tween()
	_shake_tween.tween_method(_apply_decayed_shake, 0.0, 1.0, SHAKE_DURATION)
	_shake_tween.tween_callback(_clear_shake)


func play_death_dissolve() -> Signal:
	if _owner == null:
		return _finished_now()
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_clear_shake()
	var target_modulate: Color = _base_modulate
	target_modulate.a = 0.0
	_death_tween = create_tween().set_parallel(true)
	_death_tween.tween_property(_owner, "modulate", target_modulate, DEATH_DURATION)
	_death_tween.tween_property(_owner, "scale", DEATH_SCALE, DEATH_DURATION)
	return _death_tween.finished


func _apply_decayed_shake(t: float) -> void:
	_shake_accum += get_process_delta_time()
	if _shake_accum < SHAKE_INTERVAL:
		return
	_shake_accum = 0.0
	var amp: float = SHAKE_AMPLITUDE * (1.0 - t)
	var x: float = randf_range(-amp, amp)
	_animation_comp.set_shake_offset(Vector2(x, 0.0))


func _clear_shake() -> void:
	if _animation_comp != null and _animation_comp.has_method("set_shake_offset"):
		_animation_comp.set_shake_offset(Vector2.ZERO)


func _finished_now() -> Signal:
	var timer: SceneTreeTimer = get_tree().create_timer(0.0)
	return timer.timeout

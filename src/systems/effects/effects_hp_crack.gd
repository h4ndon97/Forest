class_name EffectsHpCrack
extends RefCounted

## Phase 3-7 Pass 5 Step 1 ① — EventBus.health_changed 구독 → 화면 HP 크랙 오버레이.
## threshold 이하 구간에서만 ratio 계산, 그 외엔 0. Tween으로 부드럽게 갱신.

var _host: Node
var _config: EffectsConfigData
var _tween: Tween
var _current_alpha: float = 0.0


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config
	EventBus.health_changed.connect(_on_health_changed)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return
	var hp_ratio: float = current_hp / max_hp
	var ratio: float = 0.0
	if hp_ratio < _config.hp_crack_threshold and _config.hp_crack_threshold > 0.0:
		ratio = 1.0 - hp_ratio / _config.hp_crack_threshold
	var target_alpha: float = clampf(ratio, 0.0, 1.0) * _config.hp_crack_max_alpha
	_apply_alpha_tween(target_alpha)


func _apply_alpha_tween(target_alpha: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		OverlaySystem.set_hp_crack(target_alpha)
		_current_alpha = target_alpha
		return
	_tween = tree.create_tween()
	_tween.set_ignore_time_scale(true)
	_tween.tween_method(
		_apply_step, _current_alpha, target_alpha, _config.hp_crack_transition_duration
	)
	_current_alpha = target_alpha


func _apply_step(value: float) -> void:
	OverlaySystem.set_hp_crack(value)

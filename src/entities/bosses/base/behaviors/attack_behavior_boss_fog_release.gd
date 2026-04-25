extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 P1 안개 방출 (zone2 Mire Mother).
## 짧은 텔레그래프 후 보스 주변 큰 영역 AOE 1회 + 잔존 안개 ColorRect(시각만, 데미지 없음).
## boss_melee_aoe 패턴 답습 — telegraph(예고선) → active(히트박스) → 종료.
## 차이점: active 종료 시 잔존 안개 ColorRect 스폰(8s 페이드 아웃).
## attribute = "shadow" (어둠 속성 분기 → damage_resolver finish_shadow)

const FALLBACK_TELEGRAPH_COLOR := Color(0.55, 0.6, 0.7, 0.4)
const FALLBACK_ACTIVE_COLOR := Color(0.45, 0.5, 0.65, 0.7)
const RESIDUAL_FOG_COLOR := Color(0.6, 0.65, 0.75, 0.35)
const RESIDUAL_FOG_DURATION := 8.0

var _pattern: BossPhasePattern = null
var _telegraph_rect: ColorRect = null
var _active_rect: ColorRect = null

# 0=idle, 1=telegraph, 2=active
var _phase_state: int = 0
var _phase_timer: float = 0.0
var _telegraph_duration: float = 0.7
var _active_duration: float = 0.4

var _current_attack_area: Area2D = null


func setup_with_pattern(
	boss_root: Node2D, base_stats: EnemyStatsData, pattern: BossPhasePattern, attack_index: int = 0
) -> void:
	setup(boss_root, base_stats)
	_pattern = pattern
	if pattern == null:
		return
	var idx: int = attack_index
	if idx < 0 or idx >= pattern.telegraph_durations.size():
		idx = 0
	if not pattern.telegraph_durations.is_empty():
		_telegraph_duration = pattern.telegraph_durations[idx]
	if pattern.hitbox_active_duration > 0.0:
		_active_duration = pattern.hitbox_active_duration
	_create_fallback_visuals()


func on_attack_enter() -> void:
	_cancel_current_attack()
	_phase_state = 1
	_phase_timer = 0.0
	if _telegraph_rect:
		_telegraph_rect.visible = true
	if _active_rect:
		_active_rect.visible = false

	var spec := AttackSpec.new()
	spec.attacker = _enemy_root
	spec.source_group = "boss_attack"
	spec.shape_type = "rect"
	spec.hitbox_size = _pattern.hitbox_size
	spec.hitbox_offset = _pattern.hitbox_offset
	spec.telegraph_duration = _telegraph_duration
	spec.active_duration = _active_duration
	spec.damage = _enemy_root.stats_comp.get_attack()
	spec.is_finish = false
	spec.attribute = "shadow"
	spec.tags = PackedStringArray(["boss", "fog_release"])

	_current_attack_area = CombatSystem.request_attack(spec)


func on_attack_exit() -> void:
	if _phase_state == 2:
		_spawn_residual_fog()
	_phase_state = 0
	_cancel_current_attack()
	if _telegraph_rect:
		_telegraph_rect.visible = false
	if _active_rect:
		_active_rect.visible = false


func on_state_update(delta: float) -> void:
	if _phase_state == 0:
		return
	_phase_timer += delta
	if _phase_state == 1 and _phase_timer >= _telegraph_duration:
		_phase_state = 2
		_phase_timer = 0.0
		if _telegraph_rect:
			_telegraph_rect.visible = false
		if _active_rect:
			_active_rect.visible = true
	elif _phase_state == 2 and _phase_timer >= _active_duration:
		on_attack_exit()


func _cancel_current_attack() -> void:
	if _current_attack_area != null and is_instance_valid(_current_attack_area):
		CombatSystem.cancel_attack(_current_attack_area)
	_current_attack_area = null


func _create_fallback_visuals() -> void:
	if _enemy_root == null or _pattern == null:
		return
	if _telegraph_rect == null:
		_telegraph_rect = ColorRect.new()
		_telegraph_rect.color = FALLBACK_TELEGRAPH_COLOR
		_telegraph_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enemy_root.add_child(_telegraph_rect)
	if _active_rect == null:
		_active_rect = ColorRect.new()
		_active_rect.color = FALLBACK_ACTIVE_COLOR
		_active_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enemy_root.add_child(_active_rect)
	var size: Vector2 = _pattern.hitbox_size
	var offset: Vector2 = _pattern.hitbox_offset - size * 0.5
	for r in [_telegraph_rect, _active_rect]:
		r.size = size
		r.position = offset
		r.visible = false
		r.z_index = 5


func _spawn_residual_fog() -> void:
	if _enemy_root == null or _pattern == null:
		return
	var parent: Node = _enemy_root.get_parent()
	if parent == null:
		return
	var fog := ColorRect.new()
	fog.color = RESIDUAL_FOG_COLOR
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size: Vector2 = _pattern.hitbox_size
	fog.size = size
	fog.position = _enemy_root.global_position + _pattern.hitbox_offset - size * 0.5
	fog.z_index = 4
	parent.add_child(fog)
	var tween := fog.create_tween()
	tween.tween_property(fog, "modulate:a", 0.0, RESIDUAL_FOG_DURATION)
	tween.tween_callback(fog.queue_free)

extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 P1 광역 근접 공격.
## BossPhasePattern에서 hitbox_size/offset/duration + telegraph_durations[0]을 받는다.
## 흐름: ATTACK 진입 → telegraph(예고선 표시) → active(히트박스 ON) → 종료.

const FALLBACK_TELEGRAPH_COLOR := Color(0.95, 0.45, 0.2, 0.4)
const FALLBACK_ACTIVE_COLOR := Color(1.0, 0.65, 0.18, 0.85)

var _pattern: BossPhasePattern = null
var _hitbox_shape_node: CollisionShape2D = null
var _telegraph_rect: ColorRect = null
var _active_rect: ColorRect = null

# 0=idle, 1=telegraph, 2=active
var _phase_state: int = 0
var _phase_timer: float = 0.0
var _telegraph_duration: float = 0.5
var _active_duration: float = 0.4


## PhaseController가 호출. 베이스 setup() 이후 패턴 적용.
func setup_with_pattern(boss_root: Node2D, base_stats: EnemyStatsData,
		hitbox: Area2D, pattern: BossPhasePattern, attack_index: int = 0) -> void:
	setup(boss_root, base_stats, hitbox)
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
	_apply_shape()
	_create_fallback_visuals()


func _on_setup() -> void:
	_hitbox_shape_node = _hitbox.get_node_or_null("HitboxShape") as CollisionShape2D


func on_attack_enter() -> void:
	_phase_state = 1
	_phase_timer = 0.0
	if _telegraph_rect:
		_telegraph_rect.visible = true
	if _active_rect:
		_active_rect.visible = false


func on_attack_exit() -> void:
	_phase_state = 0
	_hitbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)
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
		_hitbox.set_deferred("monitoring", true)
		_hitbox.set_deferred("monitorable", true)
		if _telegraph_rect:
			_telegraph_rect.visible = false
		if _active_rect:
			_active_rect.visible = true
	elif _phase_state == 2 and _phase_timer >= _active_duration:
		on_attack_exit()


func _apply_shape() -> void:
	if _hitbox_shape_node == null or _pattern == null:
		return
	var rect: RectangleShape2D = _hitbox_shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		_hitbox_shape_node.shape = rect
	rect.size = _pattern.hitbox_size
	_hitbox_shape_node.position = _pattern.hitbox_offset


func _create_fallback_visuals() -> void:
	if _hitbox == null or _pattern == null:
		return
	if _telegraph_rect == null:
		_telegraph_rect = ColorRect.new()
		_telegraph_rect.color = FALLBACK_TELEGRAPH_COLOR
		_telegraph_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hitbox.add_child(_telegraph_rect)
	if _active_rect == null:
		_active_rect = ColorRect.new()
		_active_rect.color = FALLBACK_ACTIVE_COLOR
		_active_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hitbox.add_child(_active_rect)
	var size: Vector2 = _pattern.hitbox_size
	var offset: Vector2 = _pattern.hitbox_offset - size * 0.5
	for r in [_telegraph_rect, _active_rect]:
		r.size = size
		r.position = offset
		r.visible = false
		r.z_index = 5

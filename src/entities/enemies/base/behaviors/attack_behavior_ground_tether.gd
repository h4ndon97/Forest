extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 지면 고정 촉수 공격 (zone2 marsh_tendril 등 고정형 적용).
## telegraph 후 긴 사거리 hitbox 활성. ranged의 telegraph + melee의 hitbox 합성.
## telegraph 길이: stats_data.projectile_telegraph 재사용.
## 의도: 적은 이동하지 않고(base_speed=0), 사거리 안에 들어온 플레이어를 공격.
## 시각 단서: telegraph 동안 어두운 ColorRect, active 동안 발광 ColorRect (boss_melee_aoe 패턴 답습).

const _DEFAULT_ACTIVE_DURATION := 0.4
const FALLBACK_TELEGRAPH_COLOR := Color(0.45, 0.30, 0.55, 0.4)
const FALLBACK_ACTIVE_COLOR := Color(0.7, 0.45, 0.85, 0.7)

var _telegraph_timer: float = 0.0
var _pending_strike: bool = false
var _current_attack_area: Area2D = null
var _telegraph_rect: ColorRect = null
var _active_rect: ColorRect = null
# 시각 단계 — CombatSystem이 판정 라이프사이클을 관리하므로 시각 동기화 전용.
# 0=idle, 1=telegraph, 2=active
var _phase_state: int = 0
var _active_timer: float = 0.0


func on_attack_enter() -> void:
	_cancel_current_attack()
	_telegraph_timer = 0.0
	_pending_strike = true
	_phase_state = 1
	_create_fallback_visuals()
	if _telegraph_rect:
		_telegraph_rect.visible = true
	if _active_rect:
		_active_rect.visible = false


func on_attack_exit() -> void:
	_pending_strike = false
	_phase_state = 0
	_cancel_current_attack()
	if _telegraph_rect:
		_telegraph_rect.visible = false
	if _active_rect:
		_active_rect.visible = false


func on_state_update(delta: float) -> void:
	if _phase_state == 1 and _pending_strike:
		_telegraph_timer += delta
		if _telegraph_timer >= _stats_data.projectile_telegraph:
			_pending_strike = false
			_strike()
			_phase_state = 2
			_active_timer = 0.0
			if _telegraph_rect:
				_telegraph_rect.visible = false
			if _active_rect:
				_active_rect.visible = true
	elif _phase_state == 2:
		_active_timer += delta
		var active_dur: float = (
			_stats_data.hitbox_active_duration
			if _stats_data.hitbox_active_duration > 0.0
			else _DEFAULT_ACTIVE_DURATION
		)
		if _active_timer >= active_dur:
			_phase_state = 0
			if _active_rect:
				_active_rect.visible = false


func _strike() -> void:
	var spec := AttackSpec.new()
	spec.attacker = _enemy_root
	spec.source_group = "enemy_attack"
	spec.shape_type = "rect"
	spec.hitbox_size = _stats_data.hitbox_size
	spec.hitbox_offset = Vector2(
		absf(_stats_data.hitbox_offset.x) * _enemy_root.movement_comp.facing,
		_stats_data.hitbox_offset.y,
	)
	spec.active_duration = (
		_stats_data.hitbox_active_duration
		if _stats_data.hitbox_active_duration > 0.0
		else _DEFAULT_ACTIVE_DURATION
	)
	spec.damage = _enemy_root.stats_comp.get_attack()
	spec.is_finish = false
	spec.attribute = "shadow"
	spec.tags = PackedStringArray(["enemy_melee", "ground_tether"])

	_current_attack_area = CombatSystem.request_attack(spec)


func _cancel_current_attack() -> void:
	if _current_attack_area != null and is_instance_valid(_current_attack_area):
		CombatSystem.cancel_attack(_current_attack_area)
	_current_attack_area = null


func _create_fallback_visuals() -> void:
	if _enemy_root == null or _stats_data == null:
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
	# facing 반영: hitbox_offset.x 부호를 마지막 facing으로 결정
	var facing: float = _enemy_root.movement_comp.facing if _enemy_root.movement_comp else 1.0
	if facing == 0.0:
		facing = 1.0
	var size: Vector2 = _stats_data.hitbox_size
	var offset_x: float = absf(_stats_data.hitbox_offset.x) * facing
	var offset_y: float = _stats_data.hitbox_offset.y
	var top_left: Vector2 = Vector2(offset_x, offset_y) - size * 0.5
	for r in [_telegraph_rect, _active_rect]:
		r.size = size
		r.position = top_left
		r.visible = false
		r.z_index = 5

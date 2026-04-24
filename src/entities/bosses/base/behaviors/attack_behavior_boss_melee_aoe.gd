extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 P1 광역 근접 공격.
## BossPhasePattern에서 hitbox_size/offset/duration + telegraph_durations[idx]을 받는다.
## 흐름: ATTACK 진입 → telegraph(예고선 표시) → active(히트박스 ON) → 종료.
## Phase 4-0 #1 Step 5a: 자체 Hitbox 의존 제거 → CombatSystem.request_attack(AttackSpec) 위임.
## telegraph는 AttackSpec.telegraph_duration이 흡수. 시각(ColorRect)은 자체 _phase_timer로 동기화.

const FALLBACK_TELEGRAPH_COLOR := Color(0.95, 0.45, 0.2, 0.4)
const FALLBACK_ACTIVE_COLOR := Color(1.0, 0.65, 0.18, 0.85)

var _pattern: BossPhasePattern = null
var _telegraph_rect: ColorRect = null
var _active_rect: ColorRect = null

# 시각 단계 — CombatSystem이 판정 라이프사이클을 관리하므로 시각 동기화 전용.
# 0=idle, 1=telegraph, 2=active
var _phase_state: int = 0
var _phase_timer: float = 0.0
var _telegraph_duration: float = 0.5
var _active_duration: float = 0.4

## ATTACK 중도 이탈 시 잔존 히트 방지용 안전장치 (보스 사망/경직/페이즈 전환).
var _current_attack_area: Area2D = null


## PhaseController가 호출. 베이스 setup() 이후 패턴 적용.
## Step 5c: hitbox 인자 시그니처에서 제거 — base_boss가 더 이상 hitbox 멤버를 보유하지 않음.
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
	spec.attribute = "none"
	spec.tags = PackedStringArray(["boss", "p1_melee_aoe"])

	_current_attack_area = CombatSystem.request_attack(spec)


func on_attack_exit() -> void:
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

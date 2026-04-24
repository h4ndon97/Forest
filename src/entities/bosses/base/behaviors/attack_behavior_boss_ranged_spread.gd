extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 보스 원거리 스프레드 공격.
## 텔레그래프 동안 부채꼴 예고선(N개) 표시 → 발사 → 동시에 N발 발사.
## 패턴에서 projectile_scene_path/speed/spread_count/spread_angle/telegraph_durations[i] 참조.
## projectile_lifetime은 base_stats에서 가져온다.
## Phase 4-0 #1 Step 5b: 투사체 발사를 CombatSystem.request_projectile(ProjectileSpec)로 위임.

const DEFAULT_PROJECTILE_PATH := "res://src/entities/enemies/projectile/EnemyProjectile.tscn"
const TELEGRAPH_LINE_LENGTH := 96.0
const TELEGRAPH_LINE_WIDTH := 2.0
const FALLBACK_TELEGRAPH_COLOR := Color(0.95, 0.65, 0.2, 0.55)

var _pattern: BossPhasePattern = null
var _projectile_scene: PackedScene = null

# 0=idle, 1=telegraph, 2=fired
var _phase_state: int = 0
var _phase_timer: float = 0.0
var _telegraph_duration: float = 0.6
var _aim_direction: Vector2 = Vector2.RIGHT
var _telegraph_lines: Array = []


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
	_load_projectile_scene()


# _on_setup 제거 — Step 3에서 BaseEnemy의 자체 Hitbox 노드가 제거되어 강제 OFF 코드 불필요.


func on_attack_enter() -> void:
	_phase_state = 1
	_phase_timer = 0.0
	_aim_direction = _resolve_aim_direction()
	_create_telegraph_lines()


func on_attack_exit() -> void:
	_phase_state = 0
	_clear_telegraph_lines()


func on_state_update(delta: float) -> void:
	if _phase_state == 0:
		return
	_phase_timer += delta
	if _phase_state == 1 and _phase_timer >= _telegraph_duration:
		_phase_state = 2
		_clear_telegraph_lines()
		_fire_spread()
		# 발사 후 즉시 종료 — state_machine이 attack_cooldown 후 다음 ATTACK 진입.
		on_attack_exit()


# --- 내부 ---


func _load_projectile_scene() -> void:
	var path: String = _pattern.projectile_scene_path
	if path.is_empty():
		path = DEFAULT_PROJECTILE_PATH
	if not ResourceLoader.exists(path):
		push_warning("BossRangedSpread: projectile scene not found — " + path)
		return
	_projectile_scene = load(path) as PackedScene


func _resolve_aim_direction() -> Vector2:
	var target: Node2D = _enemy_root.state_machine.get_target()
	if is_instance_valid(target):
		var diff: Vector2 = target.global_position - _enemy_root.global_position
		if diff.length() > 0.1:
			return diff.normalized()
	var facing: float = _enemy_root.movement_comp.facing
	if facing == 0.0:
		facing = 1.0
	return Vector2(facing, 0.0)


func _spread_directions() -> Array:
	var count: int = _pattern.projectile_spread_count
	if count < 1:
		count = 1
	var angle_deg: float = _pattern.projectile_spread_angle
	var dirs: Array = []
	if count == 1:
		dirs.append(_aim_direction)
		return dirs
	var step: float = deg_to_rad(angle_deg)
	var start: float = -step * (count - 1) * 0.5
	for i in count:
		var rotated: Vector2 = _aim_direction.rotated(start + step * i)
		dirs.append(rotated)
	return dirs


func _create_telegraph_lines() -> void:
	_clear_telegraph_lines()
	var origin_offset := Vector2(0.0, -36.0)
	for dir in _spread_directions():
		var line := ColorRect.new()
		line.color = FALLBACK_TELEGRAPH_COLOR
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.size = Vector2(TELEGRAPH_LINE_LENGTH, TELEGRAPH_LINE_WIDTH)
		line.position = origin_offset - Vector2(0.0, TELEGRAPH_LINE_WIDTH * 0.5)
		line.pivot_offset = Vector2(0.0, TELEGRAPH_LINE_WIDTH * 0.5)
		line.rotation = dir.angle()
		line.z_index = 5
		_enemy_root.add_child(line)
		_telegraph_lines.append(line)


func _clear_telegraph_lines() -> void:
	for line in _telegraph_lines:
		if is_instance_valid(line):
			line.queue_free()
	_telegraph_lines.clear()


func _fire_spread() -> void:
	if _projectile_scene == null:
		return
	var origin: Vector2 = _enemy_root.global_position + Vector2(0.0, -36.0)
	var damage: float = _enemy_root.stats_comp.get_attack()
	var speed: float = _pattern.projectile_speed
	var lifetime: float = _stats_data.projectile_lifetime
	if lifetime <= 0.0:
		lifetime = 3.0
	for dir in _spread_directions():
		var spec := ProjectileSpec.new()
		spec.attacker = _enemy_root
		spec.source_group = "enemy_projectile"
		spec.scene = _projectile_scene
		spec.spawn_position = origin
		spec.direction = dir
		spec.speed = speed
		spec.lifetime = lifetime
		spec.damage = damage
		spec.tags = PackedStringArray(["boss", "ranged_spread"])
		var projectile: Node2D = CombatSystem.request_projectile(spec)
		if projectile != null:
			EventBus.enemy_projectile_fired.emit(origin, dir)

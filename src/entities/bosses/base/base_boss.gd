extends CharacterBody2D

## 보스 루트 스크립트.
## BaseEnemy와 별도. PhaseController가 페이즈별 공격 스크립트를 런타임 swap한다.

const BossStateMachine = preload("res://src/entities/bosses/base/boss_state_machine.gd")
const BossHPBarScript = preload("res://src/entities/bosses/base/boss_hp_bar.gd")
const EnemyDefenseScript = preload("res://src/entities/enemies/base/enemy_defense.gd")
const DamageNumberScript = preload("res://src/ui/common/damage_number.gd")

@export var boss_data: BossStatsData

var boss_id: int = -1

var _hp_bar_layer: CanvasLayer = null
var _hp_bar_node: Node2D = null
var _current_phase: int = 0

@onready var state_machine: Node = $StateMachine
@onready var phase_controller: Node = $PhaseController
@onready var stats_comp: Node = $Stats
@onready var movement_comp: Node = $Movement
@onready var animation_comp: Node = $AnimationController
@onready var detect_area: Area2D = $DetectArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var attack_behavior: Node = $AttackBehavior
@onready var defense: Node = $Defense
@onready var weak_point: Area2D = $WeakPoint


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")

	var base_stats: EnemyStatsData = boss_data.base_stats if boss_data else null
	if base_stats == null:
		push_error("BaseBoss: boss_data 또는 base_stats가 비어있음")
		set_physics_process(false)
		return

	stats_comp.setup(base_stats, EnemySystem.get_current_intensity())
	movement_comp.setup(base_stats, stats_comp)
	state_machine.setup(self)
	animation_comp.setup($AnimatedSprite2D)
	defense.set_script(EnemyDefenseScript)
	defense.setup(base_stats)
	phase_controller.setup(self, boss_data)

	boss_id = EnemySystem.register_enemy(self)

	_setup_hp_bar()

	stats_comp.died.connect(_on_died)
	stats_comp.health_changed.connect(_hp_bar_node.on_health_changed)
	stats_comp.health_changed.connect(phase_controller.on_health_changed)
	state_machine.state_changed.connect(_on_state_changed)
	detect_area.body_entered.connect(_on_detect_body_entered)
	detect_area.body_exited.connect(_on_detect_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	phase_controller.phase_entered.connect(_on_phase_entered)

	if weak_point and weak_point.has_method("setup"):
		weak_point.setup(self, boss_data.weak_point_offset, boss_data.weak_point_radius)
	EventBus.boss_weak_point_exposed.connect(_on_weak_point_exposed)

	hitbox.monitoring = false
	hitbox.monitorable = false

	# 초기 페이즈 0 패턴 주입 (INTRO 종료 후 ATTACK 시 사용)
	phase_controller.enter_phase(0)

	if not EnemySystem.are_enemies_active():
		deactivate()


func _physics_process(delta: float) -> void:
	var base_stats: EnemyStatsData = boss_data.base_stats if boss_data else null
	var is_airborne: bool = base_stats != null and base_stats.gravity_scale == 0.0

	if not is_airborne:
		if not is_on_floor():
			var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
			velocity.y += gravity * base_stats.gravity_scale * delta
		else:
			velocity.y = 0.0

	if not state_machine.is_active():
		if is_airborne:
			velocity = Vector2.ZERO
		else:
			velocity.x = 0.0
		move_and_slide()
		return

	state_machine.update(delta)
	if attack_behavior.has_method("on_state_update"):
		attack_behavior.on_state_update(delta)

	velocity = movement_comp.calculate_velocity(
		state_machine.current_state,
		state_machine.get_target(),
		velocity,
		global_position,
		is_on_floor(),
		delta
	)

	move_and_slide()
	animation_comp.update(state_machine.current_state, movement_comp.facing)


func activate() -> void:
	state_machine.activate()


func deactivate() -> void:
	state_machine.deactivate()


func update_intensity(intensity: float) -> void:
	stats_comp.update_intensity(intensity)


## 피격 처리. 약점 피격 시 multiplier 적용 후 reduction 통과.
## final_damage 반환 (UI/이벤트용).
func take_damage(amount: float, is_weak_point: bool = false) -> float:
	if state_machine.is_invincible():
		return 0.0
	var multiplier: float = 1.0
	if is_weak_point and boss_data:
		multiplier = boss_data.weak_point_damage_multiplier
	var final_damage: float = defense.apply_damage_reduction(amount * multiplier)
	stats_comp.take_damage(final_damage)
	if not stats_comp.is_dead():
		if defense.should_enter_hurt_state():
			state_machine.on_hurt()
	return final_damage


## Hurtbox / WeakPoint 양쪽이 호출. 데미지 적용 + 데미지 숫자 + 이벤트 emit 일원화.
func apply_player_hit(damage: float, is_finish: bool, is_weak_point: bool) -> void:
	var final_damage: float = take_damage(damage, is_weak_point)
	if final_damage <= 0.0:
		return
	_spawn_damage_number(final_damage, is_finish or is_weak_point)
	EventBus.damage_dealt.emit(boss_id, final_damage)


## PhaseController가 호출 — 공격 행동 스크립트를 런타임 swap한다.
func swap_attack_behavior(script_path: String, pattern: BossPhasePattern,
		attack_index: int = 0) -> void:
	if script_path.is_empty():
		return
	if not ResourceLoader.exists(script_path):
		push_warning("BaseBoss: attack script not found — " + script_path)
		return
	attack_behavior.set_script(load(script_path))
	if attack_behavior.has_method("setup_with_pattern"):
		attack_behavior.setup_with_pattern(self, boss_data.base_stats, hitbox, pattern, attack_index)


# --- 시그널 핸들러 ---

func _on_died() -> void:
	state_machine.on_death()
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	EnemySystem.on_enemy_died(boss_id, global_position)
	if boss_data:
		EventBus.enemy_drop_requested.emit(global_position, boss_data.boss_id)
		EventBus.boss_defeated.emit(boss_data.boss_id)
	queue_free()


func _on_state_changed(old_state: int, new_state: int) -> void:
	var entered_attack: bool = (new_state == BossStateMachine.State.ATTACK)
	var exited_attack: bool = (old_state == BossStateMachine.State.ATTACK)
	if entered_attack:
		if phase_controller and phase_controller.has_method("on_attack_starting"):
			phase_controller.on_attack_starting()
		if attack_behavior.has_method("on_attack_enter"):
			attack_behavior.on_attack_enter()
	elif exited_attack and attack_behavior.has_method("on_attack_exit"):
		attack_behavior.on_attack_exit()


func _on_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		state_machine.on_player_detected(body)


func _on_detect_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		state_machine.on_player_lost()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("player_attack"):
		return
	var damage: float = area.get_meta("damage", 0.0)
	var is_finish: bool = area.get_meta("is_finish", false)
	apply_player_hit(damage, is_finish, false)


func _on_weak_point_exposed(target_boss_id: String, exposed: bool) -> void:
	if boss_data == null or target_boss_id != boss_data.boss_id:
		return
	if weak_point and weak_point.has_method("set_exposed"):
		weak_point.set_exposed(exposed)


func _on_phase_entered(phase_index: int) -> void:
	var from_phase: int = _current_phase
	_current_phase = phase_index
	if boss_data:
		EventBus.boss_phase_changed.emit(boss_data.boss_id, from_phase, phase_index)


# --- 내부 ---

func _setup_hp_bar() -> void:
	_hp_bar_layer = CanvasLayer.new()
	_hp_bar_layer.layer = 5
	_hp_bar_node = Node2D.new()
	_hp_bar_node.set_script(BossHPBarScript)
	_hp_bar_layer.add_child(_hp_bar_node)
	add_child(_hp_bar_layer)
	if boss_data:
		_hp_bar_node.setup(boss_data.display_name)


func _spawn_damage_number(amount: float, is_finish: bool) -> void:
	var dmg_num: Node2D = Node2D.new()
	dmg_num.set_script(DamageNumberScript)
	dmg_num.global_position = global_position + Vector2(0, -64)
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_finish)

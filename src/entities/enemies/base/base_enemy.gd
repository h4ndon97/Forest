extends CharacterBody2D

## 적 루트 스크립트.
## 자식 컴포넌트를 조율하고 EnemySystem과 통신한다.

const RESIDUE_PATH := "res://src/entities/enemies/shadow_residue/ShadowResidue.tscn"
const DamageNumberScript = preload("res://src/ui/common/damage_number.gd")
const EnemyStateMachine = preload("res://src/entities/enemies/base/enemy_state_machine.gd")
const EnemyHPBarScript = preload("res://src/entities/enemies/base/enemy_hp_bar.gd")
const EnemyDefenseScript = preload("res://src/entities/enemies/base/enemy_defense.gd")
const AttackBehaviorMeleeScript = preload(
		"res://src/entities/enemies/base/behaviors/attack_behavior_melee.gd")
const AttackBehaviorNoneScript = preload(
		"res://src/entities/enemies/base/behaviors/attack_behavior_none.gd")

@export var stats_data: EnemyStatsData

var enemy_id: int = -1

var _hp_bar: Node2D
var _is_revived: bool = false
var _revive_hp_ratio: float = 1.0
var _revive_attack_ratio: float = 1.0

@onready var state_machine: Node = $StateMachine
@onready var stats_comp: Node = $Stats
@onready var movement_comp: Node = $Movement
@onready var animation_comp: Node = $AnimationController
@onready var detect_area: Area2D = $DetectArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var attack_behavior: Node = $AttackBehavior
@onready var death_behavior: Node = $DeathBehavior
@onready var defense: Node = $Defense


## 부활 적으로 설정한다. add_child() 전에 호출해야 한다.
func setup_as_revived(hp_ratio: float, attack_ratio: float) -> void:
	_is_revived = true
	_revive_hp_ratio = hp_ratio
	_revive_attack_ratio = attack_ratio


func _ready() -> void:
	add_to_group("enemies")

	_inject_behaviors()

	stats_comp.setup(stats_data, EnemySystem.get_current_intensity(),
			_revive_hp_ratio, _revive_attack_ratio)
	movement_comp.setup(stats_data, stats_comp)
	state_machine.setup(self)
	animation_comp.setup($AnimatedSprite2D)
	defense.setup(stats_data)
	attack_behavior.setup(self, stats_data, hitbox)
	if death_behavior.has_method("setup"):
		death_behavior.setup(self, stats_data)

	enemy_id = EnemySystem.register_enemy(self)

	_hp_bar = Node2D.new()
	_hp_bar.set_script(EnemyHPBarScript)
	add_child(_hp_bar)

	stats_comp.died.connect(_on_died)
	stats_comp.health_changed.connect(_hp_bar.on_health_changed)
	state_machine.state_changed.connect(_on_state_changed)
	detect_area.body_entered.connect(_on_detect_body_entered)
	detect_area.body_exited.connect(_on_detect_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	hitbox.monitoring = false
	hitbox.monitorable = false

	if not EnemySystem.are_enemies_active():
		deactivate()


func _physics_process(delta: float) -> void:
	# 중력은 항상 적용 (DORMANT에서도 바닥에 서 있어야 함)
	if not is_on_floor():
		var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
		velocity.y += gravity * stats_data.gravity_scale * delta
	else:
		velocity.y = 0.0

	if not state_machine.is_active():
		velocity.x = 0.0
		move_and_slide()
		return

	state_machine.update(delta)
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


func take_damage(amount: float) -> void:
	var final_damage: float = defense.apply_damage_reduction(amount)
	stats_comp.take_damage(final_damage)
	if not stats_comp.is_dead():
		if defense.should_enter_hurt_state():
			state_machine.on_hurt()


# --- 내부 ---

func _inject_behaviors() -> void:
	var attack_type: String = stats_data.attack_behavior if stats_data else "melee"
	match attack_type:
		"ranged":
			attack_behavior.set_script(load(
					"res://src/entities/enemies/base/behaviors/attack_behavior_ranged.gd"))
		"none":
			attack_behavior.set_script(AttackBehaviorNoneScript)
		_:
			attack_behavior.set_script(AttackBehaviorMeleeScript)

	var death_type: String = stats_data.death_behavior if stats_data else "none"
	# 부활 또는 분열체는 재분열 금지
	if _is_revived or (stats_data and stats_data.is_spore):
		death_type = "none"
	match death_type:
		"split":
			death_behavior.set_script(load(
					"res://src/entities/enemies/base/behaviors/death_behavior_split.gd"))
		_:
			pass

	defense.set_script(EnemyDefenseScript)


func _on_died() -> void:
	state_machine.on_death()
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	var killed_during_day: bool = EnemySystem.on_enemy_died(enemy_id, global_position)
	EventBus.enemy_drop_requested.emit(global_position, stats_data.enemy_name)
	_spawn_residue(killed_during_day)
	if death_behavior.has_method("on_death"):
		death_behavior.on_death()
	queue_free()


func _spawn_residue(killed_during_day: bool) -> void:
	if _is_revived:
		if not EnemySystem.get_config().revived_leaves_residue:
			return
	if not stats_data.leaves_residue:
		return
	if not ResourceLoader.exists(RESIDUE_PATH):
		return
	var scene := load(RESIDUE_PATH) as PackedScene
	var residue := scene.instantiate()
	residue.global_position = global_position
	if residue.has_method("setup"):
		residue.setup(stats_data, killed_during_day)
	get_parent().add_child(residue)
	EventBus.residue_left.emit(global_position, killed_during_day)


func _on_state_changed(old_state: int, new_state: int) -> void:
	var entered_attack: bool = (new_state == EnemyStateMachine.State.ATTACK)
	var exited_attack: bool = (old_state == EnemyStateMachine.State.ATTACK)
	if entered_attack:
		attack_behavior.on_attack_enter()
	elif exited_attack:
		attack_behavior.on_attack_exit()


func _on_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		state_machine.on_player_detected(body)


func _on_detect_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		state_machine.on_player_lost()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		var damage: float = area.get_meta("damage", 0.0)
		var is_finish: bool = area.get_meta("is_finish", false)
		take_damage(damage)
		_spawn_damage_number(damage, is_finish)
		EventBus.damage_dealt.emit(enemy_id, damage)


func _spawn_damage_number(amount: float, is_finish: bool) -> void:
	var dmg_num := Node2D.new()
	dmg_num.set_script(DamageNumberScript)
	dmg_num.global_position = global_position + Vector2(0, -28)
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_finish)

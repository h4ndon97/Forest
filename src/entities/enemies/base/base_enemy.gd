extends CharacterBody2D

## 적 루트 스크립트.
## 자식 컴포넌트를 조율하고 EnemySystem과 통신한다.

const RESIDUE_PATH := "res://src/entities/enemies/shadow_residue/ShadowResidue.tscn"
const DamageNumberScript = preload("res://src/ui/common/damage_number.gd")
const EnemyStateMachine = preload("res://src/entities/enemies/base/enemy_state_machine.gd")

@export var stats_data: EnemyStatsData

@onready var state_machine: Node = $StateMachine
@onready var stats_comp: Node = $Stats
@onready var movement_comp: Node = $Movement
@onready var animation_comp: Node = $AnimationController
@onready var detect_area: Area2D = $DetectArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox

var enemy_id: int = -1


func _ready() -> void:
	add_to_group("enemies")

	stats_comp.setup(stats_data, EnemySystem.get_current_intensity())
	movement_comp.setup(stats_data, stats_comp)
	state_machine.setup(self)
	animation_comp.setup($AnimatedSprite2D)

	enemy_id = EnemySystem.register_enemy(self)

	stats_comp.died.connect(_on_died)
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
	stats_comp.take_damage(amount)
	if not stats_comp.is_dead():
		state_machine.on_hurt()


# --- 내부 ---

func _on_died() -> void:
	state_machine.on_death()
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	EnemySystem.on_enemy_died(enemy_id, global_position)
	_spawn_residue()
	queue_free()


func _spawn_residue() -> void:
	if not stats_data.leaves_residue:
		return
	if not ResourceLoader.exists(RESIDUE_PATH):
		return
	var scene := load(RESIDUE_PATH) as PackedScene
	var residue := scene.instantiate()
	residue.global_position = global_position
	if residue.has_method("setup"):
		residue.setup(stats_data)
	get_parent().add_child(residue)


func _on_state_changed(_old_state: int, new_state: int) -> void:
	# ATTACK 상태 진입 시 히트박스 활성화 (시그널 중 직접 변경 불가 → deferred)
	var is_attack := (new_state == EnemyStateMachine.State.ATTACK)
	hitbox.set_deferred("monitoring", is_attack)
	hitbox.set_deferred("monitorable", is_attack)


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

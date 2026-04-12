extends CharacterBody2D

## 플레이어 루트 스크립트.
## 자식 컴포넌트를 조율하고 _physics_process 흐름을 관리한다.

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")

@export var stats: PlayerStatsData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: Node = $StateMachine
@onready var input_handler: Node = $InputHandler
@onready var movement: Node = $MovementComponent
@onready var animation_controller: Node = $AnimationController
@onready var combo: Node = $Combo
@onready var health: Node = $Health
@onready var lantern: Node2D = $Lantern
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var dash_duration_timer: Timer = $DashDurationTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer

var _is_dead: bool = false
var _death_tween: Tween


func _ready() -> void:
	add_to_group("player")

	var combat_config: CombatConfigData = CombatSystem.get_config()

	movement.setup(stats, combat_config.attack_movement_factor)
	animation_controller.setup(animated_sprite)
	state_machine.setup(coyote_timer, dash_duration_timer, dash_cooldown_timer, stats.max_air_jumps)
	combo.setup(self, combat_config)
	health.setup(self, combat_config)

	# 타이머 설정
	coyote_timer.wait_time = stats.coyote_time
	coyote_timer.one_shot = true
	dash_duration_timer.wait_time = stats.dash_duration
	dash_duration_timer.one_shot = true
	dash_cooldown_timer.wait_time = stats.dash_cooldown
	dash_cooldown_timer.one_shot = true

	# 시그널 연결
	state_machine.state_changed.connect(_on_state_changed)
	EventBus.player_died.connect(_on_died)
	EventBus.player_respawned.connect(_on_respawned)


func _physics_process(delta: float) -> void:
	if _is_dead:
		# 사망 중에는 중력만 적용
		if not is_on_floor():
			var gravity := ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) as float
			velocity.y += gravity * stats.fall_gravity_scale * delta
		else:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)
		move_and_slide()
		return

	# 1. 입력 읽기
	input_handler.update()

	# 등불 토글 (넉백/사망과 무관하게 처리)
	if input_handler.lantern_pressed:
		lantern.toggle()

	# 넉백 중에는 입력/상태/이동 계산 건너뛰고 마찰+중력만 적용
	if health.is_knocked_back():
		var gravity := ProjectSettings.get_setting("physics/2d/default_gravity", 980.0) as float
		velocity.y += gravity * stats.fall_gravity_scale * delta
		if is_on_floor() and velocity.y > 0.0:
			velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)
		move_and_slide()
		animation_controller.update(state_machine.current_state, movement.facing_direction)
		return

	# 2. 콤보 업데이트
	combo.update(input_handler, EnemySystem.are_enemies_active())

	# 3. 상태 전이 판정
	state_machine.update(input_handler, is_on_floor(), velocity)

	# 4. velocity 계산
	velocity = movement.calculate_velocity(
		state_machine.current_state,
		input_handler,
		velocity,
		is_on_floor(),
		delta,
		combo.is_attacking()
	)

	# 5. 물리 이동
	move_and_slide()

	# 6. 애니메이션 갱신
	animation_controller.update(state_machine.current_state, movement.facing_direction)

	# 7. 등불 위치/방향 갱신
	lantern.update_facing(movement.facing_direction > 0)
	lantern.update_position()


func take_damage(amount: float) -> void:
	health.take_damage(amount)


func is_attacking() -> bool:
	return combo.is_attacking()


func _on_state_changed(old_state: int, new_state: int) -> void:
	# 점프 진입 시 velocity.y 설정
	if new_state == StateMachine.State.JUMP:
		velocity.y = stats.jump_velocity


func _on_died() -> void:
	_is_dead = true

	# 스프라이트 페이드아웃
	if _death_tween:
		_death_tween.kill()
	_death_tween = create_tween()
	_death_tween.tween_property(animated_sprite, "modulate", Color(0.3, 0.1, 0.1, 0.4), 0.5)


func _on_respawned(pos: Vector2) -> void:
	_is_dead = false
	global_position = pos
	velocity = Vector2.ZERO

	# 스프라이트 복원
	if _death_tween:
		_death_tween.kill()
	animated_sprite.modulate = Color.WHITE

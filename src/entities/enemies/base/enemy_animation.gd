extends Node

## 적 애니메이션 관리 컴포넌트.
## 아트 리소스가 없으면 fallback(ColorRect)으로 동작한다.

const EnemyStateMachine = preload("res://src/entities/enemies/base/enemy_state_machine.gd")

var _sprite: AnimatedSprite2D
var _fallback: ColorRect
var _using_fallback: bool = false

const FALLBACK_SIZE := Vector2(20, 28)
const FALLBACK_COLOR := Color(0.6, 0.1, 0.1, 0.8)
const HURT_COLOR := Color(1.0, 0.3, 0.3, 0.9)
const DORMANT_COLOR := Color(0.3, 0.05, 0.05, 0.4)


func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite
	if not _sprite or not _sprite.sprite_frames:
		_create_fallback()


func update(state: int, facing_dir: float) -> void:
	if _using_fallback:
		_update_fallback(state, facing_dir)
	elif _sprite:
		_update_sprite(state, facing_dir)


func _update_sprite(state: int, facing_dir: float) -> void:
	_sprite.flip_h = facing_dir > 0.0

	var anim := _state_to_anim(state)
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)


func _update_fallback(state: int, facing_dir: float) -> void:
	match state:
		EnemyStateMachine.State.DORMANT:
			_fallback.color = DORMANT_COLOR
		EnemyStateMachine.State.HURT:
			_fallback.color = HURT_COLOR
		_:
			_fallback.color = FALLBACK_COLOR

	# 간단한 facing 표현: 위치 오프셋
	_fallback.position.x = -FALLBACK_SIZE.x * 0.5 + facing_dir * 2.0


func _state_to_anim(state: int) -> String:
	match state:
		EnemyStateMachine.State.IDLE, EnemyStateMachine.State.DORMANT:
			return "idle"
		EnemyStateMachine.State.PATROL:
			return "walk"
		EnemyStateMachine.State.CHASE:
			return "run"
		EnemyStateMachine.State.ATTACK:
			return "attack"
		EnemyStateMachine.State.HURT:
			return "hurt"
		EnemyStateMachine.State.DEAD:
			return "dead"
	return "idle"


func _create_fallback() -> void:
	_using_fallback = true
	_fallback = ColorRect.new()
	_fallback.color = FALLBACK_COLOR
	_fallback.size = FALLBACK_SIZE
	_fallback.position = Vector2(-FALLBACK_SIZE.x * 0.5, -FALLBACK_SIZE.y)
	_fallback.z_index = 0
	get_parent().add_child.call_deferred(_fallback)

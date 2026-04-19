extends Node

## 적 애니메이션 관리 컴포넌트.
## 아트 리소스가 없으면 fallback(ColorRect)으로 동작한다.

const EnemyStateMachine = preload("res://src/entities/enemies/base/enemy_state_machine.gd")

const SPRITE_BASE_OFFSET := Vector2(0, -16)
const FALLBACK_SIZE := Vector2(20, 28)
const FALLBACK_COLOR := Color(0.6, 0.1, 0.1, 0.8)
const HURT_COLOR := Color(1.0, 0.3, 0.3, 0.9)
const DORMANT_COLOR := Color(0.3, 0.05, 0.05, 0.4)

const _STATE_TO_ANIM := {
	EnemyStateMachine.State.IDLE: "idle",
	EnemyStateMachine.State.DORMANT: "idle",
	EnemyStateMachine.State.PATROL: "walk",
	EnemyStateMachine.State.CHASE: "run",
	EnemyStateMachine.State.ATTACK: "attack",
	EnemyStateMachine.State.HURT: "hurt",
	EnemyStateMachine.State.DEAD: "dead",
}

var _sprite: AnimatedSprite2D
var _fallback: ColorRect
var _using_fallback: bool = false
var _shake_offset: Vector2 = Vector2.ZERO


func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite
	if not _sprite or not _sprite.sprite_frames:
		_create_fallback()


func update(state: int, facing_dir: float) -> void:
	if _using_fallback:
		_update_fallback(state, facing_dir)
	elif _sprite:
		_update_sprite(state, facing_dir)


func set_shake_offset(offset: Vector2) -> void:
	_shake_offset = offset


func _update_sprite(state: int, facing_dir: float) -> void:
	_sprite.flip_h = facing_dir > 0.0
	_sprite.position = SPRITE_BASE_OFFSET + _shake_offset

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

	# 간단한 facing 표현: 위치 오프셋 + 흔들기 오프셋
	_fallback.position = Vector2(
		-FALLBACK_SIZE.x * 0.5 + facing_dir * 2.0 + _shake_offset.x,
		-FALLBACK_SIZE.y + _shake_offset.y
	)


func _state_to_anim(state: int) -> String:
	return _STATE_TO_ANIM.get(state, "idle")


func _create_fallback() -> void:
	_using_fallback = true
	_fallback = ColorRect.new()
	_fallback.color = DORMANT_COLOR
	_fallback.size = FALLBACK_SIZE
	_fallback.position = Vector2(-FALLBACK_SIZE.x * 0.5, -FALLBACK_SIZE.y)
	_fallback.z_index = 0
	get_parent().add_child.call_deferred(_fallback)

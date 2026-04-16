extends Node

## 매 프레임 InputMap을 읽어 행동 의도(intent)로 변환한다.
## 물리 연산이나 상태 판정은 하지 않는다.

var move_direction: float = 0.0
var jump_pressed: bool = false
var jump_held: bool = false
var jump_released: bool = false
var dash_pressed: bool = false
var attack_pressed: bool = false
var lantern_pressed: bool = false
var skill_1_pressed: bool = false
var skill_2_pressed: bool = false
var skill_3_pressed: bool = false
var skill_4_pressed: bool = false


func update() -> void:
	move_direction = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
	jump_held = Input.is_action_pressed("jump")
	jump_released = Input.is_action_just_released("jump")
	dash_pressed = Input.is_action_just_pressed("dash")
	attack_pressed = Input.is_action_just_pressed("attack")
	lantern_pressed = Input.is_action_just_pressed("lantern")
	skill_1_pressed = Input.is_action_just_pressed("skill_1")
	skill_2_pressed = Input.is_action_just_pressed("skill_2")
	skill_3_pressed = Input.is_action_just_pressed("skill_3")
	skill_4_pressed = Input.is_action_just_pressed("skill_4")

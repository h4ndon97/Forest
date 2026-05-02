class_name EchoTarget
extends Area2D

## REC-MECH-001 — Echo Nail 잔상 대상 컴포넌트.
## 적/NPC/오브젝트/잔재의 자식 또는 형제로 부착. EchoSystem에 자기 등록.
## 시간 정지 중 + 플레이어 근접 시 prompt 표시.
## 발동은 EchoSystem.try_reveal(self) 외부 호출 (Step 3에서 입력 hook 추가).

const TimeStateMachineScript = preload("res://src/systems/time/time_state_machine.gd")

const PROMPT_FONT_SIZE: int = 6
const PROMPT_OFFSET_Y: float = -22.0
const PROMPT_BASE_ALPHA: float = 0.85
const PROMPT_LABEL_SIZE: Vector2 = Vector2(40, 10)

@export var echo_data: EchoData
@export var trigger_radius: float = 28.0
@export var requires_time_stopped: bool = true
## true면 1회 노출 후 EchoSystem이 mark_consumed → queue_free.
@export var consumed_on_use: bool = true
@export var prompt_text: String = "[G] 잔상"

var _player_in_range: bool = false
var _is_time_stopped: bool = false
var _is_consumed: bool = false
var _prompt_label: Label = null


func _ready() -> void:
	add_to_group("echo_targets")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.time_flow_stopped.connect(_on_time_flow_stopped)
	EventBus.time_flow_started.connect(_on_time_flow_started)
	_setup_collision()
	_setup_prompt()
	_sync_initial_time_state()
	if Engine.has_singleton("EchoSystem") or has_node("/root/EchoSystem"):
		EchoSystem.register_target(self)


func _exit_tree() -> void:
	if has_node("/root/EchoSystem"):
		EchoSystem.unregister_target(self)


## EchoSystem이 발동 직후 호출.
## consumed_on_use=true면 즉시 폐기, false면 prompt만 갱신 (반복 가능 잔상).
func mark_consumed() -> void:
	_is_consumed = true
	_refresh_prompt()
	if consumed_on_use:
		queue_free()


## EchoSystem이 외부 호출용 가드 — 본 target이 현재 발동 가능한지.
func can_reveal() -> bool:
	if _is_consumed or echo_data == null:
		return false
	if not _player_in_range:
		return false
	if requires_time_stopped and not _is_time_stopped:
		return false
	return true


func _setup_collision() -> void:
	if has_node("CollisionShape2D"):
		return
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = trigger_radius
	shape_node.shape = shape
	add_child(shape_node)


func _setup_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.name = "EchoPrompt"
	_prompt_label.text = prompt_text
	_prompt_label.add_theme_font_size_override("font_size", PROMPT_FONT_SIZE)
	_prompt_label.add_theme_color_override(
		"font_color", Color(0.85, 0.78, 0.55, PROMPT_BASE_ALPHA)
	)
	_prompt_label.position = Vector2(-PROMPT_LABEL_SIZE.x / 2, PROMPT_OFFSET_Y)
	_prompt_label.size = PROMPT_LABEL_SIZE
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	add_child(_prompt_label)


func _sync_initial_time_state() -> void:
	# Autoload 직접 폴링 1회 — feedback_direct_ref_policy 허용 범위 (Config/상태 1회 읽기).
	# 시그널만으로는 EchoTarget이 정지 중간에 spawn될 때 초기값을 모름.
	if has_node("/root/TimeSystem"):
		_is_time_stopped = (
			TimeSystem.get_time_state() == TimeStateMachineScript.TimeState.STOPPED
		)


func _refresh_prompt() -> void:
	if _prompt_label == null:
		return
	var should_show: bool = (
		not _is_consumed
		and _player_in_range
		and (not requires_time_stopped or _is_time_stopped)
	)
	_prompt_label.visible = should_show


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_refresh_prompt()


func _on_time_flow_stopped(_hour: float) -> void:
	_is_time_stopped = true
	_refresh_prompt()


func _on_time_flow_started(_hour: float) -> void:
	_is_time_stopped = false
	_refresh_prompt()

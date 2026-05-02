extends Node

## 강화 이동 종료 후 후속 공격 처리 (Phase 4-0 #4 Step 5).
## - LIGHT_DASH: duration 종료 시점에 짧은 지연 후 자동 발동 (관통, light)
## - SHADOW_STEP / LIGHT_LEAP / SHADOW_PHASE: 종료 후 0.25s 윈도우 내 attack 입력 시 발동
##
## 일반 콤보 인프라(CombatSystem.request_attack)를 그대로 경유. 데미지는 base 콤보(20)와 동일.
## 속성/관통/다단만 능력별로 분기 — Phase 5 밸런싱에서 수치 재조정.
##
## 애니메이션:
##   - 우선 "follow_up_<tag>" 전용 애니메이션을 시도 (예: follow_up_light_dash)
##   - 없으면 "slash_4"(피니시) → "slash" 순으로 fallback
##   - 추후 전용 애니메이션 추가 시 player_animation.DYNAMIC_ANIM_PATHS에 등록만 하면 자동 작동
##     (player_animation._is_action_anim이 "follow_up_" prefix를 보호 대상으로 인식)
##
## 시각 단서:
##   - 발동 시점에 screen_flash + afterimage burst — 속성별 색
##   - dash 자체 잔상보다 한 박자 늦게 나와 "베기 임팩트" 강조

const StateMachine = preload("res://src/entities/player/player_state_machine.gd")
const FOLLOW_UP_WINDOW := 0.25
const LIGHT_DASH_AUTO_DELAY := 0.05
const SHADOW_STEP_MULTI_HIT_INTERVAL := 0.1

## 애니메이션 fallback 체인.
const FOLLOW_UP_ANIM_PREFIX := "follow_up_"
const FALLBACK_ANIM_FINISH := "slash_4"
const FALLBACK_ANIM_NORMAL := "slash"

## 시각 burst 파라미터 — dash 잔상 위에 한 번 더 강조해 follow-up 임팩트 가시화.
const BURST_AFTERIMAGE_COUNT := 8
const BURST_AFTERIMAGE_INTERVAL := 0.012
const BURST_AFTERIMAGE_FADE := 0.30
const BURST_FLASH_DURATION := 0.10
const BURST_COLOR_LIGHT := Color(2.5, 2.5, 2.5, 0.40)
const BURST_COLOR_SHADOW := Color(1.6, 0.4, 2.2, 0.40)

var _parent: CharacterBody2D
var _movement: Node
var _state_machine: Node
var _sprite: AnimatedSprite2D
var _config: CombatConfigData

var _window_active: bool = false
var _window_state: int = -1
var _window_remaining: float = 0.0


func setup(parent: CharacterBody2D) -> void:
	_parent = parent
	_movement = parent.get_node("MovementComponent")
	_state_machine = parent.get_node("StateMachine")
	_sprite = parent.get_node_or_null("AnimatedSprite2D")
	_config = CombatSystem.get_config()
	_state_machine.state_changed.connect(_on_state_changed)


## player.gd가 매 프레임 호출. 윈도우 활성 시 attack_pressed 감시 + 발동 시 input consume.
func update(input: Node, delta: float) -> void:
	if not _window_active:
		return
	_window_remaining -= delta
	if _window_remaining <= 0.0:
		_close_window()
		return
	if not input.attack_pressed:
		return
	_emit_for_state(_window_state)
	# attack 입력은 follow-up이 가져감 — combo가 이어 받지 않도록 consume.
	input.attack_pressed = false
	_close_window()


func _on_state_changed(old_state: int, new_state: int) -> void:
	var followup_states: Array = [
		StateMachine.State.LIGHT_DASH,
		StateMachine.State.SHADOW_STEP,
		StateMachine.State.LIGHT_LEAP,
		StateMachine.State.SHADOW_PHASE,
	]
	# 강화 이동 종료(체인 진입은 제외)만 트리거.
	if old_state not in followup_states or new_state in followup_states:
		return
	if old_state == StateMachine.State.LIGHT_DASH:
		_schedule_auto_light_dash()
		return
	# 입력 윈도우 모드 — 다른 윈도우가 열려 있었다면 덮어씀.
	_window_active = true
	_window_state = old_state
	_window_remaining = FOLLOW_UP_WINDOW


func _schedule_auto_light_dash() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	# 잔상 끝에 베기 — 살짝 지연으로 시각 단서 확보. ignore_time_scale로 힛스톱 무관.
	var t: SceneTreeTimer = tree.create_timer(LIGHT_DASH_AUTO_DELAY, true, false, true)
	t.timeout.connect(_on_auto_light_dash_timeout)


func _on_auto_light_dash_timeout() -> void:
	if not is_instance_valid(_parent):
		return
	_emit_for_state(StateMachine.State.LIGHT_DASH)


func _emit_for_state(state: int) -> void:
	if not EnemySystem.are_enemies_active():
		return
	if not is_instance_valid(_parent):
		return
	_play_animation(state)
	_play_visual_burst(state)
	_request_attack(state)


func _request_attack(state: int) -> void:
	var spec := AttackSpec.new()
	spec.attacker = _parent
	spec.source_group = "player_attack"
	spec.shape_type = "rect"
	spec.hitbox_size = _config.hitbox_size
	spec.hitbox_offset = Vector2(
		absf(_config.hitbox_offset.x) * _movement.facing_direction,
		_config.hitbox_offset.y,
	)
	spec.active_duration = _config.hit_duration
	# 일반 1타 데미지 — 관통(light)·다단(shadow_step)으로 누적 효과는 자연 발생.
	spec.damage = CombatSystem.get_combo_damage(1)
	spec.attribute = _attribute_for_state(state)
	spec.is_finish = false
	spec.piercing = state == StateMachine.State.LIGHT_DASH
	spec.multi_hit_count = 2 if state == StateMachine.State.SHADOW_STEP else 1
	if spec.multi_hit_count > 1:
		spec.multi_hit_interval = SHADOW_STEP_MULTI_HIT_INTERVAL
	spec.tags = PackedStringArray(["follow_up", _state_tag(state)])
	CombatSystem.request_attack(spec)


## AnimationController에 위임 — _loaded_anims 메타데이터 기반 fallback.
## (직접 sprite_frames.has_animation 체크는 embedded placeholder를 가짜 양성으로 재생.)
func _play_animation(state: int) -> void:
	if _parent == null:
		return
	var anim_ctrl: Node = _parent.get_node_or_null("AnimationController")
	if anim_ctrl == null or not anim_ctrl.has_method("play_follow_up"):
		return
	anim_ctrl.play_follow_up(_state_tag(state))


func _play_visual_burst(state: int) -> void:
	var attribute: String = _attribute_for_state(state)
	var color: Color = BURST_COLOR_LIGHT if attribute == "light" else BURST_COLOR_SHADOW
	EventBus.screen_flash_requested.emit(color, BURST_FLASH_DURATION)
	if _sprite != null:
		EffectsSystem.request_afterimage(
			_sprite, BURST_AFTERIMAGE_COUNT, BURST_AFTERIMAGE_INTERVAL, BURST_AFTERIMAGE_FADE
		)


func _attribute_for_state(state: int) -> String:
	match state:
		StateMachine.State.LIGHT_DASH, StateMachine.State.LIGHT_LEAP:
			return "light"
		StateMachine.State.SHADOW_STEP, StateMachine.State.SHADOW_PHASE:
			return "shadow"
	return "neutral"


func _state_tag(state: int) -> String:
	match state:
		StateMachine.State.LIGHT_DASH:
			return "light_dash"
		StateMachine.State.SHADOW_STEP:
			return "shadow_step"
		StateMachine.State.LIGHT_LEAP:
			return "light_leap"
		StateMachine.State.SHADOW_PHASE:
			return "shadow_phase"
	return "unknown"


func _close_window() -> void:
	_window_active = false
	_window_state = -1
	_window_remaining = 0.0

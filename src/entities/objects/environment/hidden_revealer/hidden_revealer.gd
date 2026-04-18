extends Node2D

## 숨김 노출 컴포넌트.
## 4가지 reveal_condition 중 하나의 조건 충족 시 target_node를 드러낸다.
## 감지는 외부 센서/detector에 위임 — 본 컴포넌트는 구독과 드러내기 동작만 수행.
## 드러낸 이후 StateFlags에 플래그를 기록하여 재진입 시 즉시 복원된다.

@export var data: HiddenRevealerData
## 드러낼 대상 노드 (queue_free 또는 visible=true).
@export var target_node_path: NodePath
## 감지 소스 노드 (LightSensor / ShadowResidue / ShadowProjectionZone 등).
@export var source_node_path: NodePath
## 플래그 네이밍용 스테이지 식별자. 비우면 "unknown".
@export var stage_id: String = ""

var _revealed: bool = false
var _target: Node = null
var _source: Node = null
var _expected_purify_position: Vector2 = Vector2.ZERO
var _has_expected_purify_position: bool = false
var _player_inside_cover: bool = false
var _sustain_timer: float = 0.0
var _flag_id: String = ""


func _ready() -> void:
	if data == null:
		push_warning("HiddenRevealer: data 미설정 (%s)" % name)
		set_process(false)
		return
	_target = get_node_or_null(target_node_path)
	_source = get_node_or_null(source_node_path)
	_flag_id = StateFlagNames.hidden_revealer_flag(stage_id, name)

	# 세이브 복원: 이미 드러난 경우 즉시 처리
	if _flag_id != "" and _get_state_flags() != null and _get_state_flags().has_flag(_flag_id):
		_revealed = true
		_apply_reveal_action()
		set_process(false)
		return

	# PURIFICATION: 소스 위치를 미리 캡처
	if data.reveal_condition == HiddenRevealerData.RevealCondition.PURIFICATION:
		if _source and is_instance_valid(_source) and _source is Node2D:
			_expected_purify_position = (_source as Node2D).global_position
			_has_expected_purify_position = true

	_connect_source()

	# SHADOW_COVER 외에는 _process 불필요
	if data.reveal_condition != HiddenRevealerData.RevealCondition.SHADOW_COVER:
		set_process(false)


func _process(delta: float) -> void:
	if _revealed or data == null:
		return
	if data.reveal_condition != HiddenRevealerData.RevealCondition.SHADOW_COVER:
		return
	if _player_inside_cover:
		_sustain_timer += delta
		if _sustain_timer >= data.require_sustained_seconds:
			_trigger_reveal()


## 현재 드러났는지 여부.
func is_revealed() -> bool:
	return _revealed


## 디버그/세이브 복원용 강제 드러내기. 플래그는 기록하지 않는다 (중복 방지).
func force_reveal() -> void:
	if _revealed:
		return
	_revealed = true
	_apply_reveal_action()
	set_process(false)


# --- 내부 ---


func _connect_source() -> void:
	match data.reveal_condition:
		HiddenRevealerData.RevealCondition.LIGHT_SENSOR, HiddenRevealerData.RevealCondition.REFLECTION:
			if _source and _source.has_signal("light_sensor_activated"):
				_source.light_sensor_activated.connect(_on_light_sensor_activated)
			else:
				push_warning("HiddenRevealer: LIGHT_SENSOR/REFLECTION 소스가 LightSensor가 아님 (%s)" % name)
		HiddenRevealerData.RevealCondition.PURIFICATION:
			EventBus.residue_purified.connect(_on_residue_purified)
		HiddenRevealerData.RevealCondition.SHADOW_COVER:
			if _source and _source is Area2D:
				(_source as Area2D).body_entered.connect(_on_cover_body_entered)
				(_source as Area2D).body_exited.connect(_on_cover_body_exited)
			else:
				push_warning("HiddenRevealer: SHADOW_COVER 소스가 Area2D가 아님 (%s)" % name)
		HiddenRevealerData.RevealCondition.FLAG:
			if data.trigger_flag_id.is_empty():
				push_warning("HiddenRevealer: FLAG 조건에 trigger_flag_id가 비어있음 (%s)" % name)
				return
			# 이미 켜져 있으면 즉시 reveal
			var flags: Node = _get_state_flags()
			if flags != null and flags.has_flag(data.trigger_flag_id):
				_trigger_reveal()
				return
			EventBus.state_flag_changed.connect(_on_state_flag_changed)


func _on_light_sensor_activated(_sensor_id: String) -> void:
	if not _revealed:
		_trigger_reveal()


func _on_residue_purified(pos: Vector2) -> void:
	if _revealed or not _has_expected_purify_position:
		return
	if _expected_purify_position.distance_to(pos) <= data.purification_match_distance:
		_trigger_reveal()


func _on_cover_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside_cover = true


func _on_cover_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside_cover = false
		_sustain_timer = 0.0


func _on_state_flag_changed(flag_id: String, value: bool) -> void:
	if _revealed or not value:
		return
	if flag_id == data.trigger_flag_id:
		_trigger_reveal()


func _trigger_reveal() -> void:
	if _revealed:
		return
	_revealed = true
	_apply_reveal_action()
	set_process(false)
	var flags: Node = _get_state_flags()
	if flags != null and _flag_id != "":
		flags.set_flag(_flag_id, true)
	EventBus.hidden_revealed.emit(stage_id, name)


func _apply_reveal_action() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	match data.reveal_action:
		HiddenRevealerData.RevealAction.QUEUE_FREE:
			_target.queue_free()
		HiddenRevealerData.RevealAction.SET_VISIBLE:
			if "visible" in _target:
				_target.visible = true
			# process_mode 복원: 숨김 포탈 등 DISABLED 상태로 묶인 대상 재활성화
			if _target is Node:
				(_target as Node).process_mode = Node.PROCESS_MODE_INHERIT


func _get_state_flags() -> Node:
	if has_node("/root/StateFlags"):
		return get_node("/root/StateFlags")
	return null

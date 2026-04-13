extends Node2D

## 정화 감지 컴포넌트.
## 잔류에 부착되어 등불 접촉 + 시간대 조건 충족 시 정화를 실행한다.
## 정화 조건: 플레이어 범위 내 + 등불 ON + 처치 시간대 ≠ 현재 시간대.
## 거리 기반 감지로 안정적으로 동작한다.

var _killed_during_day: bool = true
var _detection_radius: float = 24.0
var _player_in_range: bool = false
var _lantern_on: bool = false
var _current_is_day: bool = true
var _player: Node2D = null
var _purified: bool = false


## setup은 add_child 전에 호출된다. 데이터만 저장한다.
func setup(killed_during_day: bool, radius: float) -> void:
	_killed_during_day = killed_during_day
	_detection_radius = radius


func _ready() -> void:
	_current_is_day = TimeSystem.is_day()
	EventBus.day_night_changed.connect(_on_day_night_changed)
	EventBus.lantern_toggled.connect(_on_lantern_toggled)

	# 플레이어 참조 + 등불 초기 상태
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]
		if _player.has_node("Lantern"):
			_lantern_on = _player.get_node("Lantern").is_on()


func _physics_process(_delta: float) -> void:
	if _purified or not _player or not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	var was_in_range := _player_in_range
	_player_in_range = dist <= _detection_radius
	if _player_in_range and not was_in_range:
		_try_purify()


func _on_day_night_changed(is_day: bool) -> void:
	_current_is_day = is_day
	_try_purify()


func _on_lantern_toggled(is_on: bool, _lantern_position: Vector2) -> void:
	_lantern_on = is_on
	_try_purify()


## 정화 조건을 검사하고, 충족 시 부모(ShadowResidue)의 purify()를 호출한다.
func _try_purify() -> void:
	if _purified:
		return
	if not _player_in_range:
		return
	if not _lantern_on:
		return
	# 처치 시간대의 반대 시간대에서만 정화 가능
	if _killed_during_day == _current_is_day:
		return

	_purified = true
	var parent := get_parent()
	if parent and parent.has_method("purify"):
		parent.purify()

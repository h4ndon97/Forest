class_name DuskSpiderEntity
extends RefCounted

## 개별 땅거미 인스턴스.
## 맵 위를 논리적으로 이동하며, 도착 시 시스템에 통보한다.
## 씬 트리에 추가되지 않는 데이터 객체이다.

enum State { IDLE, TRACKING, ARRIVED, DEFEATED }

var id: int
var current_stage_id: String
var target_stage_id: String
var state: State = State.IDLE
## 현재 맵 간 이동 진행도 (0.0 ~ 1.0). 1.0 도달 시 다음 맵으로 이동.
var move_progress: float = 0.0
## 다음에 도착할 스테이지 ID (현재 이동 중인 구간의 목적지)
var next_stage_id: String = ""


func _init(spider_id: int, start_stage_id: String) -> void:
	id = spider_id
	current_stage_id = start_stage_id


## 타겟을 설정하고 추적을 시작한다.
func start_tracking(target_id: String, navigator: Node) -> void:
	target_stage_id = target_id
	state = State.TRACKING
	move_progress = 0.0
	next_stage_id = navigator.get_next_step(current_stage_id, target_id)


## 매 프레임 이동을 진행한다. 도착하면 true를 반환한다.
func advance(delta: float, seconds_per_map: float) -> bool:
	if state != State.TRACKING:
		return false
	if next_stage_id.is_empty():
		return false

	var speed: float = 1.0 / seconds_per_map
	move_progress += delta * speed

	if move_progress >= 1.0:
		move_progress = 0.0
		current_stage_id = next_stage_id
		if current_stage_id == target_stage_id:
			state = State.ARRIVED
			return true
		# 아직 도착하지 않았으면 다음 구간 설정은 시스템이 처리
	return false


## 타겟을 갱신하고 경로를 재계산한다.
func update_target(new_target_id: String, navigator: Node) -> void:
	if state != State.TRACKING:
		return
	target_stage_id = new_target_id
	next_stage_id = navigator.get_next_step(current_stage_id, new_target_id)
	move_progress = 0.0


## 현재 위치에서 타겟까지 남은 거리(홉 수)를 반환한다.
func get_remaining_distance(navigator: Node) -> int:
	if state != State.TRACKING:
		return -1
	return navigator.get_distance(current_stage_id, target_stage_id)


## 시간 정지로 인해 추적을 중단한다. 위치는 유지.
func stop_tracking() -> void:
	if state == State.TRACKING:
		state = State.IDLE
		move_progress = 0.0
		next_stage_id = ""
		target_stage_id = ""


## 처치됨.
func defeat() -> void:
	state = State.DEFEATED

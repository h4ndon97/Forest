extends Node

## 독립 스테이지 시간 전파 컴포넌트.
## flow를 시작한 스테이지를 원점(origin)으로 설정하고,
## 원점으로부터의 홉 수에 따라 감쇠된 비율로 시간을 전파한다.
## 각 스테이지는 독립적으로 시간이 흐르며,
## 현재 스테이지의 flow를 멈춰도 다른 스테이지는 계속 흐른다.
## _process(delta)로 모든 흐름 중 스테이지를 직접 진행한다.

var _registry: Node
var _stage_hours: Dictionary  # StageSystem과 참조 공유
var _config: PropagationConfigData
var _current_stage_id: String = ""
var _origin_stage_id: String = ""
var _stage_rates: Dictionary = {}  # BFS 감쇠 비율 (rebuild 시 계산)
var _flowing_stages: Dictionary = {}  # stage_id -> rate (독립 흐름 중)
var _ts_flowing: bool = false  # TimeSystem FLOWING 상태 추적
var _is_auto_resuming: bool = false  # 자동 재개 플래그 (rebuild 스킵)
var _paused: bool = false  # 전환 애니메이션 일시정지
var _is_current_origin: bool = false  # 현재 스테이지 원점 여부 (시그널 중복 발행 방지)


func setup(registry: Node, stage_hours: Dictionary, config: PropagationConfigData) -> void:
	_registry = registry
	_stage_hours = stage_hours
	_config = config
	EventBus.time_flow_started.connect(_on_flow_started)
	EventBus.time_flow_stopped.connect(_on_flow_stopped)
	EventBus.time_flow_paused.connect(_on_flow_paused)
	EventBus.time_flow_resumed.connect(_on_flow_resumed)


func _process(delta: float) -> void:
	if _paused or _flowing_stages.is_empty():
		return

	var hours_per_second: float = _config.flow_speed / 60.0

	for stage_id in _flowing_stages.keys():
		# 현재 스테이지는 TimeSystem이 직접 처리
		if stage_id == _current_stage_id:
			continue

		var rate: float = _flowing_stages[stage_id]
		var hours_elapsed: float = hours_per_second * delta * rate

		# 아직 초기화되지 않은 스테이지는 초기 시각 설정
		if not _stage_hours.has(stage_id):
			var data: StageData = _registry.get_stage(stage_id)
			if data:
				_stage_hours[stage_id] = data.initial_hour
			else:
				continue

		_stage_hours[stage_id] += hours_elapsed
		_stage_hours[stage_id] = _wrap_hour(_stage_hours[stage_id])


## StageSystem이 stage_entered 처리 후 직접 호출한다.
## 자동 재개 여부를 반환한다 (true = flow 자동 재개됨).
func notify_stage_entered(stage_id: String) -> bool:
	_current_stage_id = stage_id

	if _flowing_stages.has(stage_id):
		if not _ts_flowing:
			# TimeSystem STOPPED 상태에서 흐르는 스테이지 진입 → 자동 재개
			var rate: float = _flowing_stages[stage_id]
			var hour: float = _stage_hours.get(stage_id, 12.0)
			_is_auto_resuming = true
			EventBus.time_flow_resume_requested.emit(hour, rate)
			return true
		# 이미 FLOWING 중 — rate만 갱신
		_emit_player_rate()
	else:
		# 현재 스테이지가 전파 대상 아님 → 원점 플래그 해제
		_update_origin_flag()

	return false


## 스테이지가 독립적으로 흐르고 있는지 반환한다.
func is_stage_flowing(stage_id: String) -> bool:
	return _flowing_stages.has(stage_id)


func _on_flow_started(_current_hour: float) -> void:
	_ts_flowing = true

	if _is_auto_resuming:
		_is_auto_resuming = false
		return

	# 새 flow 시작: 원점 갱신 + rate map 재구축
	_origin_stage_id = _current_stage_id
	_rebuild_rate_map()
	_flowing_stages.clear()
	for stage_id in _stage_rates:
		_flowing_stages[stage_id] = _stage_rates[stage_id]
	_emit_player_rate()


func _on_flow_stopped(_current_hour: float) -> void:
	_ts_flowing = false
	# 현재 스테이지만 흐름 중단 — 다른 스테이지는 계속 흐른다
	_flowing_stages.erase(_current_stage_id)
	_update_origin_flag()


func _on_flow_paused() -> void:
	_paused = true


func _on_flow_resumed() -> void:
	_paused = false


## 원점에서 BFS로 모든 도달 가능 스테이지의 감쇠 비율을 계산한다.
func _rebuild_rate_map() -> void:
	_stage_rates.clear()
	if _origin_stage_id.is_empty():
		return

	var queue: Array = [[_origin_stage_id, 1.0]]
	_stage_rates[_origin_stage_id] = 1.0

	var depth := 0
	while not queue.is_empty() and depth <= _config.max_depth:
		var next_queue: Array = []
		for entry in queue:
			var stage_id: String = entry[0]
			var rate: float = entry[1]
			var child_rate: float = rate * _config.propagation_rate
			if child_rate < _config.minimum_threshold:
				continue
			var data: StageData = _registry.get_stage(stage_id)
			if not data:
				continue
			for adj_id in data.adjacent_stages:
				if _stage_rates.has(adj_id):
					continue
				_stage_rates[adj_id] = child_rate
				next_queue.append([adj_id, child_rate])
		queue = next_queue
		depth += 1


## 플레이어 현재 스테이지의 flow rate를 TimeSystem에 전달한다.
func _emit_player_rate() -> void:
	var rate: float = _flowing_stages.get(_current_stage_id, 1.0)
	EventBus.flow_rate_changed.emit(rate)
	_update_origin_flag()


## 현재 스테이지의 원점 여부를 재계산하고, 변경 시에만 시그널을 발행한다.
func _update_origin_flag() -> void:
	var new_origin: bool = (
		not _origin_stage_id.is_empty()
		and _current_stage_id == _origin_stage_id
		and _flowing_stages.has(_current_stage_id)
	)
	if new_origin != _is_current_origin:
		_is_current_origin = new_origin
		EventBus.propagation_origin_changed.emit(new_origin)


## 시각을 0.0~24.0 범위로 래핑한다.
func _wrap_hour(hour: float) -> float:
	hour = fmod(hour, 24.0)
	if hour < 0.0:
		hour += 24.0
	return hour

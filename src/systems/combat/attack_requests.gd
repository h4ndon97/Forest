class_name AttackRequests
extends RefCounted

## 활성 공격 요청의 생명주기 관리: idle → telegraph → active → expired.
## CombatSystem이 단일 인스턴스 보유하고 _process(delta)에서 tick한다.
## Step 1에서는 내부 로직 완성 — 호출자(request_attack)는 Step 2에서 연결.
##
## telegraph_duration == 0이면 즉시 active 상태로 시작하므로 보스/일반 공격 공통 경로.

## 페이즈 전환 시 발행 — 보스 예고선 ColorRect 가시성 등 외부 시각 컴포넌트 연동용.
## §7 미결: 시그널 vs 콜백 — 우선 시그널로 내보내고 Step 5에서 재검토.
signal telegraph_started(area: Area2D, spec: AttackSpec)
signal active_started(area: Area2D, spec: AttackSpec)
signal attack_expired(area: Area2D, spec: AttackSpec)

enum Phase { TELEGRAPH, ACTIVE }

var _requests: Array[_Request] = []


## 새 요청 등록. telegraph_duration > 0이면 예고 페이즈부터, 아니면 즉시 active.
func enqueue(area: Area2D, spec: AttackSpec) -> void:
	if area == null or spec == null:
		return
	var req := _Request.new()
	req.area = area
	req.spec = spec
	req.timer = 0.0
	if spec.telegraph_duration > 0.0:
		req.phase = Phase.TELEGRAPH
		telegraph_started.emit(area, spec)
	else:
		req.phase = Phase.ACTIVE
		_activate(req)
	_requests.append(req)


## CombatSystem._process(delta)에서 매 프레임 호출.
func process(delta: float) -> void:
	if _requests.is_empty():
		return
	# 뒤에서 앞으로 순회 — 만료 요청 안전 제거.
	for i in range(_requests.size() - 1, -1, -1):
		var req: _Request = _requests[i]
		if not is_instance_valid(req.area):
			_requests.remove_at(i)
			continue
		req.timer += delta
		match req.phase:
			Phase.TELEGRAPH:
				if req.timer >= req.spec.telegraph_duration:
					req.phase = Phase.ACTIVE
					req.timer = 0.0
					_activate(req)
			Phase.ACTIVE:
				if req.timer >= req.spec.active_duration:
					_expire(req)
					_requests.remove_at(i)


## 외부가 요청을 조기 종료하고 싶을 때 (예: 플레이어 사망, 보스 경직).
func cancel(area: Area2D) -> void:
	for i in range(_requests.size() - 1, -1, -1):
		if _requests[i].area == area:
			_expire(_requests[i])
			_requests.remove_at(i)
			return


## 활성 요청 개수 — 디버그/테스트용.
func active_count() -> int:
	return _requests.size()


func _activate(req: _Request) -> void:
	if not is_instance_valid(req.area):
		return
	req.area.set_deferred("monitoring", true)
	req.area.set_deferred("monitorable", true)
	active_started.emit(req.area, req.spec)


func _expire(req: _Request) -> void:
	if not is_instance_valid(req.area):
		return
	req.area.set_deferred("monitoring", false)
	req.area.set_deferred("monitorable", false)
	attack_expired.emit(req.area, req.spec)
	req.area.queue_free()


class _Request:
	var area: Area2D
	var spec: AttackSpec
	var phase: int = Phase.ACTIVE
	var timer: float = 0.0

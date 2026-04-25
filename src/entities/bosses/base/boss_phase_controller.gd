extends Node

## 보스 페이즈 FSM 컨트롤러.
## HP 임계 감시 + 페이즈별 공격 패턴 주입 + 패턴 내 다중 공격 순환.

signal phase_entered(phase_index: int)
signal phase_transition_started(from_phase: int, to_phase: int)

var _boss: Node = null
var _boss_data: BossStatsData = null
var _current_phase: int = -1
var _is_transitioning: bool = false
## 현재 페이즈에서 다음 ATTACK에 사용할 attack_scripts 인덱스
var _attack_index: int = 0
## 현재 페이즈의 다음 전환 임계 인덱스 (phase_hp_thresholds 기준)
var _next_threshold_index: int = 0


func setup(boss: Node, boss_data: BossStatsData) -> void:
	_boss = boss
	_boss_data = boss_data


## 지정 페이즈로 진입. 패턴 0번 스크립트를 보스 attack_behavior에 swap.
func enter_phase(phase_index: int) -> void:
	if _boss_data == null:
		return
	if phase_index < 0 or phase_index >= _boss_data.phase_patterns.size():
		push_warning("BossPhaseController: invalid phase_index " + str(phase_index))
		return
	var pattern: BossPhasePattern = _boss_data.phase_patterns[phase_index]
	if pattern == null or pattern.attack_scripts.is_empty():
		push_warning("BossPhaseController: phase " + str(phase_index) + " has no attack pattern")
		return
	_current_phase = phase_index
	_attack_index = 0
	_next_threshold_index = phase_index
	_is_transitioning = false
	_swap_to_current_attack(pattern)
	phase_entered.emit(phase_index)


## HP 변동 시 호출 — 다음 임계점 통과 확인 후 페이즈 전환 트리거.
func on_health_changed(current_hp: float, max_hp: float) -> void:
	if _is_transitioning or _boss_data == null or max_hp <= 0.0:
		return
	if _next_threshold_index >= _boss_data.phase_hp_thresholds.size():
		return
	var ratio: float = current_hp / max_hp
	var threshold: float = _boss_data.phase_hp_thresholds[_next_threshold_index]
	if ratio <= threshold:
		_trigger_phase_transition(_current_phase + 1)


## ATTACK 진입 직전 base_boss가 호출 — 다중 공격 스크립트 순환.
func on_attack_starting() -> void:
	if _current_phase < 0 or _boss_data == null:
		return
	var pattern: BossPhasePattern = _boss_data.phase_patterns[_current_phase]
	if pattern == null or pattern.attack_scripts.size() <= 1:
		return
	_attack_index = (_attack_index + 1) % pattern.attack_scripts.size()
	_swap_to_current_attack(pattern)


func get_current_phase() -> int:
	return _current_phase


# --- 내부 ---


func _swap_to_current_attack(pattern: BossPhasePattern) -> void:
	var idx: int = _attack_index
	if idx < 0 or idx >= pattern.attack_scripts.size():
		idx = 0
	var script_path: String = pattern.attack_scripts[idx]
	if _boss and _boss.has_method("swap_attack_behavior"):
		_boss.swap_attack_behavior(script_path, pattern, idx)


func _trigger_phase_transition(to_phase: int) -> void:
	if to_phase >= _boss_data.phase_patterns.size():
		return
	_is_transitioning = true
	_next_threshold_index += 1
	var from_phase: int = _current_phase
	phase_transition_started.emit(from_phase, to_phase)
	if _boss and _boss.state_machine and _boss.state_machine.has_method("enter_phase_transition"):
		if not _boss.state_machine.phase_transition_finished.is_connected(_on_transition_finished):
			_boss.state_machine.phase_transition_finished.connect(
				_on_transition_finished.bind(to_phase), CONNECT_ONE_SHOT
			)
		_boss.state_machine.enter_phase_transition()
	else:
		# 폴백: state_machine 미지원 시 즉시 전환
		enter_phase(to_phase)


func _on_transition_finished(to_phase: int) -> void:
	enter_phase(to_phase)

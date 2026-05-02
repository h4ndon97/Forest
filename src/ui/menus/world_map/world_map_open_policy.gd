extends Node

## 월드맵 열림 가능 여부 판정 — Stage 0.
## WorldMapUI 자식 노드. EventBus 시그널을 구독해 차단 상태를 유지한다.
## can_open() = 다음 모두 false 일 때 true:
##   - 다른 UI 메뉴 활성 (Pause/Inventory/Shop)
##   - 컷신/전환/대화 진행 중
##   - 보스 인트로 진행 중
##   - 최근 2초 내 전투 시그널 (damage_received/dealt 휴리스틱)

const COMBAT_WINDOW_MS: int = 2000

var _in_cutscene: bool = false
var _in_transition: bool = false
var _dialogue_count: int = 0
var _in_boss_intro: bool = false
var _last_combat_ms: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.cutscene_started.connect(_on_cutscene_started)
	EventBus.cutscene_finished.connect(_on_cutscene_finished)
	EventBus.stage_transition_started.connect(_on_transition_started)
	EventBus.stage_transition_completed.connect(_on_transition_completed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.boss_intro_started.connect(_on_boss_intro_started)
	EventBus.boss_intro_finished.connect(_on_boss_intro_finished)
	EventBus.damage_received.connect(_on_damage_received)
	EventBus.damage_dealt.connect(_on_damage_dealt)


func can_open() -> bool:
	if _in_cutscene or _in_transition or _in_boss_intro:
		return false
	if _dialogue_count > 0:
		return false
	if PauseMenu.is_open() or InventoryMenu.is_open() or ShopMenu.is_open():
		return false
	if _is_in_combat():
		return false
	return true


func _is_in_combat() -> bool:
	if _last_combat_ms < 0:
		return false
	return Time.get_ticks_msec() - _last_combat_ms < COMBAT_WINDOW_MS


# --- 시그널 핸들러 ---


func _on_cutscene_started(_id: String) -> void:
	_in_cutscene = true


func _on_cutscene_finished(_id: String) -> void:
	_in_cutscene = false


func _on_transition_started(_from_stage: String, _to_stage: String) -> void:
	_in_transition = true


func _on_transition_completed(_stage_id: String) -> void:
	_in_transition = false


func _on_dialogue_started(_npc_id: String) -> void:
	_dialogue_count += 1


func _on_dialogue_finished(_npc_id: String) -> void:
	_dialogue_count = max(0, _dialogue_count - 1)


func _on_boss_intro_started(_boss_id: String) -> void:
	_in_boss_intro = true


func _on_boss_intro_finished(_boss_id: String) -> void:
	_in_boss_intro = false


func _on_damage_received(_amount: float) -> void:
	_last_combat_ms = Time.get_ticks_msec()


func _on_damage_dealt(_target_id: int, _amount: float) -> void:
	_last_combat_ms = Time.get_ticks_msec()

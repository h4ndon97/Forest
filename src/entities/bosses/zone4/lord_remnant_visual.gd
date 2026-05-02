extends Node2D

## 수장의 잔재(Lord Remnant) 보스 잠정 비주얼 — 단순 ColorRect.
## throne_echo_visual.gd 답습 — 페이즈별 색조(P0/P1/P2)를 그림자 왕가 잔재 보라 톤 시리즈로.
## 정식 프로그래밍 아트는 추후 art-spec 작업 시 mire_mother_visual.gd 패턴 답습 가능.

const BODY_WIDTH: float = 60.0
const BODY_HEIGHT: float = 76.0

## P1: 그림자 잔재 어두운 보라 (잠재)
const COLOR_PHASE_0 := Color(0.25, 0.20, 0.30, 1.0)
## P2: 활성 잔영 보라
const COLOR_PHASE_1 := Color(0.45, 0.30, 0.55, 1.0)
## P3: 격렬 광기 보라
const COLOR_PHASE_2 := Color(0.65, 0.45, 0.75, 1.0)

@export var sprite_path: String = ""

var _phase: int = 0
var _boss_id: String = ""
var _rect: ColorRect


func _ready() -> void:
	_setup_fallback_rect()
	_resolve_boss_id()
	if not EventBus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		EventBus.boss_phase_changed.connect(_on_boss_phase_changed)


func set_phase(phase_index: int) -> void:
	_phase = phase_index
	_apply_color()


# --- 내부 ---


func _setup_fallback_rect() -> void:
	_rect = ColorRect.new()
	_rect.size = Vector2(BODY_WIDTH, BODY_HEIGHT)
	_rect.position = Vector2(-BODY_WIDTH * 0.5, -BODY_HEIGHT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = COLOR_PHASE_0
	add_child(_rect)


func _apply_color() -> void:
	if _rect == null:
		return
	match _phase:
		0:
			_rect.color = COLOR_PHASE_0
		1:
			_rect.color = COLOR_PHASE_1
		_:
			_rect.color = COLOR_PHASE_2


func _resolve_boss_id() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var bd: Variant = parent.get("boss_data")
	if bd == null:
		return
	_boss_id = bd.boss_id


func _on_boss_phase_changed(boss_id: String, _from_phase: int, to_phase: int) -> void:
	if boss_id != _boss_id:
		return
	set_phase(to_phase)

extends "res://src/entities/objects/environment/base/environment_object.gd"

## 렌즈(Lens) 환경 오브젝트.
## STOPPED 중 interact()로 프리셋 각도 회전 (거울과 동일 패턴).
## FocusZone 내 적 강도를 focus_intensity로 상시 override (min 병합 — 약화 방향, Cover의 대칭).

@export var lens_data: LensData

var _preset_index: int = 0
var _affected_enemies: Dictionary = {}

@onready var _rotation_pivot: Node2D = $RotationPivot
@onready var _focus_zone: Area2D = $RotationPivot/FocusZone
@onready var _focus_collision: CollisionShape2D = $RotationPivot/FocusZone/CollisionShape2D
@onready var _focus_visual: ColorRect = $RotationPivot/FocusZone/FocusVisual
@onready var _beam_visual: Polygon2D = $RotationPivot/BeamVisual
@onready var _lens_body: Polygon2D = $RotationPivot/LensBody
@onready var _lens_border: Line2D = $RotationPivot/LensBorder
@onready var _highlight_node_local: Node2D = $Highlight
@onready var _prompt_node_local: Node2D = $Prompt


func _ready() -> void:
	highlight_node = _highlight_node_local
	prompt_node = _prompt_node_local
	super._ready()
	if lens_data == null:
		push_warning("Lens: lens_data 미설정")
		return
	data = lens_data
	_preset_index = lens_data.initial_preset_index

	_setup_beam_visual()
	_setup_focus_zone()
	_setup_body_visual()
	_apply_rotation()

	_focus_zone.enemy_entered.connect(_on_enemy_entered)
	_focus_zone.enemy_exited.connect(_on_enemy_exited)


func _process(_delta: float) -> void:
	if lens_data == null:
		return
	# 매 프레임 override 재적용 (EnemySystem 브로드캐스트 무효화)
	if not _affected_enemies.is_empty():
		_reapply_override_to_all()


func _on_interact() -> void:
	if lens_data == null:
		return
	_preset_index = (_preset_index + 1) % maxi(lens_data.preset_count, 1)
	_apply_rotation()
	EventBus.environment_interacted.emit(get_instance_id(), _preset_index)


# --- 내부 ---


func _apply_rotation() -> void:
	if lens_data == null or _rotation_pivot == null:
		return
	var step: float = TAU / float(maxi(lens_data.preset_count, 1))
	_rotation_pivot.rotation = step * float(_preset_index)


func _setup_beam_visual() -> void:
	if lens_data == null or _beam_visual == null:
		return
	# 원뿔 수렴 형태: 넓은 입구 (본체) → 좁은 출구 (focus zone)
	var beam_len: float = lens_data.beam_length
	var focus_len: float = lens_data.focus_zone_length
	var body_half: float = lens_data.body_size.y * 0.5
	var focus_half: float = lens_data.focus_zone_width * 0.5
	var focus_start: float = beam_len - focus_len
	_beam_visual.polygon = PackedVector2Array(
		[
			Vector2(0, -body_half),
			Vector2(focus_start, -focus_half),
			Vector2(beam_len, -focus_half),
			Vector2(beam_len, focus_half),
			Vector2(focus_start, focus_half),
			Vector2(0, body_half),
		]
	)
	_beam_visual.color = Color(1.0, 0.92, 0.35, 0.22)


func _setup_focus_zone() -> void:
	if lens_data == null:
		return
	var focus_len: float = lens_data.focus_zone_length
	var focus_width: float = lens_data.focus_zone_width
	var focus_start: float = lens_data.beam_length - focus_len
	# 집광 영역은 빔 끝단에 위치
	if _focus_collision and _focus_collision.shape is RectangleShape2D:
		(_focus_collision.shape as RectangleShape2D).size = Vector2(focus_len, focus_width)
		_focus_collision.position = Vector2(focus_start + focus_len * 0.5, 0)
	if _focus_visual:
		_focus_visual.size = Vector2(focus_len, focus_width)
		_focus_visual.position = Vector2(focus_start, -focus_width * 0.5)
		_focus_visual.color = Color(1.0, 1.0, 0.6, 0.35)


func _setup_body_visual() -> void:
	if lens_data == null:
		return
	var body: Vector2 = lens_data.body_size
	# 원형 렌즈 본체 (12각형 폴리곤)
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 12
	for i in range(segments):
		var theta: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(theta) * body.x * 0.5, sin(theta) * body.y * 0.5))
	if _lens_body:
		_lens_body.polygon = points
		_lens_body.color = lens_data.body_color
	if _lens_border:
		var border_points: PackedVector2Array = points.duplicate()
		border_points.append(points[0])
		_lens_border.points = border_points
		_lens_border.default_color = lens_data.body_border_color


func _on_enemy_entered(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	_affected_enemies[id] = enemy
	_apply_override(enemy)
	EventBus.environment_blocked_shadow.emit(get_instance_id(), id, true)
	_emit_boss_weak_point(enemy, true)


func _on_enemy_exited(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	if not _affected_enemies.has(id):
		return
	_affected_enemies.erase(id)
	_restore_intensity(enemy)
	EventBus.environment_blocked_shadow.emit(get_instance_id(), id, false)
	_emit_boss_weak_point(enemy, false)


func _emit_boss_weak_point(enemy: Node, exposed: bool) -> void:
	if not enemy.is_in_group("bosses"):
		return
	if not "boss_data" in enemy or enemy.boss_data == null:
		return
	EventBus.boss_weak_point_exposed.emit(enemy.boss_data.boss_id, exposed)


func _apply_override(enemy: Node) -> void:
	if not enemy.has_method("update_intensity"):
		return
	# 약화 모드: min() 병합 — 더 약한 강도가 적용되도록 (Cover의 max와 대칭)
	var current: float = EnemySystem.get_current_intensity()
	var target: float = minf(current, lens_data.focus_intensity)
	enemy.update_intensity(target)


func _reapply_override_to_all() -> void:
	var stale: Array[int] = []
	for id in _affected_enemies.keys():
		var enemy: Node = _affected_enemies[id]
		if not is_instance_valid(enemy):
			stale.append(id)
			continue
		_apply_override(enemy)
	for id in stale:
		_affected_enemies.erase(id)


func _restore_intensity(enemy: Node) -> void:
	if not enemy.has_method("update_intensity"):
		return
	var restore: float = EnemySystem.get_current_intensity()
	# 밤+등불 ON일 때는 per-object 위치 기반 강도로 복원
	if not ShadowSystem.is_day_mode() and ShadowSystem.is_lantern_active():
		restore = ShadowSystem.get_intensity_at(enemy.global_position)
	enemy.update_intensity(restore)

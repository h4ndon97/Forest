extends Area2D

## 보스 약점 Area2D.
## 노출 상태(exposed=true)에서만 player_attack 감지 → boss.apply_player_hit(.., is_weak_point=true).
## 노출은 base_boss가 EventBus.boss_weak_point_exposed 시그널을 받아 set_exposed로 토글.

const PULSE_BASE_ALPHA := 0.55
const PULSE_AMP_ALPHA := 0.25
const PULSE_SPEED := 4.0

var _boss: Node = null
var _exposed: bool = false
var _pulse_t: float = 0.0
var _visual: ColorRect = null
var _shape: CollisionShape2D = null


func setup(boss: Node, offset: Vector2, radius: float) -> void:
	_boss = boss
	position = offset
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = radius
	_visual = get_node_or_null("WeakPointVisual") as ColorRect
	if _visual:
		var size: float = radius * 2.0
		_visual.size = Vector2(size, size)
		_visual.position = Vector2(-radius, -radius)
		_visual.visible = false


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 8
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if not _exposed or _visual == null:
		return
	_pulse_t += delta
	var pulse: float = (sin(_pulse_t * PULSE_SPEED) + 1.0) * 0.5
	var alpha: float = PULSE_BASE_ALPHA + PULSE_AMP_ALPHA * pulse
	var c: Color = _visual.color
	c.a = alpha
	_visual.color = c


func is_exposed() -> bool:
	return _exposed


func set_exposed(exposed: bool) -> void:
	if _exposed == exposed:
		return
	_exposed = exposed
	set_deferred("monitoring", exposed)
	set_deferred("monitorable", exposed)
	if _visual:
		_visual.visible = exposed
		_pulse_t = 0.0


func _on_area_entered(area: Area2D) -> void:
	if not _exposed:
		return
	if not area.is_in_group("player_attack"):
		return
	if _boss == null or not is_instance_valid(_boss):
		return
	var damage: float = area.get_meta("damage", 0.0)
	if damage <= 0.0:
		return
	var is_finish: bool = area.get_meta("is_finish", false)
	if _boss.has_method("apply_player_hit"):
		_boss.apply_player_hit(damage, is_finish, true)

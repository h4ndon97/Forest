extends Area2D

## 적 투사체. 직선 이동 + 수명 만료 + 플레이어/벽 접촉 시 소멸.
## 발사자가 setup() 호출로 방향/속도/데미지/수명을 주입한다.

var _velocity: Vector2 = Vector2.ZERO
var _damage: float = 0.0
var _pending_lifetime: float = -1.0

@onready var _lifetime_timer: Timer = $Lifetime
@onready var _visual: Node2D = $Visual


func setup(direction: Vector2, speed: float, damage: float, lifetime: float) -> void:
	_velocity = direction.normalized() * speed
	_damage = damage
	_pending_lifetime = lifetime
	set_meta("damage", damage)


func _ready() -> void:
	add_to_group("enemy_projectile")
	if _pending_lifetime > 0.0:
		_lifetime_timer.stop()
		_lifetime_timer.wait_time = _pending_lifetime
		_lifetime_timer.start()
	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	body_entered.connect(_on_body_entered)
	_update_visual_facing()


func get_damage() -> float:
	return _damage


## 플레이어 hurtbox가 감지 후 호출. 투사체 소멸.
func on_hit() -> void:
	queue_free()


func _physics_process(delta: float) -> void:
	position += _velocity * delta


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	# 벽(레이어 1) 접촉 시 소멸
	queue_free()


func _update_visual_facing() -> void:
	if _velocity.x < 0.0:
		_visual.scale.x = -1.0

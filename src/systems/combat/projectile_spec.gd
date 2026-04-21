class_name ProjectileSpec
extends Resource

## 투사체 1건의 파라미터를 담는 Resource. 요청자 → CombatSystem.request_projectile(spec).
## Step 1에서는 스키마만 확정. 실제 사용은 Step 4(적 원거리·투사체)부터.

@export_group("Source")
@export_enum("player_attack", "enemy_projectile", "boss_attack")
var source_group: String = "enemy_projectile"

@export_group("Scene")
## enemy_projectile.tscn 등 인스턴싱할 씬.
@export var scene: PackedScene = null
@export var spawn_position: Vector2 = Vector2.ZERO

@export_group("Motion")
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 180.0
@export var lifetime: float = 3.0

@export_group("Damage")
@export var damage: float = 0.0
@export_enum("none", "light", "shadow", "hybrid", "neutral") var attribute: String = "none"

@export_group("Meta")
@export var tags: PackedStringArray = PackedStringArray()

## 발사체 소유자(런타임 전용).
var attacker: Node = null

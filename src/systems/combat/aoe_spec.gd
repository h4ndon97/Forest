class_name AoeSpec
extends Resource

## 광역(AoE) 공격 1건의 파라미터를 담는 Resource.
## Step 1에서는 스키마만 선언 + CombatSystem.request_aoe()는 stub(경고 푸시만).
## 본격 사용은 #2 SkillExec 또는 #3 속성 피니시(hybrid)에서.

@export_group("Source")
@export_enum("player_attack", "enemy_attack", "boss_attack")
var source_group: String = "player_attack"

@export_group("Shape")
@export var center: Vector2 = Vector2.ZERO
@export var radius: float = 40.0

@export_group("Timing")
@export var telegraph_duration: float = 0.0
@export var active_duration: float = 0.2

@export_group("Damage")
@export var damage: float = 0.0
@export_enum("none", "light", "shadow", "hybrid", "neutral") var attribute: String = "none"

@export_group("Meta")
@export var tags: PackedStringArray = PackedStringArray()

## 공격자(런타임 전용).
var attacker: Node = null

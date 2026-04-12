class_name EnemyStatsData
extends Resource

## 적 유형별 기본 스탯 리소스.

@export_group("기본 정보")
@export var enemy_name: String = ""
@export var enemy_type: String = ""  # tree, rock, flower, pillar

@export_group("체력")
@export var base_hp: float = 100.0

@export_group("공격")
@export var base_attack: float = 10.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0

@export_group("이동")
@export var base_speed: float = 60.0
@export var patrol_speed: float = 30.0

@export_group("감지")
@export var detect_range: float = 150.0
@export var lose_range: float = 200.0

@export_group("그림자 반응")
@export var min_intensity: float = 0.2
@export var max_intensity: float = 1.5

@export_group("물리")
@export var collision_width: float = 20.0
@export var collision_height: float = 28.0
@export var gravity_scale: float = 1.0

@export_group("잔류")
@export var leaves_residue: bool = true

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

@export_group("시간 정지 응답")
## 정지 면역 (true 시 시간 정지 중에도 active 유지). zone4 정지 면역 엘리트 등.
## base_enemy.deactivate()에서 가드 — _registry.deactivate_all 호출 시에도 활성 유지.
@export var time_immune: bool = false

@export_group("행동 타입")
## 공격 행동 (melee / ranged / none / ground_tether / ruin_charge)
@export_enum("melee", "ranged", "none", "ground_tether", "ruin_charge")
var attack_behavior: String = "melee"
## 사망 행동 (none / split)
@export_enum("none", "split") var death_behavior: String = "none"

@export_group("근접 공격 형상")
## 공격 히트박스 크기
@export var hitbox_size: Vector2 = Vector2(30.0, 20.0)
## 공격 히트박스 오프셋 (전방 기준, x는 양수 = 전방)
@export var hitbox_offset: Vector2 = Vector2(20.0, -14.0)
## 히트박스 활성 지속 (초). 0이면 ATTACK 상태 내내 활성
@export var hitbox_active_duration: float = 0.0

@export_group("방어")
## 고정 데미지 감산 (피격 후 최소 1 보장)
@export var damage_reduction_flat: float = 0.0
## HURT 상태 진입 확률 (0=항상 저항, 1=항상 경직)
@export var hurt_resistance_chance: float = 1.0

@export_group("원거리 공격")
## 투사체 씬 경로 (ranged일 때 필수)
@export var projectile_scene_path: String = ""
## 투사체 속도 (px/s)
@export var projectile_speed: float = 180.0
## 투사체 수명 (초)
@export var projectile_lifetime: float = 3.0
## 발사 선딜 (공격 트리거 후 실제 발사까지)
@export var projectile_telegraph: float = 0.35

@export_group("분열")
## 분열체 스탯 리소스 경로 (split일 때 필수)
@export var spore_stats_path: String = ""
## 분열체 생성 개수
@export var spore_count: int = 2
## 스폰 분산 반경 (px)
@export var spore_spread_radius: float = 16.0
## 분열체 여부 (재분열 방지)
@export var is_spore: bool = false

@export_group("이동 프로파일")
## 이동 방식 (ground / airborne_homing)
@export_enum("ground", "airborne_homing") var movement_profile: String = "ground"
## airborne_homing: 조향 속도 (rad/s 근사, lerp factor로 사용)
@export var homing_turn_rate: float = 3.0
## airborne_homing: 최대 이동 속도 (px/s)
@export var homing_max_speed: float = 60.0

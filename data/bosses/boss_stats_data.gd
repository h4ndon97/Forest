class_name BossStatsData
extends Resource

## 보스 전용 스탯 리소스.
## EnemyStatsData(base_stats)를 composition으로 포함하고, 페이즈/약점/보상 메타를 추가한다.

@export_group("정체성")
@export var boss_id: String = ""
@export var display_name: String = ""
## INTRO 상태 지속 (포효/등장 연출, 무적)
@export var intro_duration: float = 1.5
## DEFEATED 상태 지속 (사망 연출 후 queue_free)
@export var defeat_duration: float = 2.5

@export_group("기본 스탯")
## EnemyStatsData를 그대로 재사용 — HP/공격력/이동/충돌 형상 등
@export var base_stats: EnemyStatsData

@export_group("페이즈")
## 페이즈 수 (1구역=2, 3구역+=3 이상)
@export var phase_count: int = 2
## 페이즈 전환 HP 임계 비율 (size = phase_count - 1). 예: [0.5] = HP 50%에서 P1→P2
@export var phase_hp_thresholds: PackedFloat32Array = PackedFloat32Array([0.5])
## 페이즈 전환 무적 지속 (s)
@export var phase_transition_duration: float = 1.8
## 페이즈별 공격 패턴 (size = phase_count)
@export var phase_patterns: Array[BossPhasePattern] = []

@export_group("약점 (Phase 3-3-c)")
## 약점 위치 오프셋 (보스 root 기준)
@export var weak_point_offset: Vector2 = Vector2(0, -56)
## 약점 반경 (px)
@export var weak_point_radius: float = 22.0
## 약점 피격 데미지 배율
@export var weak_point_damage_multiplier: float = 2.5
## 약점 활성화 트리거 소스 ("lens_focus" 등 — 향후 확장)
@export var weak_point_reveal_source: String = "lens_focus"

@export_group("보상 (Phase 3-3-d)")
## 잠금 해제 능력 ID (AbilityRegistry 키)
@export var reward_ability_id: String = ""
## 강화 포인트 지급량
@export var reward_growth_points: int = 5
## 드롭 아이템 ID 목록
@export var reward_item_ids: PackedStringArray = PackedStringArray()
## 스토리 단서 StateFlag 키
@export var reward_story_flag: String = ""
## 다음 구역 해금 StateFlag 키
@export var reward_next_zone_flag: String = ""

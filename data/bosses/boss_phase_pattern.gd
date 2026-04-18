class_name BossPhasePattern
extends Resource

## 보스 페이즈별 공격 패턴 정의.
## attack_scripts에 1개 이상 등록 — 2개 이상이면 ATTACK 진입마다 순환 선택 (3-3-b).

@export_group("기본")
@export var pattern_name: String = ""
## 공격 행동 스크립트 경로 (1개 이상). 순환 선택용.
@export var attack_scripts: PackedStringArray = PackedStringArray()
## 각 attack_scripts에 대응하는 ATTACK 쿨다운 (s)
@export var attack_cooldowns: PackedFloat32Array = PackedFloat32Array()
## 각 attack_scripts에 대응하는 텔레그래프(예고선) 지속 (s)
@export var telegraph_durations: PackedFloat32Array = PackedFloat32Array()

@export_group("근접 광역")
## 광역 히트박스 크기
@export var hitbox_size: Vector2 = Vector2(180.0, 60.0)
## 광역 히트박스 오프셋 (전방 기준, x 양수 = 전방)
@export var hitbox_offset: Vector2 = Vector2(90.0, -30.0)
## 히트박스 활성 지속 (s, 텔레그래프 종료 후)
@export var hitbox_active_duration: float = 0.4

@export_group("원거리 스프레드 (Phase 3-3-b)")
## 투사체 씬 경로
@export var projectile_scene_path: String = ""
## 투사체 속도 (px/s)
@export var projectile_speed: float = 180.0
## 발사 개수 (3 = 3way 스프레드)
@export var projectile_spread_count: int = 3
## 발사 각도 분산 (도)
@export var projectile_spread_angle: float = 18.0

@export_group("뿌리 소환 (Phase 3-3-b)")
## 소환할 적 스탯 리소스 경로
@export var root_stats_path: String = ""
## 소환 개수
@export var root_count: int = 3
## 소환 위치 간격 (px)
@export var root_spacing: float = 80.0

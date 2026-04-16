class_name GrowthConfigData
extends Resource

## 성장 시스템 설정 데이터.
## data/growth/growth_config.tres에서 수치 조정.
## 모든 보너스는 포인트당 flat 가산. 변경 가능성 높음 — 수치는 전부 여기서 관리.

# === 포인트 획득 ===
@export_group("Point Earning")
## 적 처치 시 강화 포인트 (최소)
@export var kill_points_min: int = 1
## 적 처치 시 강화 포인트 (최대)
@export var kill_points_max: int = 3
## 스테이지 클리어 시 강화 포인트
@export var stage_clear_points: int = 10
## 보스 처치 시 강화 포인트 (Phase 3)
@export var boss_clear_points: int = 50

# === 빛 투자 (포인트당 보너스) ===
@export_group("Light Investment")
## 공격력 보너스 / 포인트
@export var attack_bonus_per_point: float = 5.0
## 등불 범위 보너스 (px) / 포인트
@export var lantern_range_bonus_per_point: float = 15.0
## 등불 밝기 보너스 / 포인트 (energy 가산)
@export var lantern_brightness_bonus_per_point: float = 0.05

# === 그림자 투자 (포인트당 보너스) ===
@export_group("Shadow Investment")
## HP 보너스 / 포인트
@export var hp_bonus_per_point: float = 10.0

# === 프로퍼티 투자 (포인트당 보너스) ===
@export_group("Property Investment")
## 시간 자원 최대치 보너스 / 포인트
@export var time_max_bonus_per_point: float = 10.0
## 시간 자원 회복량 보너스 / 포인트
@export var time_recovery_bonus_per_point: float = 1.0

# === 혼합 해금 ===
@export_group("Hybrid Unlock")
## 빛·그림자 각각 이 수치 이상 투자 시 혼합 계열 해금
@export var hybrid_unlock_threshold: int = 3

# === 리스펙 ===
@export_group("Respec")
## 리스펙 비용 = 총 투자 포인트 × 이 비율 (강화 포인트 소모)
@export var respec_cost_ratio: float = 0.5

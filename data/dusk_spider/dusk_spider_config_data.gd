class_name DuskSpiderConfigData
extends Resource

## 땅거미 시스템 설정 리소스.
## 이동, 스폰, 강화, 전투 관련 수치를 외부에서 조정한다.

@export_group("이동")
## 맵 1개 이동에 걸리는 실시간 초 (기본 120초 = 2분)
@export var seconds_per_map: float = 120.0

@export_group("스폰")
## 시간 흐름 시작 시 스폰 최소 거리 (맵 수)
@export var spawn_distance_min: int = 3
## 시간 흐름 시작 시 스폰 최대 거리 (맵 수)
@export var spawn_distance_max: int = 5
## 동시 존재 최대 수
@export var max_spiders: int = 3

@export_group("도착 시 강화")
## 도착 시 기존 적 HP 배율 (1.3 = +30%)
@export var reinforce_hp_multiplier: float = 1.3
## 도착 시 기존 적 ATK 배율 (1.3 = +30%)
@export var reinforce_atk_multiplier: float = 1.3

@export_group("전투 (placeholder)")
## 땅거미 자체 HP (일반 적 대비 2배 기준)
@export var combat_hp: float = 200.0
## 땅거미 자체 공격력 (일반 적 대비 1.5배 기준)
@export var combat_attack: float = 45.0
## 처치 시 드롭 포인트
@export var defeat_points: int = 50

class_name MirrorData
extends EnvironmentObjectData

## 거울/수정 환경 오브젝트 데이터.
## 프리셋 각도별 회전 + FLOWING 진입 시 구역 내 적 분열 트리거.

@export_group("회전 프리셋")
## 프리셋 각도 수 (4 = 0/90/180/270도, 8 = 0/45/.../315도)
@export var preset_count: int = 4
## 시작 프리셋 인덱스 (배치 시 초기 각도)
@export var initial_preset_index: int = 0

@export_group("반사 구역")
## 부채꼴 빔 길이 (px)
@export var beam_length: float = 128.0
## 부채꼴 각도 (도, 전체 호)
@export var beam_angle_degrees: float = 60.0

@export_group("분열 트리거")
## FLOWING 진입 시 구역 내 적을 분열시킬지 여부
@export var split_on_flow_start: bool = true
## 공용 분열체 fallback 경로. 적 stats에 spore_stats_path가 비어있을 때 사용.
@export var default_shard_spore_path: String = "res://data/enemies/shard_spore_enemy.tres"

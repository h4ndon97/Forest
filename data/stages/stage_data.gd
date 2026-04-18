class_name StageData
extends Resource

## 스테이지별 설정 리소스.
## 각 스테이지의 정적 데이터를 정의한다.

enum ClearState { UNCLEARED, HALF_CLEARED, FULLY_CLEARED }
enum LockType { NONE, LIGHT, PURIFY, ENVIRONMENT, ABILITY }

@export_group("기본 정보")
## 스테이지 고유 식별자
@export var stage_id: String = ""
## 표시 이름
@export var display_name: String = ""
## 씬 파일 경로
@export var scene_path: String = ""
## 스테이지 초기 시각 (0.0~23.99). 첫 진입 시 이 시간으로 시작.
@export var initial_hour: float = 12.0
## 속한 구역 ID (월드맵 그룹핑용). 빈 문자열이면 "기타".
@export var zone_id: String = ""

@export_group("인접 스테이지")
## 인접 포탈로 연결된 스테이지 ID 목록
@export var adjacent_stages: Array[String] = []

@export_group("잠금")
## 잠금 유형 (NONE이면 잠금 없음)
@export var lock_type: LockType = LockType.NONE
## 잠금 해제 조건 식별자 (능력 ID, 아이템 ID 등)
@export var lock_requirement: String = ""

@export_group("클리어 조건")
## 스테이지 내 총 적 수
@export var total_enemies: int = 0
## 스테이지 내 총 잔류 수 (보통 total_enemies와 동일)
@export var total_residues: int = 0

@export_group("거점 설정")
## 이 스테이지가 거점(체크포인트)인지 여부
@export var is_checkpoint: bool = false

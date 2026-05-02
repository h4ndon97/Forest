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

@export_group("카메라/룸")
## 카메라 limit 영역 크기 (픽셀). 한 화면 = 640x360. 가로 스크롤 룸은 width 확장.
## 카메라는 (0, 0) ~ room_size 사이로 제한된다.
@export var room_size: Vector2 = Vector2(640, 360)

@export_group("월드맵 위치 (직사각형 톱뷰)")
## 월드맵 위치 (normalized 0~1 기준, 화면 640x360 비율). Vector2(-1, -1)=미설정 → 극좌표 fallback.
## REC-UX-007 Stage 1+ 직사각형 톱뷰 채택. 기존 극좌표 필드는 자동 변환 fallback용으로 유지.
## Phase B(2026-05-02)부터 영역(territory)형 전환 — 본 점 좌표는 폴리곤 라벨 위치/연결선 기준점으로 사용.
@export var world_map_pos: Vector2 = Vector2(-1.0, -1.0)

@export_group("월드맵 영역 (폴리곤)")
## 월드맵 stage 영역 폴리곤 (normalized 0~1, 시계방향 권장).
## 빈 배열이면 WorldMapPolygonFallback이 zone 사각형 + stage 인덱스 기반 자동 분할 적용.
## REC-UX-007 Stage 1.5+ 영역형 미니맵 채택(2026-05-02 확정).
@export var world_map_polygon: PackedVector2Array = PackedVector2Array()

@export_group("월드맵 위치 (극좌표 deprecated)")
## 동심 링 인덱스. world_map_pos 미설정 시 자동 변환 fallback. 0=월드맵 미표시(test_*).
@export var radius_ring: int = 0
## 시계 각도 (도). 0°=12시, 시계방향 증가. 0~360. world_map_pos 미설정 시 fallback.
@export var angle_deg: float = 0.0
## 링 반경 오프셋 (픽셀). world_map_pos 미설정 시 fallback.
@export var radius_offset: float = 0.0

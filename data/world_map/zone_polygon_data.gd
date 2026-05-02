class_name ZonePolygonData
extends Resource

## 월드맵 영역 polygon 데이터 — REC-UX-007 Stage 1.
## 각 zone의 영역 polygon 정점 + 기본 색을 보유한다.
## polygon_points가 비어 있으면 renderer가 ring 기반 도넛 default를 자동 생성.

## 영역 식별자. StageData.zone_id와 일치.
@export var zone_id: String = ""

## normalized 0~1 좌표계 기준 polygon 정점들 (화면 비율).
## 비면 renderer가 zone별 가로 띠 default 자동 생성 (직사각형 톱뷰).
@export var polygon_points: PackedVector2Array

## Stage 1 fallback 색. Stage 2 셰이더 도입 시 base color로 활용.
@export var base_color: Color = Color(0.2, 0.2, 0.2)

## 노드/연결선 아래로 깔리도록 음수.
@export var z_index: int = -10

## Stage 3 — 영역 일러스트 PNG 경로. 비면 polygon 색만 표시.
@export var illust_texture_path: String = ""

## Stage 2 — 시간 셰이더 톤 변화 강도(0=무변화, 1=완전 적용).
@export var time_tint_strength: float = 1.0

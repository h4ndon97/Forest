class_name EnvironmentObjectData
extends Resource

## 환경 오브젝트 베이스 Resource.
## 거울/렌즈/차폐물/반사 바닥이 공통으로 사용하는 메타데이터.

@export_group("기본 정보")
@export var object_name: String = ""
@export var prompt_text: String = "상호작용"

@export_group("상호작용")
## 플레이어 상호작용 가능 여부 (반사 바닥 = false)
@export var can_interact: bool = true
## 상호작용 반경 (플레이어 InteractionDetector와의 거리 기준 선택에 사용)
@export var interaction_radius: float = 48.0

@export_group("영향 구역")
## 영향 구역 기본 반경 (원형 fallback). 서브 타입이 별도 모양을 가질 경우 무시될 수 있음.
@export var influence_radius: float = 64.0

@export_group("비주얼")
## 추후 주입할 스프라이트 경로. 비어있으면 fallback 비주얼 사용.
@export var sprite_path: String = ""

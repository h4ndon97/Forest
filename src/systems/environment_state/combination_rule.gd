class_name CombinationRule
extends Resource

## 환경 오브젝트 상태 조합 규칙.
## EnvironmentStateRegistry가 이 규칙들을 순회하며 조합 만족 여부를 판정한다.
## 2구역+ 앵커 — 1구역에서는 스모크 테스트(V8)에만 사용.

## 이 조합의 식별자 (예: "fog_mirrors_aligned").
@export var combo_key: String = ""
## 필요 상태 매핑. { object_id: state_name } 형식. 스테이지 설계 시점에 고정되는 구체 값.
@export var required_states: Dictionary = {}

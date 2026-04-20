extends Node2D

## 환경 오브젝트 하이라이트 (비활성화됨).
## 오브젝트 자체의 시각(글로우·부유 등)으로 상호작용 대상임을 전달하도록 변경.
## 씬 구조와 하위 호환을 위해 노드/속성은 유지.

@export var size: Vector2 = Vector2(40, 56)
@export var thickness: float = 1.5
@export var color: Color = Color(1.0, 0.9, 0.3, 0.9)

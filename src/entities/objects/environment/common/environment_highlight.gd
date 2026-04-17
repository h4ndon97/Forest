extends Node2D

## 환경 오브젝트 하이라이트 (fallback 테두리).
## 가장 가까운 타겟이 되었을 때 노란색 테두리 표시.

@export var size: Vector2 = Vector2(40, 56)
@export var thickness: float = 1.5
@export var color: Color = Color(1.0, 0.9, 0.3, 0.9)

var _line: Line2D


func _ready() -> void:
	_line = Line2D.new()
	_line.width = thickness
	_line.default_color = color
	var half: Vector2 = size * 0.5
	_line.add_point(Vector2(-half.x, -half.y))
	_line.add_point(Vector2(half.x, -half.y))
	_line.add_point(Vector2(half.x, half.y))
	_line.add_point(Vector2(-half.x, half.y))
	_line.add_point(Vector2(-half.x, -half.y))
	add_child(_line)

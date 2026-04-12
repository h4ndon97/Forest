extends Node2D

## 플로팅 데미지 숫자.
## 생성 후 위로 떠오르며 페이드아웃되고 자동 제거된다.

const FLOAT_DISTANCE := 24.0
const DURATION := 0.6
const FONT_SIZE_NORMAL := 8
const FONT_SIZE_FINISH := 10

var _label: Label


func setup(amount: float, is_finish: bool = false) -> void:
	_label = Label.new()
	_label.text = str(int(amount))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var font_size: int = FONT_SIZE_FINISH if is_finish else FONT_SIZE_NORMAL
	_label.add_theme_font_size_override("font_size", font_size)

	var font_color := Color(1.0, 0.85, 0.3) if is_finish else Color(1.0, 1.0, 1.0)
	_label.add_theme_color_override("font_color", font_color)

	# 라벨을 중앙 정렬
	_label.position = Vector2(-20, -10)
	_label.size = Vector2(40, 20)
	add_child(_label)

	# 약간의 수평 랜덤 오프셋
	position.x += randf_range(-6.0, 6.0)

	# 떠오르며 페이드아웃
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, DURATION)
	tween.tween_property(_label, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)

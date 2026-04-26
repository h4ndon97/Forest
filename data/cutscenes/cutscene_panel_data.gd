class_name CutscenePanelData
extends Resource

## 컷신 1장 패널.
## 일러스트 + 텍스트 라인 묶음 + 페이드/홀드 타이밍.
## 일러스트 경로가 비었거나 로드 실패 시 placeholder ColorRect로 자동 fallback.

@export_file("*.png", "*.webp") var image_path: String = ""
@export var speaker: String = ""
@export_multiline var lines: Array[String] = []
@export var fade_in: float = 0.6
@export var fade_out: float = 0.6
## 마지막 라인 표시 후 자동 진행까지 대기 시간. 0이면 입력 대기.
@export var auto_advance_hold: float = 0.0
## 일러스트 로드 실패 시 placeholder 색.
@export var placeholder_tint: Color = Color(0.10, 0.08, 0.16, 1.0)

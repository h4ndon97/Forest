class_name DialogueData
extends Resource

## 대화 라인 데이터 리소스.
## NPC가 참조해 DialogueBox에 전달한다.
## 분기/변수/다국어는 미지원 — 필요 시 후속 리팩터로 확장.

@export var dialogue_id: String = ""
@export var speaker: String = ""
@export var lines: Array[String] = []

class_name CutsceneData
extends Resource

## 컷신 시퀀스 정의.
## panels Array 순서대로 재생. 패널 사이는 fade_out → fade_in 자연 연결.
## OverlaySystem.play_cutscene(data)로 호출.

@export var cutscene_id: String = ""
@export var panels: Array[CutscenePanelData] = []
## 스킵 입력(ESC) 허용 여부. 핵심 스토리 비트는 false 가능.
@export var skippable: bool = true
## 재생 중 시간 흐름 정지 여부. 보스 등장처럼 정지가 자연스러운 경우 true.
@export var pause_time_during: bool = false
## 시네마틱 블랙바 두께 (0이면 바 미사용).
@export var cinematic_bar_thickness: float = 36.0

class_name EchoData
extends Resource

## REC-MECH-001 — Echo Nail 잔상 데이터.
## 정지된 적/NPC/오브젝트/잔재에 부착되는 EchoTarget이 참조한다.
## 시간 정지 중 플레이어가 echo_nail 액션으로 잔상을 들여다보면 본 데이터의
## lines / cutscene / shard_reward를 매체(DialogueBox 또는 CutscenePanel)로 재생한다.

## EchoTarget 식별자. 중복되지 않도록 고유 부여.
@export var echo_id: String = ""

## 잔상 주체 분류. enemy / npc / object / residue.
## EventBus.echo_revealed 와 함께 emit되어 NARR/통계 분기에 활용.
@export var subject_type: StringName = &"enemy"

## UI 라벨용 표시명 ("정지된 병사" / "잊혀진 비석" 등).
@export var subject_label: String = ""

## 잔상 텍스트 라인. 1~3장 권장.
@export_multiline var lines: Array[String] = []

## 0=DialogueBox(가벼움) — 적/오브젝트.
## 1=Cutscene(컷신) — 보스/특수 NPC.
@export_enum("Dialogue", "Cutscene") var present_mode: int = 0

## present_mode=1일 때 재생할 CutsceneData (.tres) 경로.
## 비어있거나 로드 실패 시 0(Dialogue)로 fallback.
@export_file("*.tres") var cutscene_path: String = ""

## 처치 보상 — Memory Shard 획득량.
@export var shard_reward: int = 1

## 잔상 발광 색조. 0=light(노랑) / 1=shadow(보라) / 2=neutral(회색).
@export_enum("Light", "Shadow", "Neutral") var vfx_palette: int = 0

## 후속 NARR 분기 트리거용 (옵션). echo_finished 시 함께 emit.
## 비어있으면 emit 안 함.
@export var emit_event: StringName = &""

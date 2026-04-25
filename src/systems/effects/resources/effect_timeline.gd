class_name EffectTimeline
extends Resource

## 이펙트 시퀀스 1건 = "한 번의 연출 단위". offset 기반 cue 배열.
## 스펙: docs/refactor/EFFECT_TIMELINE_SPEC.md §2.1.

## 에디터/디버그용 표시명.
@export var display_name: String = ""
## 시간 정지 정책.
##   ignore: 힛스톱/pause 중에도 진행 (피니시, 시간정지 해제 등)
##   respect: time_scale에 따라 늦춰짐 (미래 앰비언트성 예약, 현재 미사용)
@export_enum("ignore", "respect") var time_policy: String = "ignore"
## 총 예상 길이 (참고용, 정합성 체크). 실제 실행은 cue.offset_sec가 기준.
@export var expected_duration: float = 0.0
## PauseMenu(get_tree().paused=true) 중에도 재생 허용 여부. 기본 false.
@export var allow_during_pause: bool = false
## cue 배열. 시간순 정렬이 아니어도 Player가 내부 정렬.
@export var cues: Array[EffectCue] = []

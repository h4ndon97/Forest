class_name HiddenRevealerData
extends Resource

## 숨김 노출 설정 리소스.
## 감지 조건(4종) 충족 시 타깃 노드를 드러내는 동작 파라미터.
## 감지 자체는 HiddenRevealer가 외부 센서/detector 시그널을 구독하여 위임 수신한다.

enum RevealCondition { LIGHT_SENSOR, REFLECTION, PURIFICATION, SHADOW_COVER, FLAG }
enum RevealAction { QUEUE_FREE, SET_VISIBLE }

@export var reveal_condition: RevealCondition = RevealCondition.LIGHT_SENSOR
@export var reveal_action: RevealAction = RevealAction.SET_VISIBLE
@export var one_shot: bool = true
## SHADOW_COVER 조건 전용: 플레이어가 차폐물 그림자 영역에 머물러야 하는 시간(초).
@export var require_sustained_seconds: float = 1.0
## 정화 위치 매칭 허용 오차(픽셀).
@export var purification_match_distance: float = 12.0
## FLAG 조건 전용: 이 StateFlag가 true가 되면 reveal.
@export var trigger_flag_id: String = ""

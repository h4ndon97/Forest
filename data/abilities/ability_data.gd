class_name AbilityData
extends Resource

## 영구 능력(Ability) 데이터 정의.
## 보스 처치 등으로 영구 해금되는 이동/상호작용 능력.
## 스킬(SkillData)과 분리: 스킬은 시간 자원 소모/장착식, 능력은 무자원/영구 보유.

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Classification")
## "dash" / "jump" / "interaction" 등 (확장용)
@export var category: String = "dash"

@export_group("UI")
## 아이콘 경로 (UI/HUD용, 후속 단계에서 사용)
@export var icon_path: String = ""
## 해금 알림용 스토리 플래그 (선택)
@export var unlock_story_flag: String = ""

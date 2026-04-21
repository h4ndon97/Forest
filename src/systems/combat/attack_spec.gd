class_name AttackSpec
extends Resource

## 공격 1건의 파라미터를 담는 Resource. 요청자 → CombatSystem.request_attack(spec).
## Step 1(본 커밋)에서는 스키마만 확정. 호출자는 Step 2(player_combo) 이후 단계적으로 연결.
## damage_resolver가 Step 6에서 읽을 필드(attribute·is_finish·piercing·multi_hit_*·knockback)도
## 스키마 안정성을 위해 이 시점에 선제적으로 선언한다.

@export_group("Source")
## 히트박스에 추가할 그룹명. base_enemy 등이 이 그룹을 감지해 데미지 수신.
@export_enum("player_attack", "enemy_attack", "boss_attack")
var source_group: String = "player_attack"

@export_group("Shape")
@export var hitbox_size: Vector2 = Vector2(36, 24)
@export var hitbox_offset: Vector2 = Vector2(24, -14)
@export_enum("rect", "circle") var shape_type: String = "rect"
## shape_type == "circle"일 때만 사용. rect는 hitbox_size를 쓴다.
@export var circle_radius: float = 0.0

@export_group("Timing")
## 예고선(telegraph) 단계. 0이면 즉시 active. 보스 공격 흡수용.
@export var telegraph_duration: float = 0.0
## 히트박스가 monitoring=true 상태로 유지되는 시간.
@export var active_duration: float = 0.3

@export_group("Damage")
@export var damage: float = 0.0
@export_enum("none", "light", "shadow", "hybrid", "neutral") var attribute: String = "none"
@export var is_finish: bool = false
## 다수 적 관통 허용 (#3 light 피니시).
@export var piercing: bool = false
## 다단히트 횟수 (#3 shadow 피니시). 기본 1.
@export var multi_hit_count: int = 1
## 다단히트 간격(초). multi_hit_count > 1일 때만 의미.
@export var multi_hit_interval: float = 0.0
## 넉백 강도 (#3 neutral 피니시 강화 등).
@export var knockback: float = 0.0

@export_group("Meta")
## 분류 태그. 예: ["combo", "hit_3"] / ["skill"] / ["boss", "p1_melee_aoe"].
@export var tags: PackedStringArray = PackedStringArray()
## effect_type="skill" 계열에서 원본 스킬 식별용. 그 외는 빈 문자열.
@export var skill_id: String = ""

## 히트박스 소유자(방향/속성 해석 기준 + 자기 피격 제외). 런타임 전용 — 에디터에서 설정 불가.
var attacker: Node = null

class_name SkillData
extends Resource

## 스킬 데이터 정의.
## data/skills/*.tres에서 수치 조정.

# === 기본 정보 ===
@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# === 분류 ===
@export_group("Classification")
## "light" / "shadow" / "hybrid"
@export var path: String = "light"
## "active" / "passive"
@export var skill_type: String = "active"
## 1~3 (경로 내 해금 순서)
@export var tier: int = 1

# === 효과 타입 ===
@export_group("Effect")
## "melee" / "aoe" / "projectile" / "buff"
@export var effect_type: String = "melee"
## melee 히트박스 크기
@export var hitbox_size: Vector2 = Vector2(40, 28)
## melee 히트박스 오프셋 (facing 기준)
@export var hitbox_offset: Vector2 = Vector2(28, -14)
## AoE 반경 (effect_type == "aoe" 시)
@export var aoe_radius: float = 48.0

# === 수치 ===
@export_group("Parameters")
@export var damage: float = 30.0
@export var cooldown: float = 3.0
## 시간 자원 소모량
@export var time_cost: float = 5.0
## 히트박스 활성 시간
@export var active_duration: float = 0.25

# === 아트 ===
@export_group("Art")
## 스킬 아이콘 PNG 경로. 비어있으면 skill_icons.gd의 프로그래밍 드로잉 폴백.
@export var icon_path: String = ""

@tool
class_name WeaponData
extends "res://data/items/item_data.gd"

## 무기(=등불) 아이템 리소스.
## 의미: 주인공의 무기는 등불. 등불의 빛으로 빛 검을 발현해 전투(2026-05-02 확정).
## 클래스명 WeaponData는 코드 호환성 위해 유지.

@export_group("Weapon Stats")
## 공격력 가산 (flat)
@export var attack_bonus: float = 0.0
## 공격속도 배율 (1.0 = 기본)
@export var attack_speed_mult: float = 1.0
## 콤보 데미지 배율 (1.0 = 기본)
@export var combo_damage_mult: float = 1.0

@export_group("Lantern Visual")
## 등불 빛 색 (발현되는 빛 검 색에도 반영). Color(0,0,0,0)이면 속성 토글에 따라 자동 매핑.
@export var light_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## 시그니처 효과 ID (Phase 5 hook). 빈 StringName이면 효과 없음.
@export var signature_effect: StringName = &""

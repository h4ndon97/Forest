@tool
class_name WeaponData
extends "res://data/items/item_data.gd"

## 무기 아이템 리소스.
## 공격 관련 보너스를 정의한다.

@export_group("Weapon Stats")
## 공격력 가산 (flat)
@export var attack_bonus: float = 0.0
## 공격속도 배율 (1.0 = 기본)
@export var attack_speed_mult: float = 1.0
## 콤보 데미지 배율 (1.0 = 기본)
@export var combo_damage_mult: float = 1.0

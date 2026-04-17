@tool
class_name ArmorData
extends "res://data/items/item_data.gd"

## 방어구 아이템 리소스.
## 방어 관련 보너스를 정의한다.

@export_group("Armor Stats")
## 최대 HP 가산 (flat)
@export var hp_bonus: float = 0.0
## 피격 데미지 감소 (flat)
@export var defense_bonus: float = 0.0

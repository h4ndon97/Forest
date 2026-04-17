@tool
class_name ConsumableData
extends "res://data/items/item_data.gd"

## 소모품 아이템 리소스.
## HP 회복 / 시간자원 회복 2종.

enum ConsumableType { HP_RECOVER, TIME_RECOVER }

@export_group("Consumable")
@export var consumable_type: ConsumableType = ConsumableType.HP_RECOVER
## 회복량
@export var effect_amount: float = 30.0
## 최대 소지량
@export var max_carry: int = 3

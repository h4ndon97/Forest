@tool
class_name AccessoryData
extends "res://data/items/item_data.gd"

## 장신구 아이템 리소스.
## 수치 보정 + 특수 효과 (개별 효과만, 시너지 없음).

@export_group("Stat Bonuses")
@export var attack_bonus: float = 0.0
@export var hp_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var time_max_bonus: float = 0.0
@export var time_recovery_bonus: float = 0.0

@export_group("Special Effect")
## 특수 효과 ID ("" = 효과 없음). Phase 4~5에서 효과 시스템 확장.
@export var special_effect_id: String = ""

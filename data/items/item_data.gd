class_name ItemData
extends Resource

## 아이템 공통 베이스 리소스.
## 모든 아이템(무기, 방어구, 장신구, 소모품)은 이 클래스를 상속한다.

enum ItemCategory { WEAPON, ARMOR, ACCESSORY, CONSUMABLE }
enum ItemRarity { COMMON, RARE, UNIQUE }

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var category: ItemCategory = ItemCategory.WEAPON
@export var rarity: ItemRarity = ItemRarity.COMMON

@export_group("Visual")
## null이면 등급별 ColorRect 플레이스홀더 표시
@export var icon: Texture2D

@export_group("Shop")
## 0 = 구매 불가
@export var buy_price: int = 0
## 0 = 판매 불가
@export var sell_price: int = 0

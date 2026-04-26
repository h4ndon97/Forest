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
## REC-UX-003: 메카닉 설명(description)과 별개의 짧은 시/산문 (Blasphemous Rosary 패턴).
## 한국어 시조 풍 또는 짧은 산문 권장. 작가 협업 시 채워짐. 빈 문자열이면 표시 안 함.
@export_multiline var flavor_text: String = ""

@export_group("Visual")
## null이면 등급별 ColorRect 플레이스홀더 표시
@export var icon: Texture2D

@export_group("Shop")
## 0 = 구매 불가
@export var buy_price: int = 0
## 0 = 판매 불가
@export var sell_price: int = 0

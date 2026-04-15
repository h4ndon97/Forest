class_name EnemyConfigData
extends Resource

## 적 시스템 전역 설정 리소스.

@export_group("활성화")
## 시간 흐름 시작 후 적 활성화까지 딜레이 (초)
@export var activation_delay: float = 0.3

@export_group("전역 강도")
## ShadowSystem의 전역 강도 최솟값 (shadow_config의 min_intensity와 동일해야 함)
@export var global_intensity_min: float = 0.2
## ShadowSystem의 전역 강도 최댓값
@export var global_intensity_max: float = 1.5

@export_group("잔류")
## 잔류 지속 시간 (-1 = 영구, 땅거미가 처리)
@export var residue_duration: float = -1.0
## 잔류 부활 시 HP 비율
@export var residue_revive_hp_ratio: float = 0.5
## 잔류 부활 시 공격력 비율
@export var residue_revive_attack_ratio: float = 1.5
## 부활 적이 다시 잔류를 남기는지 여부
@export var revived_leaves_residue: bool = false

@export_group("AI 행동")
## 순찰 전환 간격 (초)
@export var patrol_interval: float = 3.0
## 피격 경직 지속 시간 (초)
@export var hurt_duration: float = 0.3

@export_group("임시 전투")
## CombatSystem 구현 전 임시 플레이어 공격력
@export var temp_player_damage: float = 25.0

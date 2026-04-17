# 시간이 멈춘 숲 — 7. 아이템 시스템

> 이 문서는 장비, 장신구, 소모품의 종류와 획득 경로를 정의한다.
> 성장 시스템(GROWTH.md)과 전투 시스템(COMBAT.md)에서 확정된 구조 위에서 설계된다.

---

## 1. 아이템 카테고리

### 확정된 규칙 (STAGES.md, GROWTH.md, COMBAT.md)
- 장비/장신구를 통한 캐릭터 강화
- 획득 경로: 전투(적 처치 드롭), 맵 배치, 기믹/퍼즐 풀이, 보스 처치, 상점
- 프로퍼티 능력치(시간 자원 등)는 장비로도 올릴 수 있음
- HP 회복 아이템 존재 (전투 중 사용)
- 시간 자원 회복 아이템 존재 (스킬 사용 시 flat 소비 보충용, Phase 2-1 확정)

### 카테고리 (확정)
- **장비**: 무기 (1슬롯) + 방어구 (1슬롯)
- **장신구**: 3슬롯
- **소모품**: 일회성 사용 아이템
- **등불**: 장비가 아님. 성장 시스템으로 강화.

총 장착 슬롯: **무기 1 + 방어구 1 + 장신구 3 = 5슬롯**

### 등급 체계 (확정)
- **3등급**: 일반(COMMON) / 희귀(RARE) / 유니크(UNIQUE)
- 등급만 존재, 강화/업그레이드 시스템 없음
- 등급별 UI 색상: 일반=회색, 희귀=파랑, 유니크=금색

---

## 2. 장비

### 무기 (확정)
- 검 교체 가능
- 검마다 다른 능력치/특성
- 보너스: 공격력(attack_bonus), 공격속도(attack_speed_mult), 콤보 데미지(combo_damage_mult)

### 방어구 (확정)
- 슬롯 1개
- 보너스: HP(hp_bonus), 방어력(defense_bonus)

### 장비 보너스 적용 (확정)
- 성장 보너스 + 장비 보너스 합산 방식
- 방어력: `maxf(피해량 - 방어력, 1.0)` — 최소 1 데미지 보장
- 장비 변경 시 `equipment_stats_changed` 시그널로 관련 시스템 자동 갱신

---

## 3. 장신구

### 구조 (확정)
- 슬롯 3개

### 효과 방향 (확정)
- **능력치 보정 + 특수 효과** — 장신구마다 다름
  - 수치 보정: 공격력, HP, 방어력, 시간 자원 최대치, 시간 회복량
  - 고유 효과: special_effect_id 필드 (Phase 3+ 구현)

### 미결 사항
- [ ] 장신구 조합/시너지 여부
- [ ] 특수 효과 구체 목록

---

## 4. 소모품

### 소지 구조 (확정)
- **종류별 개수 제한** — 종류마다 최대 소지량 설정
- 거점에서 전량 보충 (full_recovery_requested)
- 거점 + 인게임 모두 사용 가능

### 소모품 종류 (확정)
- **HP 회복** (HP_RECOVER): 키 1번. HP를 effect_amount만큼 즉시 회복
- **시간자원 회복** (TIME_RECOVER): 키 2번. 시간 자원을 effect_amount만큼 즉시 회복

### 소지량 (확정)
- 종류별 최대 3개 (max_carry 필드로 아이템별 조정 가능)

### 획득 경로 (확정)
- 적 드롭 (확률 기반)
- 맵 배치 (ItemDrop 엔티티)
- 거점 상점

---

## 5. 상점

### 구조 (확정)
- 거점에 ShopKeeper NPC 배치
- interact 키(F)로 상점 UI 열기
- 상점별 판매 아이템 목록 설정 가능 (shop_items export)

### 화폐 (미결)
- Phase 5에서 결정. 현재 무조건 구매 성공 (테스트용)

### 미결 사항
- [ ] 화폐 종류 및 획득 방식
- [ ] 판매(되팔기) 기능 여부

---

## 6. 드롭 시스템

### 적 드롭 (확정)
- 적 사망 시 `enemy_drop_requested` 시그널 발신
- InventorySystem에서 확률 판정 → ItemDrop 엔티티 생성
- 현재 테스트용: 30% 확률, hp_potion/time_crystal 균일 랜덤

### 맵 배치 드롭 (확정)
- ItemDrop 엔티티를 씬에 직접 배치
- interact 키(F)로 획득

### 미결 사항
- [ ] 적 종류별 드롭 테이블 (밸런싱)
- [ ] 드롭 확률 곡선 (밸런싱)

---

## 7. 구현 상태 (Phase 2-7 완료)

### Resource 클래스
- `ItemData` (base): id, display_name, description, category, rarity, icon, buy_price, sell_price
- `WeaponData` extends ItemData: attack_bonus, attack_speed_mult, combo_damage_mult
- `ArmorData` extends ItemData: hp_bonus, defense_bonus
- `AccessoryData` extends ItemData: attack_bonus, hp_bonus, defense_bonus, time_max_bonus, time_recovery_bonus, special_effect_id
- `ConsumableData` extends ItemData: consumable_type, effect_amount, max_carry

### InventorySystem Autoload (4개 자식 컴포넌트)
- **ItemRegistry**: data/items/ 하위 .tres 파일 자동 로드/캐시
- **EquipmentManager**: 5슬롯 장착/해제, 카테고리별 자동 슬롯 매칭
- **ConsumableManager**: 소모품 재고 추적, 사용, 거점 보충
- **EquipmentStatCalculator**: 장착 아이템 보너스 합산

### UI
- **ConsumableHud**: 하단좌측 2슬롯 (HP=빨강, Time=파랑), 키 1/2로 사용, 사용 시 플래시 연출
- **InventoryMenu** (Autoload): Tab으로 열기, 장비 슬롯(좌) + 소지 아이템(우) + 정보(하), 거점에서만 장착 가능
- **ShopMenu** (Autoload): 상점 NPC interact로 열기, 아이템 목록 + 가격 + 등급 색상

### 시스템 연동
- **HP**: 성장 + 장비 hp_bonus 합산, 방어력 적용, HP 소모품 회복
- **전투**: 성장 + 장비 attack_bonus 합산
- **시간 자원**: 성장 + 장비 time_max/recovery_bonus 합산, 시간 소모품 회복
- **세이브/로드**: SaveManager에 인벤토리 데이터 통합

### 테스트 데이터
- `sword_basic.tres`: 낡은 검 (COMMON, ATK +5)
- `sword_shadow.tres`: 그림자 검 (RARE, ATK +15, 속도 0.9, 콤보 1.2)
- `leather_vest.tres`: 가죽 조끼 (COMMON, HP +20, DEF +3)
- `ring_of_strength.tres`: 힘의 반지 (COMMON, ATK +8)
- `hp_potion.tres`: HP 물약 (회복 30, 최대 3)
- `time_crystal.tres`: 시간 수정 (회복 20, 최대 3)

### 미결 사항 (전체)
- [ ] 화폐 시스템 (Phase 5)
- [ ] 장신구 특수 효과 구현 (Phase 3+)
- [ ] 장신구 조합/시너지 여부
- [ ] 적 종류별 드롭 테이블 (밸런싱)
- [ ] 수치 밸런싱 (가격, 보너스 수치, 소지량 등)

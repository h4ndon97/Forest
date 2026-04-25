## 시스템 간 통신을 위한 이벤트 버스.
## 모든 시스템 간 시그널은 여기에 정의한다.
## 시스템이 직접 서로를 참조하지 않고, EventBus를 통해 통신한다.
##
## 시그널 구독 정책 (Phase 4-0 #5, 2026-04-25):
## emit/connect 양방향이 채워진 시그널은 별도 표기 없음. 한쪽만 채워진 시그널은 끝에
## "# subscriber: <사유>" 인라인 주석으로 의도를 명시한다. 사유 패턴:
##   - "Phase 4-A 보스" — 2~5구역 보스 진입 시 활용 예정 (1구역 보스는 직접 호출 경로)
##   - "Phase 5 UI ..." — UI 폴리시 작업에서 연결 예정
##   - "통계 예약" — 분석/디버그용. 후속 통계 시스템 도입 시 활용
##   - "HUD 폴링 대체" — HUD가 getter API로 처리 중, 시그널은 잉여
##   - "외부 구독 예약" — 발신자 노드 내부 처리. 외부 시스템 알림용 자리
extends Node

# === 시간 시스템 ===
signal time_set_requested(hour: float)
signal time_state_changed(old_state: int, new_state: int)
signal current_hour_changed(hour: float)
signal sun_state_updated(sun_angle: float, is_day: bool)
signal time_manipulated(from_hour: float, to_hour: float)  # subscriber: 통계 예약
signal time_flow_started(current_hour: float)
signal time_flow_stopped(current_hour: float)
signal day_night_changed(is_day: bool)

# === 그림자 시스템 ===
signal shadow_params_changed(direction: Vector2, scale: float, intensity: float)
signal shadow_scale_changed(object_id: int, scale: float)

# === 적 시스템 ===
signal enemy_spawned(enemy_id: int)  # subscriber: 통계 예약
signal enemy_killed(enemy_id: int, enemy_name: String)
signal residue_left(position: Vector2, killed_during_day: bool)
signal residue_purified(position: Vector2)
signal residue_revival_requested(stage_id: String)
signal residue_revived(position: Vector2, enemy_type: String)
signal enemy_projectile_fired(origin: Vector2, direction: Vector2)  # subscriber: 통계 예약
signal enemy_split_spawned(origin: Vector2, spore_count: int)  # subscriber: 통계 예약

# === 땅거미 시스템 ===
signal dusk_spider_spawned(spider_id: int)
signal dusk_spider_approached(distance: int)
signal dusk_spider_arrived(stage_id: String)
signal dusk_spider_defeated(spider_id: int)
signal enemy_reinforce_requested(stage_id: String, hp_mult: float, atk_mult: float)

# === 스테이지 시스템 ===
signal stage_entered(stage_id: String)
signal stage_clear_updated(stage_id: String, clear_level: int)
signal spawn_point_set(position: Vector2)
signal stage_enemies_sync_requested(stage_id: String, killed_names: Array)
## options 키 (모두 선택):
##   fade_color: Color (default Color.BLACK)
##   skip_fade_out: bool (default false) — 화면 이미 검정일 때 페이드아웃 스킵 (죽음 경로)
##   fade_in_duration: float (default StageTransition.FADE_DURATION)
signal stage_transition_requested(
	target_stage_id: String, entry_direction: String, options: Dictionary
)
signal stage_transition_started(from_stage: String, to_stage: String)
signal stage_transition_completed(stage_id: String)
signal stage_access_denied(stage_id: String, lock_type: int, reason: String)

# === 시간 전파 ===
signal flow_rate_changed(rate: float)
signal propagation_origin_changed(is_origin: bool)
signal time_flow_paused
signal time_flow_resumed
signal time_hour_sync_requested(hour: float)
signal time_flow_resume_requested(hour: float, rate: float)

# === 전투 시스템 ===
signal combo_hit_landed(hit_number: int)
signal combo_finished(attribute: String)
signal combo_resetted
signal damage_dealt(target_id: int, amount: float)  # subscriber: 통계 예약
signal damage_received(amount: float)  # subscriber: 통계 예약
signal health_changed(current_hp: float, max_hp: float)
signal player_died
signal player_respawned(position: Vector2)

# === 성장 시스템 ===
signal points_earned(amount: int, source: String)  # subscriber: 통계/UI 예약
signal skill_unlocked(skill_id: String)
signal growth_stats_changed
# subscriber: Phase 5 UI
signal growth_points_changed(growth_available: int, property_available: int)
signal growth_invested(category: String, total_invested: int)  # subscriber: 통계 예약
signal growth_respec_completed  # subscriber: Phase 5 UI 피드백
signal hybrid_unlocked

# === 등불 시스템 ===
signal lantern_toggled(is_on: bool, lantern_position: Vector2)

# === 거점 시스템 ===
signal checkpoint_entered(checkpoint_id: String)
signal checkpoint_exited(checkpoint_id: String)
signal full_recovery_requested

# === 월드맵 ===
signal world_map_opened
signal world_map_closed

# === 스킬 시스템 ===
signal skill_equipped(slot_index: int, skill_id: String)
signal skill_unequipped(slot_index: int)
signal skill_used(slot_index: int, skill_id: String)
# subscriber: HUD 폴링 대체 (skill_hud.get_cooldown_ratio)
signal skill_cooldown_started(slot_index: int, duration: float)
signal skill_cooldown_finished(slot_index: int)
signal finish_attribute_changed(attribute: String)  # subscriber: Phase 5 HUD 속성 아이콘

# === 시간 자원 ===
signal time_resource_changed(current: float, max_val: float)
signal time_resource_depleted  # subscriber: Phase 5 UI 피드백
signal time_resource_consume_flat_requested(amount: float)

# === 인벤토리/장비 시스템 ===
signal item_acquired(item_id: String)
signal item_removed(item_id: String)  # subscriber: Phase 5 UI 갱신
## 소모품 소지 한도 가득 차서 획득 실패. ItemPickupPopup이 안내 메시지 표시.
signal item_pickup_full(item_id: String)
## slot_type: 0=weapon, 1=armor, 2~4=accessory. item_id="" = 해제
signal equipment_changed(slot_type: int, item_id: String)
signal equipment_stats_changed
signal consumable_used(consumable_type: int, amount: float)
signal consumable_count_changed(item_id: String, current: int, max_val: int)
signal consumables_refilled  # subscriber: Phase 5 UI 갱신

# === 상점 시스템 ===
signal shop_opened(shop_id: String)
signal shop_closed
signal shop_purchase_completed(item_id: String)  # subscriber: Phase 5 UI 피드백

# === 인벤토리 UI ===
signal inventory_opened
signal inventory_closed

# === 아이템 드롭 ===
signal enemy_drop_requested(position: Vector2, enemy_name: String)

# === 환경 오브젝트 시스템 ===
signal environment_interacted(object_id: int, state_index: int)  # subscriber: 통계 예약
signal environment_split_triggered(object_id: int, enemy_ids: Array)  # subscriber: 통계 예약
signal environment_blocked_shadow(cover_id: int, caster_id: int, blocked: bool)  # subscriber: 통계 예약

# === 환경 센서/상태 (Phase 3-1) ===
signal light_sensor_toggled(sensor_id: String, is_on: bool)
signal environment_combo_changed(combo_key: String, satisfied: bool)
signal hidden_revealed(stage_id: String, revealer_name: String)  # subscriber: Phase 5 UI 피드백

# === 상태 플래그 (Phase 3-1) ===
signal state_flag_changed(flag_id: String, value: bool)

# === 보스 시스템 (Phase 3-3) ===
## boss_spawned/intro_started/intro_finished는 1구역 보스(ancient_oakheart)에서 직접 호출 경로 사용.
## Phase 4-A(2~5구역 보스) 진입 시 BossSystem 도입과 함께 emit/connect 부활 예정.
signal boss_spawned(boss_id: String)  # subscriber: Phase 4-A 보스
signal boss_intro_started(boss_id: String)  # subscriber: Phase 4-A 보스
signal boss_intro_finished(boss_id: String)  # subscriber: Phase 4-A 보스
signal boss_phase_changed(boss_id: String, from_phase: int, to_phase: int)
signal boss_defeated(boss_id: String)
signal boss_arena_triggered(boss_id: String)  # subscriber: Phase 4-A 보스
signal boss_weak_point_exposed(boss_id: String, exposed: bool)

# === 능력 시스템 (Phase 3-3-d) ===
signal ability_unlocked(ability_id: String)  # subscriber: Phase 5 UI 알림

# === 대화 시스템 (Phase 3-4) ===
signal dialogue_started(npc_id: String)
signal dialogue_finished(npc_id: String)

# === 타이틀/게임 진입 (Phase 3-6) ===
signal game_start_requested(is_new_game: bool)

# === 일시정지 메뉴 (Phase 3-6) ===
signal game_paused  # subscriber: 외부 구독 예약 (PauseMenu 자체 처리)
signal game_resumed  # subscriber: 외부 구독 예약 (PauseMenu 자체 처리)
signal return_to_title_requested

# === 이펙트 시스템 (Phase 3-7 Pass 1 + Phase 4-0 #1 Step 6 부활) ===
## hit_flash/hitstop/screen_flash 3종은 Phase 4-0 #1 Step 6에서 부활.
## damage_resolver emit, EffectsSystem connect.
signal hit_flash_requested(target: CanvasItem, color: Color, duration: float)
signal screen_shake_requested(trauma: float)
signal hitstop_requested(duration: float, scale: float)
signal screen_flash_requested(color: Color, duration: float)

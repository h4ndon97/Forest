## 시스템 간 통신을 위한 이벤트 버스.
## 모든 시스템 간 시그널은 여기에 정의한다.
## 시스템이 직접 서로를 참조하지 않고, EventBus를 통해 통신한다.
extends Node

# === 시간 시스템 ===
signal time_set_requested(hour: float)
signal time_state_changed(old_state: int, new_state: int)
signal current_hour_changed(hour: float)
signal sun_state_updated(sun_angle: float, is_day: bool)
signal time_manipulated(from_hour: float, to_hour: float)
signal time_flow_started(current_hour: float)
signal time_flow_stopped(current_hour: float)
signal day_night_changed(is_day: bool)

# === 그림자 시스템 ===
signal shadow_params_changed(direction: Vector2, scale: float, intensity: float)
signal shadow_scale_changed(object_id: int, scale: float)

# === 적 시스템 ===
signal enemy_spawned(enemy_id: int)
signal enemy_killed(enemy_id: int, enemy_name: String)
signal residue_left(position: Vector2, killed_during_day: bool)
signal residue_purified(position: Vector2)
signal residue_revival_requested(stage_id: String)
signal residue_revived(position: Vector2, enemy_type: String)

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
signal stage_transition_requested(target_stage_id: String, entry_direction: String)
signal stage_transition_started(from_stage: String, to_stage: String)
signal stage_transition_completed(stage_id: String)
signal stage_access_denied(stage_id: String, lock_type: int, reason: String)

# === 시간 전파 ===
signal flow_rate_changed(rate: float)
signal time_flow_paused
signal time_flow_resumed
signal time_hour_sync_requested(hour: float)
signal time_flow_resume_requested(hour: float, rate: float)

# === 전투 시스템 ===
signal combo_hit_landed(hit_number: int)
signal combo_finished(attribute: String)
signal combo_resetted
signal damage_dealt(target_id: int, amount: float)
signal damage_received(amount: float)
signal health_changed(current_hp: float, max_hp: float)
signal player_died
signal player_respawned(position: Vector2)

# === 성장 시스템 ===
signal points_earned(amount: int, source: String)
signal skill_unlocked(skill_id: String)
signal growth_stats_changed()
signal growth_points_changed(growth_available: int, property_available: int)
signal growth_invested(category: String, total_invested: int)
signal growth_respec_completed()
signal hybrid_unlocked()

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
signal skill_cooldown_started(slot_index: int, duration: float)
signal skill_cooldown_finished(slot_index: int)
signal finish_attribute_changed(attribute: String)

# === 시간 자원 ===
signal time_resource_changed(current: float, max_val: float)
signal time_resource_depleted
signal time_resource_consume_flat_requested(amount: float)

# === 인벤토리/장비 시스템 ===
signal item_acquired(item_id: String)
signal item_removed(item_id: String)
## slot_type: 0=weapon, 1=armor, 2~4=accessory. item_id="" = 해제
signal equipment_changed(slot_type: int, item_id: String)
signal equipment_stats_changed()
signal consumable_used(consumable_type: int, amount: float)
signal consumable_count_changed(item_id: String, current: int, max_val: int)
signal consumables_refilled()

# === 상점 시스템 ===
signal shop_opened(shop_id: String)
signal shop_closed
signal shop_purchase_completed(item_id: String)

# === 인벤토리 UI ===
signal inventory_opened
signal inventory_closed

# === 아이템 드롭 ===
signal enemy_drop_requested(position: Vector2, enemy_name: String)

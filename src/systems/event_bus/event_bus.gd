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

# === 땅거미 시스템 ===
signal dusk_spider_approached(distance: int)
signal dusk_spider_arrived(stage_id: String)

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
signal time_flow_paused()
signal time_flow_resumed()
signal time_hour_sync_requested(hour: float)
signal time_flow_resume_requested(hour: float, rate: float)

# === 전투 시스템 ===
signal combo_hit_landed(hit_number: int)
signal combo_finished(attribute: String)
signal combo_resetted()
signal damage_dealt(target_id: int, amount: float)
signal damage_received(amount: float)
signal health_changed(current_hp: float, max_hp: float)
signal player_died()
signal player_respawned(position: Vector2)

# === 성장 시스템 ===
signal points_earned(amount: int, source: String)
signal skill_unlocked(skill_id: String)

# === 등불 시스템 ===
signal lantern_toggled(is_on: bool, lantern_position: Vector2)

# === 시간 자원 ===
signal time_resource_changed(current: float, max_val: float)
signal time_resource_depleted()

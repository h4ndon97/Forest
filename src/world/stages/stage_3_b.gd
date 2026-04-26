extends Node2D

## 3-B '옛 왕좌의 뜰' — 3구역 보스 아레나.
## 17시 황혼, 잠금 없음 (3-1~3-9 fully cleared 시 진입), 보스 1체 + 렌즈 2.
## 보스는 BossArenaTrigger 진입 시 활성화 (그 전까지 DORMANT).
## 패턴은 stage_2_b.gd 답습.

const STAGE_ID := "stage_3_b"
const SPAWN_POSITION := Vector2(80, 320)
const ARENA_WIDTH := 960
const BG_PATH := "res://assets/backgrounds/bg_stage_3_b.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_zone3.png"

var _trigger_consumed: bool = false


func _ready() -> void:
	EventBus.stage_entered.emit(STAGE_ID)
	EventBus.spawn_point_set.emit(SPAWN_POSITION)
	StageCamera.apply(STAGE_ID)
	_setup_boss()
	_setup_arena_trigger()
	_try_apply_background()
	_try_apply_ground()


func _setup_boss() -> void:
	var boss := get_node_or_null("Boss")
	if boss and boss.has_method("deactivate"):
		boss.deactivate()


func _setup_arena_trigger() -> void:
	var trigger := get_node_or_null("BossArenaTrigger") as Area2D
	if not trigger:
		return
	trigger.body_entered.connect(_on_arena_trigger_entered)


func _on_arena_trigger_entered(body: Node2D) -> void:
	if _trigger_consumed:
		return
	if not body.is_in_group("player"):
		return
	_trigger_consumed = true
	var boss := get_node_or_null("Boss")
	if boss != null:
		EnemySystem.on_boss_arena_entered(boss)
	var trigger := get_node_or_null("BossArenaTrigger") as Area2D
	if trigger:
		trigger.set_deferred("monitoring", false)
	var visual := get_node_or_null("BossArenaTrigger/TriggerVisual") as CanvasItem
	if visual:
		visual.visible = false
	var boss_id := ""
	if boss and boss.boss_data:
		boss_id = boss.boss_data.boss_id
	EventBus.boss_arena_triggered.emit(boss_id)


func _try_apply_background() -> void:
	if not ResourceLoader.exists(BG_PATH):
		return
	var tex: Texture2D = load(BG_PATH)
	if not tex:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.z_index = -10
	sprite.centered = false
	add_child(sprite)
	$BG.visible = false


func _try_apply_ground() -> void:
	if not ResourceLoader.exists(GROUND_TILE_PATH):
		return
	var tex: Texture2D = load(GROUND_TILE_PATH)
	if not tex:
		return
	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_TILE
	tex_rect.size = Vector2(ARENA_WIDTH, 64)
	tex_rect.position = Vector2(0, 328)
	add_child(tex_rect)
	$Floor/FloorSprite.visible = false

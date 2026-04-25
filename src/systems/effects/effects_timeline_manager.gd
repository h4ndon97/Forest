class_name EffectsTimelineManager
extends RefCounted

## EffectsSystem의 Layer 3(Effect Timeline) 책임 분리.
## .tres 자동 스캔, MAX_CONCURRENT_TIMELINES 상한 enforce,
## EffectsTimelinePlayer 인스턴스 생성·소멸 관리를 담당한다.
## host(EffectsSystem)는 add_child 부모로만 사용된다.

const TimelinePlayerScript = preload("res://src/systems/effects/effects_timeline_player.gd")
const TimelineRegistryScript = preload("res://src/systems/effects/effects_timeline_registry.gd")

## 동시 재생 timeline 상한. 초과 호출 시 가장 오래된 Player를 cancel.
const MAX_CONCURRENT_TIMELINES := 8

var _host: Node
var _registry: EffectsTimelineRegistry
var _active_players: Array[EffectsTimelinePlayer] = []


func _init(host: Node) -> void:
	_host = host
	_registry = TimelineRegistryScript.new()
	_registry.load_all()


## timeline 리소스를 재생하고 Player 핸들을 반환한다.
func request(timeline: EffectTimeline, ctx: Dictionary = {}) -> EffectsTimelinePlayer:
	if timeline == null:
		push_warning("EffectsTimelineManager.request: timeline is null")
		return null
	_enforce_limit()
	var player: EffectsTimelinePlayer = TimelinePlayerScript.new()
	player.name = "TimelinePlayer_%s" % timeline.display_name
	player.setup(timeline, ctx)
	_host.add_child(player)
	_active_players.append(player)
	player.tree_exited.connect(_active_players.erase.bind(player))
	return player


## Registry 조회로 timeline을 재생한다. id는 .tres 파일 basename (StringName).
func request_by_id(timeline_id: StringName, ctx: Dictionary = {}) -> EffectsTimelinePlayer:
	if _registry == null:
		return null
	var timeline: EffectTimeline = _registry.get_timeline(timeline_id)
	if timeline == null:
		push_warning("EffectsTimelineManager.request_by_id: '%s' not registered" % timeline_id)
		return null
	return request(timeline, ctx)


## 재생 중 timeline을 취소. 이미 발화한 cue는 되돌릴 수 없다(Layer 2 위임 완료).
func cancel(handle: EffectsTimelinePlayer) -> void:
	if handle == null or not is_instance_valid(handle):
		return
	handle.cancel()


func _enforce_limit() -> void:
	while _active_players.size() >= MAX_CONCURRENT_TIMELINES:
		var oldest: EffectsTimelinePlayer = _active_players[0]
		_active_players.remove_at(0)
		if is_instance_valid(oldest):
			oldest.cancel()

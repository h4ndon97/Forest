extends Node

## 영구 상태 플래그 저장소 (Autoload: StateFlags).
## 씬 전환/세이브 간 지속되는 boolean 플래그. 월드 영구 이벤트 추적.
## 파일 I/O는 하지 않음 — 직렬화는 SaveManager.collect_data/apply_data 경유.

signal flag_set(flag_id: String)
signal flag_cleared(flag_id: String)

var _flags: Dictionary = {}


## 플래그를 설정한다. value=false면 clear_flag와 동일.
func set_flag(flag_id: String, value: bool = true) -> void:
	if not value:
		clear_flag(flag_id)
		return
	if _flags.get(flag_id, false):
		return
	_flags[flag_id] = true
	flag_set.emit(flag_id)
	EventBus.state_flag_changed.emit(flag_id, true)


## 플래그가 true로 설정되어 있는지 반환한다.
func has_flag(flag_id: String) -> bool:
	return _flags.get(flag_id, false)


## has_flag의 alias (명료성 위함).
func get_flag(flag_id: String) -> bool:
	return has_flag(flag_id)


## 플래그를 제거한다.
func clear_flag(flag_id: String) -> void:
	if not _flags.get(flag_id, false):
		return
	_flags.erase(flag_id)
	flag_cleared.emit(flag_id)
	EventBus.state_flag_changed.emit(flag_id, false)


## 전체 플래그 복사본을 반환한다 (디버그/세이브용).
func get_all_flags() -> Dictionary:
	return _flags.duplicate()


## SaveManager 직렬화용.
func get_save_data() -> Dictionary:
	return _flags.duplicate()


## SaveManager 복원용. 기존 플래그는 전부 교체된다 (시그널 없이 조용히 로드).
func load_save_data(data: Dictionary) -> void:
	_flags.clear()
	for key in data:
		if bool(data[key]):
			_flags[str(key)] = true

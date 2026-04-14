extends Node

## 세이브/로드를 담당하는 StageSystem 자식 컴포넌트.
## 거점 진입 시 게임 상태를 JSON으로 직렬화하여 디스크에 저장한다.
## 게임 시작 시 저장 파일이 있으면 상태를 복원한다.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1


## 게임 상태를 디스크에 저장한다.
func save_game(data: Dictionary) -> void:
	data["version"] = SAVE_VERSION
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("SaveManager: 세이브 파일 쓰기 실패: " + SAVE_PATH)
		return
	file.store_string(json_string)
	file.close()


## 디스크에서 세이브 데이터를 읽어 반환한다. 실패 시 빈 딕셔너리.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("SaveManager: 세이브 파일 읽기 실패: " + SAVE_PATH)
		return {}
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_warning("SaveManager: JSON 파싱 실패: " + json.get_error_message())
		return {}

	var result = json.data
	if not result is Dictionary:
		push_warning("SaveManager: 세이브 데이터가 Dictionary가 아님")
		return {}

	return result


## 세이브 파일 존재 여부를 반환한다.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 세이브 파일을 삭제한다.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

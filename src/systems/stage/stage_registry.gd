extends Node

## 등록된 스테이지 데이터를 관리한다.
## StageSystem의 자식으로 동작하며, StageData 로드/조회를 처리한다.

var _stages: Dictionary = {}  # stage_id -> StageData


## StageData를 레지스트리에 등록한다.
func register(data: StageData) -> void:
	if data.stage_id.is_empty():
		push_warning("StageRegistry: stage_id가 비어있는 StageData 등록 시도 무시")
		return
	_stages[data.stage_id] = data


## stage_id로 StageData를 조회한다.
func get_stage(stage_id: String) -> StageData:
	return _stages.get(stage_id) as StageData


## 등록된 모든 stage_id를 반환한다.
func get_all_stage_ids() -> Array:
	return _stages.keys()


## stage_id가 등록되어 있는지 확인한다.
func has_stage(stage_id: String) -> bool:
	return _stages.has(stage_id)


## 등록된 스테이지 수를 반환한다.
func get_count() -> int:
	return _stages.size()

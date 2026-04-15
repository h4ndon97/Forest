extends Node

## 땅거미 맵 이동 경로 탐색 컴포넌트.
## StageSystem의 public API를 통해 스테이지 그래프를 읽고
## BFS로 최단 경로 및 거리를 계산한다.


## 두 스테이지 사이의 최단 거리(홉 수)를 반환한다.
## 도달 불가능하면 -1을 반환한다.
func get_distance(from_id: String, to_id: String) -> int:
	if from_id == to_id:
		return 0
	var path: Array = find_path(from_id, to_id)
	if path.is_empty():
		return -1
	return path.size() - 1


## BFS로 from_id에서 to_id까지의 최단 경로를 반환한다.
## 반환값: [from_id, ..., to_id] 형태의 stage_id 배열. 도달 불가 시 빈 배열.
func find_path(from_id: String, to_id: String) -> Array:
	if from_id == to_id:
		return [from_id]

	var visited: Dictionary = {from_id: ""}
	var queue: Array = [from_id]

	while not queue.is_empty():
		var current: String = queue.pop_front()
		var data: StageData = StageSystem.get_stage_data(current)
		if not data:
			continue
		for adj_id in data.adjacent_stages:
			if visited.has(adj_id):
				continue
			visited[adj_id] = current
			if adj_id == to_id:
				return _reconstruct_path(visited, from_id, to_id)
			queue.append(adj_id)

	return []


## 특정 스테이지에서 정확히 target_distance만큼 떨어진 스테이지 목록을 반환한다.
## 스폰 위치 결정에 사용한다.
func get_stages_at_distance(origin_id: String, target_distance: int) -> Array:
	if target_distance == 0:
		return [origin_id]

	var visited: Dictionary = {origin_id: 0}
	var queue: Array = [origin_id]
	var result: Array = []

	while not queue.is_empty():
		var current: String = queue.pop_front()
		var current_dist: int = visited[current]
		if current_dist >= target_distance:
			continue
		var data: StageData = StageSystem.get_stage_data(current)
		if not data:
			continue
		for adj_id in data.adjacent_stages:
			if visited.has(adj_id):
				continue
			var new_dist: int = current_dist + 1
			visited[adj_id] = new_dist
			if new_dist == target_distance:
				result.append(adj_id)
			elif new_dist < target_distance:
				queue.append(adj_id)

	return result


## 경로에서 다음 이동할 스테이지 ID를 반환한다.
## current_id에서 target_id 방향으로 한 칸 이동.
func get_next_step(current_id: String, target_id: String) -> String:
	var path: Array = find_path(current_id, target_id)
	if path.size() < 2:
		return ""
	return path[1]


# --- 내부 ---


func _reconstruct_path(visited: Dictionary, from_id: String, to_id: String) -> Array:
	var path: Array = []
	var current: String = to_id
	while current != "":
		path.push_front(current)
		current = visited.get(current, "")
		if current == from_id:
			path.push_front(from_id)
			break
	return path

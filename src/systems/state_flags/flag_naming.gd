class_name StateFlagNames
extends RefCounted

## 상태 플래그 네이밍 상수.
## 형식: "<domain>.<scope>.<name>"
## 타이포 방지를 위해 자주 참조되는 플래그를 여기 상수로 정의한다.

## 1-H 숨겨진 등불대 포탈 발견 (1-4 렌즈 빛 집중으로 활성화).
const HIDDEN_1H_DISCOVERED := "hidden_revealer.stage_1_4.portal_1h_revealed"

## HiddenRevealer가 자동 기록하는 플래그 ID를 반환한다.
## 형식: "hidden_revealer.<stage_id>.<node_name>"
static func hidden_revealer_flag(stage_id: String, node_name: String) -> String:
	var sid: String = stage_id if not stage_id.is_empty() else "unknown"
	return "hidden_revealer.%s.%s" % [sid, node_name]

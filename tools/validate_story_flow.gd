extends SceneTree
## 验证小游戏剧情模式与 Minigames 桥接层：
## - 每个小游戏都能以剧情模式打开、完成、发出结果
## - 结果写入 Dialogic 变量 minigame_* 
## - 重试成功按半额结算
## - 结束后桥接层的 CanvasLayer 被清理

const EXPECTED_REWARDS := {
	"reading": 15.0,
	"pairing": 10.0,
	"envelope": 10.0,
	"counting": 10.0,
	"route": 5.0,
	"relief": 10.0,
	"forgery": 10.0,
	"restoration": 0.0,
}

var bridge
var dialogic
var current_id := ""
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	bridge = root.get_node("Minigames")
	dialogic = root.get_node("Dialogic")
	bridge.minigame_opened.connect(_on_opened)

	for game_id in EXPECTED_REWARDS:
		current_id = game_id
		await bridge.run(game_id)
		_check_result(game_id, EXPECTED_REWARDS[game_id], false)

	current_id = "retry"
	await bridge.run("reading")
	_check_result("retry", 7.5, true)

	_check_timelines()
	await _check_story_timeline()
	print("Story minigame flow: ", "passed" if failures == 0 else str(failures) + " failed")
	quit(1 if failures else 0)


func _check_timelines() -> void:
	var found := {}
	var remaining_todos := 0
	var regex := RegEx.create_from_string("do Minigames\\.run\\(\"([a-z_]+)\"\\)")
	for file in DirAccess.get_files_at("res://Timelines"):
		if not file.ends_with(".dtl"):
			continue
		var text := FileAccess.get_file_as_string("res://Timelines/" + file)
		if text.contains("TODO mini-game"):
			remaining_todos += 1
		for match in regex.search_all(text):
			var game_id := match.get_string(1)
			found[game_id] = int(found.get(game_id, 0)) + 1

	for game_id in EXPECTED_REWARDS:
		if int(found.get(game_id, 0)) != 1:
			_fail("timeline should call Minigames.run(\"" + game_id + "\") exactly once")
	if remaining_todos > 0:
		_fail(str(remaining_todos) + " timelines still contain TODO mini-game placeholders")


func _check_story_timeline() -> void:
	# End-to-end: a real Dialogic timeline awaits the bridge, then applies the reward.
	current_id = "timeline"
	var timeline := DialogicTimeline.new()
	timeline.from_text("set {shunbo_trust} = 0\ndo Minigames.run(\"reading\")\nif {minigame_reward} > 0:\n\tset {shunbo_trust} += {minigame_reward}\n")
	dialogic.start_timeline(timeline)
	await create_timer(1.0).timeout
	var value: float = float(dialogic.VAR.get_variable("shunbo_trust"))
	var reward: float = float(dialogic.VAR.get_variable("minigame_reward"))
	if not is_equal_approx(reward, 15.0):
		_fail("story timeline did not receive the bridge reward")
	if not is_equal_approx(value, 15.0):
		_fail("story timeline variable expression produced " + str(value) + ", expected 15.0")
	dialogic.VAR.set_variable("shunbo_trust", 0)


func _on_opened(game: Control) -> void:
	match current_id:
		"pairing":
			game.call("_select_source", 0)
			game.get("option_buttons")[0][1].pressed.emit()
			game.call("_select_source", 1)
			game.get("option_buttons")[1][0].pressed.emit()
			game.get("submit_button").pressed.emit()
		"route":
			game.get("route_buttons")[2].pressed.emit()
		"retry":
			var quiz_data: Dictionary = game.get("game")
			var correct := int(quiz_data.correct)
			game.get("option_buttons")[(correct + 1) % 3].pressed.emit()
			game.get("retry_button").pressed.emit()
			game.get("option_buttons")[correct].pressed.emit()
		_:
			var quiz_data: Dictionary = game.get("game")
			game.get("option_buttons")[int(quiz_data.correct)].pressed.emit()

	if game.get("back_button").visible:
		_fail(current_id + " still shows the back button in story mode")
	if not game.get("continue_button").visible:
		_fail(current_id + " did not offer a continue button after completion")
	game.get("continue_button").pressed.emit()


func _check_result(game_id: String, expected_reward: float, expect_retried: bool) -> void:
	var success: bool = bool(dialogic.VAR.get_variable("minigame_success"))
	var retried: bool = bool(dialogic.VAR.get_variable("minigame_retried"))
	var reward: float = float(dialogic.VAR.get_variable("minigame_reward"))
	var choice: int = int(dialogic.VAR.get_variable("minigame_choice"))
	if not success:
		_fail(game_id + " did not report success")
	if retried != expect_retried:
		_fail(game_id + " retried flag is wrong")
	if not is_equal_approx(reward, expected_reward):
		_fail(game_id + " reward is " + str(reward) + ", expected " + str(expected_reward))
	if game_id == "route" and choice != 2:
		_fail("route choice is " + str(choice) + ", expected 2")
	if game_id != "route" and choice != -1:
		_fail(game_id + " should not set a route choice")
	if bridge.is_running():
		_fail(game_id + " left the bridge running")
	if bridge.get_child_count() != 0:
		_fail(game_id + " left the minigame layer in the tree")
	print(game_id, ": reward=", reward, " retried=", retried, " choice=", choice)


func _fail(message: String) -> void:
	failures += 1
	printerr("ERROR: ", message)

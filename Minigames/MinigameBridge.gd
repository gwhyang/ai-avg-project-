extends Node
## 主线与独立小游戏之间的桥接层。
##
## Timeline 里用：
##     do Minigames.run("reading")
## 调用。Dialogic 的 call 事件会 await 这个方法，因此剧情会停在这里，
## 直到玩家在小游戏里完成并按下“继续剧情/确认路线”。
##
## 结果写入以下 Dialogic 变量，由 Timeline 负责具体加到哪个数值变量：
##   minigame_success  bool
##   minigame_retried  bool
##   minigame_reward   float（重试成功时是小游戏显示的半额，如 7.5）
##   minigame_choice   int（路线小游戏选中 0/1/2，其余为 -1）

signal minigame_opened(game: Control)

const QUIZ_SCENE := "res://Minigames/Quiz.tscn"
const PAIRING_SCENE := "res://Minigames/Pairing.tscn"
const ROUTE_SCENE := "res://Minigames/Route.tscn"

var _running := false


func is_running() -> bool:
	return _running


func run(game_id: String) -> void:
	if _running:
		push_error("[Minigames] A minigame is already running.")
		return

	_running = true
	var layer := CanvasLayer.new()
	layer.name = "StoryMinigameLayer"
	layer.layer = 50
	add_child(layer)

	var game: Control = _instantiate(game_id)
	if game == null:
		layer.queue_free()
		_running = false
		return

	if game.has_method("configure"):
		game.configure(game_id)
	layer.add_child(game)
	if game.has_method("set_story_mode"):
		game.set_story_mode(true)

	var outcome := {"done": false, "result": {}}
	game.story_finished.connect(func(result: Dictionary) -> void:
		outcome.result = result
		outcome.done = true
	)

	minigame_opened.emit(game)
	while not outcome.done:
		await get_tree().process_frame
	_apply_result(outcome.result)

	layer.queue_free()
	await get_tree().process_frame
	_running = false


func _instantiate(game_id: String) -> Control:
	var scene_path := QUIZ_SCENE
	if game_id == "pairing":
		scene_path = PAIRING_SCENE
	elif game_id == "route":
		scene_path = ROUTE_SCENE

	if not ResourceLoader.exists(scene_path):
		push_error("[Minigames] Unknown minigame scene for id: " + game_id)
		return null
	return (load(scene_path) as PackedScene).instantiate() as Control


func _apply_result(result: Dictionary) -> void:
	Dialogic.VAR.set_variable("minigame_success", bool(result.get("success", false)))
	Dialogic.VAR.set_variable("minigame_retried", bool(result.get("retried", false)))
	Dialogic.VAR.set_variable("minigame_reward", float(result.get("reward", 0.0)))
	Dialogic.VAR.set_variable("minigame_choice", int(result.get("choice", -1)))

extends SceneTree

const QUIZ_DATA = preload("res://Minigames/QuizData.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for game_id in QUIZ_DATA.GAMES:
		await _check_quiz(game_id)
	await _check_pairing()
	await _check_route()
	await _check_hub()
	print("Minigame prototype checks: ", "passed" if failures == 0 else str(failures) + " failed")
	quit(1 if failures else 0)


func _check_quiz(game_id: String) -> void:
	var game: Dictionary = QUIZ_DATA.GAMES[game_id]
	var quiz: Control = load("res://Minigames/Quiz.tscn").instantiate()
	quiz.call("configure", game_id)
	root.add_child(quiz)
	await process_frame
	for node_name in ["DocumentPanel", "OptionA", "OptionB", "OptionC", "Feedback", "Retry", "Restart"]:
		if quiz.find_child(node_name, true, false) == null:
			_fail(game_id + " UI is missing scene node " + node_name)
	var options: Array = quiz.get("option_buttons")
	var feedback: Label = quiz.get("feedback_label")
	var retry: Button = quiz.get("retry_button")
	var restart: Button = quiz.get("restart_button")
	if options.size() != 3:
		_fail(game_id + " has no answer choices")
		quiz.queue_free()
		await process_frame
		return

	var wrong_index: int = (int(game.correct) + 1) % options.size()
	options[wrong_index].pressed.emit()
	if not retry.visible or feedback.text.is_empty():
		_fail(game_id + " did not show a retry after a wrong answer")
	retry.pressed.emit()
	if retry.visible or options[0].disabled:
		_fail(game_id + " did not restore the choices for retry")
	options[int(game.correct)].pressed.emit()
	if not quiz.get("complete") or not restart.visible:
		_fail(game_id + " did not complete on the correct answer")
	if float(game.reward) > 0.0 and not feedback.text.contains("+" + _format_reward(float(game.reward) * 0.5)):
		_fail(game_id + " did not preview half reward after retry")
	restart.pressed.emit()
	if quiz.get("complete") or quiz.get("had_wrong_answer") or options[0].disabled:
		_fail(game_id + " did not reset for replay")
	options[int(game.correct)].pressed.emit()
	if float(game.reward) > 0.0 and not feedback.text.contains("+" + _format_reward(float(game.reward))):
		_fail(game_id + " did not preview full reward on first try")
	quiz.queue_free()
	await process_frame


func _check_pairing() -> void:
	var pairing: Control = load("res://Minigames/Pairing.tscn").instantiate()
	root.add_child(pairing)
	await process_frame
	for node_name in ["Grid1", "Grid2", "Phrase1", "Phrase2", "A1A", "A2C", "Submit", "Status"]:
		if pairing.find_child(node_name, true, false) == null:
			_fail("Pairing UI is missing scene node " + node_name)
	var sources: Array = pairing.get("source_buttons")
	var choices: Array = pairing.get("option_buttons")
	var submit: Button = pairing.get("submit_button")
	sources[0].pressed.emit()
	choices[0][0].pressed.emit()
	sources[1].pressed.emit()
	choices[1][0].pressed.emit()
	submit.pressed.emit()
	var selected: Array = pairing.get("chosen")
	if not pairing.get("had_error") or selected[0] != -1 or selected[1] != 0:
		_fail("Pairing did not clear only the wrong link")
	sources[0].pressed.emit()
	choices[0][1].pressed.emit()
	submit.pressed.emit()
	if not pairing.get("completed") or not pairing.get("status_label").text.contains("+5"):
		_fail("Pairing did not award half after retry")
	pairing.call("_on_replay_pressed")
	if pairing.get("completed") or pairing.get("had_error"):
		_fail("Pairing did not reset for replay")
	pairing.queue_free()
	await process_frame


func _check_route() -> void:
	var route: Control = load("res://Minigames/Route.tscn").instantiate()
	root.add_child(route)
	await process_frame
	for node_name in ["RouteGrid", "ResultPanel", "ResultHeading", "Back", "Replay"]:
		if route.find_child(node_name, true, false) == null:
			_fail("Route UI is missing scene node " + node_name)
	var choices: Array = route.get("route_buttons")
	for index in range(3):
		choices[index].pressed.emit()
		if route.get("selected_route") != index:
			_fail("Route " + str(index + 1) + " could not be selected")
		if index == 2 and route.get("result_reward").text != "顺伯信任 +5":
			_fail("Water route did not preview the scripted reward")
		if index != 2 and not route.get("result_reward").text.is_empty():
			_fail("An unscored route previewed a reward")
	route.call("_on_replay_pressed")
	if route.get("selected_route") != -1:
		_fail("Route did not reset for replay")
	route.queue_free()
	await process_frame


func _check_hub() -> void:
	var hub: Control = load("res://Minigames/PrototypeHub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	for node_name in ["Menu", "Grid", "QuitButton"]:
		if hub.find_child(node_name, true, false) == null:
			_fail("Hub UI is missing scene node " + node_name)
	var grid: GridContainer = hub.get("grid")
	if grid.get_child_count() != 8:
		_fail("Hub does not list all eight games")
	for index in range(grid.get_child_count()):
		var card: Button = grid.get_child(index)
		card.pressed.emit()
		await process_frame
		var active_game: Control = hub.get("active_game")
		if active_game == null:
			_fail("Hub card " + str(index + 1) + " did not open a game")
			continue
		active_game.emit_signal("exit_requested")
		await process_frame
		if hub.get("active_game") != null or not hub.get("menu").visible:
			_fail("Hub card " + str(index + 1) + " did not return to gallery")
	hub.queue_free()
	await process_frame


func _format_reward(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)


func _fail(message: String) -> void:
	failures += 1
	printerr("ERROR: ", message)

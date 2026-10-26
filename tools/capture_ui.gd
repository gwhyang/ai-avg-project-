extends SceneTree
## Dev-only helper: renders the main menu, the dialogue box and the choice
## buttons to PNG files under user:// so the art setup can be reviewed quickly.
##
## Usage:
##   godot --path . --script res://tools/capture_ui.gd
##
## It needs a real rendering driver (do not pass --headless).

var main: Control


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	main = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	await _wait(0.4)
	await _save("ui_menu")

	main.get_node("%StartButton").pressed.emit()
	await _wait(1.0)
	var dialogic: Node = root.get_node("Dialogic")
	dialogic.Inputs.handle_input()
	await _wait(0.4)
	await _save("ui_dialogue")
	_report()

	for i in range(9):
		dialogic.Inputs.handle_input()
		await _wait(0.25)
	await _wait(0.8)
	await _save("ui_speaker")
	_report()

	for i in range(60):
		dialogic.Inputs.handle_input()
		await _wait(0.12)
		var buttons := _choice_buttons()
		if not buttons.is_empty():
			await _wait(0.4)
			print("choices visible: ", buttons.size())
			await _save("ui_choices")
			break

	dialogic.call("end_timeline", true)
	await _wait(0.4)
	main.queue_free()
	await process_frame
	var hub: Control = load("res://Minigames/PrototypeHub.tscn").instantiate()
	root.add_child(hub)
	await _wait(0.6)
	await _save("ui_hub")

	var screens := {0: "ui_quiz", 1: "ui_pairing", 4: "ui_route"}
	for card_index in screens:
		var card: Button = hub.grid.get_child(card_index)
		card.pressed.emit()
		await _wait(0.8)
		await _save(screens[card_index])
		var game: Control = hub.active_game
		if game:
			if card_index == 0:
				game.get("option_buttons")[2].pressed.emit()
				await _wait(0.4)
				await _save("ui_quiz_answer")
			elif card_index == 1:
				game.call("_select_source", 0)
				game.get("option_buttons")[0][0].pressed.emit()
				await _wait(0.4)
				await _save("ui_pairing_selected")
			elif card_index == 4:
				game.get("route_buttons")[2].pressed.emit()
				await _wait(0.4)
				await _save("ui_route_selected")
			game.emit_signal("exit_requested")
			await _wait(0.4)

	var bridge = root.get_node("Minigames")
	bridge.call_deferred("run", "reading")
	await _wait(0.8)
	await _save("ui_story_quiz")
	var layer: CanvasLayer = bridge.get_node_or_null("StoryMinigameLayer")
	if layer and layer.get_child_count() > 0:
		var game: Control = layer.get_child(0)
		var quiz_data: Dictionary = game.get("game")
		game.get("option_buttons")[int(quiz_data.correct)].pressed.emit()
		await _wait(0.4)
		await _save("ui_story_quiz_done")
		game.get("continue_button").pressed.emit()
	while bridge.is_running():
		await _wait(0.1)

	await _wait(0.2)
	quit()


func _choice_buttons() -> Array:
	var found := []
	for node in root.find_children("*", "DialogicNode_ChoiceButton", true, false):
		if node.is_visible_in_tree() and not node.text.is_empty():
			found.append(node)
	return found


func _report() -> void:
	var name_label: Label = root.find_child("DialogicNode_NameLabel", true, false)
	var dialog_text: RichTextLabel = root.find_child("DialogicNode_DialogText", true, false)
	var text_panel: PanelContainer = root.find_child("DialogTextPanel", true, false)
	var name_panel: PanelContainer = root.find_child("NameLabelPanel", true, false)
	if name_label and dialog_text:
		print("speaker='", name_label.text, "' chars=", dialog_text.text.length(),
			" visible_lines=", dialog_text.get_visible_line_count(),
			" size=", dialog_text.size)
	if text_panel and name_panel:
		print("window=", root.size, " viewport=", root.get_visible_rect().size)
		print("text panel rect=", text_panel.get_global_rect(),
			" name panel rect=", name_panel.get_global_rect(),
			" name label size=", name_label.size)
	var indicator: Control = root.find_child("NextIndicator", true, false)
	if indicator:
		print("next indicator visible=", indicator.is_visible_in_tree(),
			" rect=", indicator.get_global_rect())


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://" + name + ".png")
	var error := image.save_png(path)
	print("captured ", path, " (", error, ")")

extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var menu: Control = main.get_node("Menu")
	var start_button: Button = main.get_node("Menu/StartButton")
	var dialogic: Node = root.get_node("Dialogic")
	if not menu.visible or not start_button.has_focus():
		printerr("Main menu did not open ready for input")
		quit(1)
		return

	start_button.pressed.emit()
	for frame in range(5):
		await process_frame
	var current_timeline: DialogicTimeline = dialogic.get("current_timeline")
	if menu.visible or current_timeline == null or current_timeline.resource_path != "res://Timelines/timeline.dtl":
		printerr("Start button did not launch the opening timeline")
		quit(1)
		return

	await dialogic.call("end_timeline", true)
	await process_frame
	if not menu.visible or not start_button.has_focus():
		printerr("Main menu did not return after the timeline ended")
		quit(1)
		return

	print("Main scene start and return flow passed")
	quit()

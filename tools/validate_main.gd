extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var menu: Control = main.get_node("BoardArea")
	var start_button: Button = main.get_node("%StartButton")
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
	if not dialogic.Audio.is_channel_playing_file("res://Asset/music/【淡入】序章音乐.mp3", "music"):
		printerr("Opening timeline did not start its music")
		quit(1)
		return

	# Ending during a crossfade must release both players and their volume tweens.
	dialogic.Audio.update_audio("music", "res://Asset/music/【淡入】第一章音乐.mp3", {"fade_length": 1.5})
	await dialogic.call("end_timeline", true)
	for frame in range(3):
		await process_frame
	if not menu.visible or not start_button.has_focus():
		printerr("Main menu did not return after the timeline ended")
		quit(1)
		return
	if dialogic.Audio.is_any_channel_playing() or dialogic.Audio.audio_node.get_child_count() != 0:
		printerr("Story music continued after returning to the main menu")
		quit(1)
		return

	print("Main scene start and return flow passed")
	# Allow the audio server to release playback resources before process shutdown.
	await create_timer(0.1).timeout
	quit()

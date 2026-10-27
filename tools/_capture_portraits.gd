extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var main: Control = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var dialogic: Node = root.get_node("Dialogic")
	dialogic.start("chapter_2")
	await create_timer(1.5).timeout
	for i in range(8):
		dialogic.Inputs.handle_input()
		await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://portrait_check.png")
	image.save_png(path)
	print("captured ", path)
	dialogic.call("end_timeline", true)
	await create_timer(0.2).timeout
	quit()

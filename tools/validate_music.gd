extends SceneTree
## Exercise actual music cue blocks with Dialogic's parser, expressions and audio players.

const CUES := [
	["timeline", "start", "【淡入】序章音乐.mp3"],
	["chapter_1", "chapter_1", "【淡入】第一章音乐.mp3"],
	["chapter_2", "chapter_2", "【淡入】第二章音乐+《救国批》+《未竟》.mp3"],
	["chapter_3", "chapter_3", "【淡入】第三章音乐.mp3"],
	["chapter_3", "ambush_merge", "第三章（阿棠是否要给阿妹钱抉择）.mp3"],
	["chapter_4", "chapter_4", "【淡入】第四章音乐.mp3"],
	["chapter_5", "chapter_5", "【淡入】第五章音乐.mp3"],
	["ending_relief", "ending_relief", "【淡入】第二章音乐+《救国批》+《未竟》.mp3"],
	["ending_unfinished", "ending_unfinished", "【淡入】第二章音乐+《救国批》+《未竟》.mp3"],
	["ending_return", "ending_return", "《批归》《守信》《下南洋》+所有结局统一汇入.mp3"],
	["ending_steadfast", "ending_steadfast", "《批归》《守信》《下南洋》+所有结局统一汇入.mp3"],
	["ending_south", "ending_south", "《批归》《守信》《下南洋》+所有结局统一汇入.mp3"],
	["postwar", "ending_letter_pending", "《批归》《守信》《下南洋》+所有结局统一汇入.mp3"],
	["modern", "modern", "《批归》《守信》《下南洋》+所有结局统一汇入.mp3"],
]

var dialogic: Node
var checked := 0
var previous_path := ""
var previous_player: AudioStreamPlayer
var expected_volume := 0.0
var music_started := 0


func _initialize() -> void:
	call_deferred("_run")
	create_timer(15.0).timeout.connect(func() -> void:
		printerr("Music validation timed out")
		quit(1))


func _run() -> void:
	dialogic = root.get_node("Dialogic")
	dialogic.Audio.audio_started.connect(func(_info: Dictionary) -> void: music_started += 1)
	dialogic.signal_event.connect(_on_signal)
	var test_text := ""
	for index in range(CUES.size()):
		var cue: Array = CUES[index]
		var source := FileAccess.get_file_as_string("res://Timelines/" + cue[0] + ".dtl")
		var lines := source.replace("\r\n", "\n").split("\n")
		var label_index := lines.find("label " + cue[1])
		if label_index < 0:
			printerr("Missing cue label: ", cue)
			quit(1)
			return
		# Replay the source's real condition and audio event, including indentation.
		test_text += lines[label_index + 1] + "\n" + lines[label_index + 2] + "\n"
		test_text += "[signal arg=\"cue:" + str(index) + "\"]\n"
		test_text += "[wait time=\"0.06\" hide_text=\"false\"]\n"
	test_text += "[wait time=\"1.55\" hide_text=\"false\"]\n[signal arg=\"settled\"]\n"
	var ending := FileAccess.get_file_as_string("res://Timelines/modern.dtl").replace("\r\n", "\n").get_slice("label finish\n", 1)
	test_text += ending.get_slice("\n", 0) + "\n" + ending.get_slice("\n", 1) + "\n"
	test_text += "[signal arg=\"stopped\"]\n"
	var timeline := DialogicTimeline.new()
	timeline.from_text(test_text)
	dialogic.start(timeline)


func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr(message)
		quit(1)
	return ok


func _on_signal(argument: String) -> void:
	if argument.begins_with("cue:"):
		var index := argument.trim_prefix("cue:").to_int()
		var path := "res://Asset/music/" + str(CUES[index][2])
		if not _check(dialogic.Audio.is_channel_playing_file(path, "music"), "Wrong or missing music at " + str(CUES[index])):
			return
		var player: AudioStreamPlayer = dialogic.Audio.current_audio_channels["music"]
		if not _check(player.stream is AudioStreamMP3 and player.stream.loop, "Music did not loop"):
			return
		if previous_path == path:
			if not _check(player == previous_player, "Same music restarted across timelines"):
				return
		else:
			if not _check(player != previous_player and player.volume_db < -30.0, "Music switch did not begin fading in"):
				return
		var overrides: Dictionary = dialogic.Audio.info["music"].settings_overrides
		if not _check(is_equal_approx(overrides.fade_length, 1.5), "Missing 1.5-second transition"):
			return
		expected_volume = overrides.volume
		previous_path = path
		previous_player = player
		checked += 1
	elif argument == "settled":
		if not _check(checked == CUES.size() and music_started == 9, "Cue guard started music an unexpected number of times"):
			return
		if not _check(dialogic.Audio.audio_node.get_child_count() == 1 and is_equal_approx(previous_player.volume_db, expected_volume), "Old music players did not fade out and clean up"):
			return
		dialogic.Audio._pause()
		if not _check(previous_player.stream_paused, "Music ignored dialogue pause"):
			return
		dialogic.Audio._resume()
	elif argument == "stopped":
		if not _check(not dialogic.Audio.is_any_channel_playing(), "Ending did not fade music to silence"):
			return
		print("Music passed: 8 files, 14 cues, continuous shared tracks, crossfades, loop, pause, ending fade")
		await dialogic.end_timeline(true)
		# Allow the audio server to release playback resources before process shutdown.
		await create_timer(0.1).timeout
		quit(0)

extends SceneTree

var character_loader := DialogicCharacterFormatLoader.new()
var timeline_loader := DialogicTimelineFormatLoader.new()
var errors := 0


func _initialize() -> void:
	ResourceLoader.add_resource_format_loader(character_loader, true)
	ResourceLoader.add_resource_format_loader(timeline_loader, true)
	validate_resources()
	quit(1 if errors else 0)


func fail(message: String) -> void:
	errors += 1
	printerr("ERROR: ", message)


func validate_registry(directory: Dictionary, extension: String) -> void:
	var registered_paths := {}
	for identifier in directory:
		var path: String = str(directory[identifier])
		if not path.begins_with("res://") or path.get_extension() != extension:
			fail("Invalid ." + extension + " registration: " + str(identifier) + " -> " + path)
		elif registered_paths.has(path):
			fail("Duplicate ." + extension + " registration: " + path)
		else:
			registered_paths[path] = true
		if not FileAccess.file_exists(path):
			fail("Registered ." + extension + " file is missing: " + path)

	for path in DialogicResourceUtil.list_resources_of_type("." + extension):
		if not registered_paths.has(path):
			fail("Unregistered ." + extension + " file: " + path)


func validate_characters(directory: Dictionary) -> Dictionary:
	var loaded := {}
	var portrait_count := 0
	var identifiers: Array = directory.keys()
	identifiers.sort()
	for identifier in identifiers:
		var path: String = str(directory[identifier])
		var character := ResourceLoader.load(path) as DialogicCharacter
		if character == null:
			fail("Cannot load character " + str(identifier) + " at " + path)
			continue
		loaded[identifier] = character
		if character.default_portrait and not character.portraits.has(character.default_portrait):
			fail(str(identifier) + " has a missing default portrait: " + character.default_portrait)
		for portrait_name in character.portraits:
			portrait_count += 1
			var info: Dictionary = character.portraits[portrait_name]
			var image: String = str(info.get("export_overrides", {}).get("image", ""))
			image = image.trim_prefix('"').trim_suffix('"')
			if image and not FileAccess.file_exists(image):
				fail(str(identifier) + "/" + str(portrait_name) + " missing image: " + image)
			var scene: String = str(info.get("scene", ""))
			if scene.begins_with("res://") and not FileAccess.file_exists(scene):
				fail(str(identifier) + "/" + str(portrait_name) + " missing scene: " + scene)
	print("Characters: ", loaded.size(), " files, ", portrait_count, " portraits")
	return loaded


func check_character(identifier: String, portrait: String, characters: Dictionary, context: String) -> void:
	if identifier.is_empty() or not characters.has(identifier):
		fail(context + " references unknown character: " + (identifier if identifier else "<empty>"))
	elif portrait and not characters[identifier].portraits.has(portrait):
		fail(context + " references unknown portrait: " + identifier + "/" + portrait)


func validate_resources() -> void:
	var character_directory: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	var timeline_directory: Dictionary = ProjectSettings.get_setting("dialogic/directories/dtl_directory", {})
	validate_registry(character_directory, "dch")
	validate_registry(timeline_directory, "dtl")
	var characters := validate_characters(character_directory)

	var timelines := {}
	var labels := {}
	var identifiers: Array = timeline_directory.keys()
	identifiers.sort()
	for identifier in identifiers:
		var path: String = str(timeline_directory[identifier])
		var timeline := ResourceLoader.load(path) as DialogicTimeline
		if timeline == null:
			fail("Cannot load timeline " + str(identifier) + " at " + path)
			continue
		timeline.process()
		timelines[identifier] = timeline
		labels[identifier] = {}
		for event in timeline.events:
			if event is DialogicLabelEvent:
				if labels[identifier].has(event.name):
					fail(str(identifier) + " has duplicate label: " + event.name)
				labels[identifier][event.name] = true

	var total_events := 0
	var total_text := 0
	var total_labels := 0
	var total_jumps := 0
	for identifier in identifiers:
		if not timelines.has(identifier):
			continue
		var timeline: DialogicTimeline = timelines[identifier]
		var event_count := 0
		var text_count := 0
		var jump_count := 0
		for index in range(timeline.events.size()):
			var event: DialogicEvent = timeline.events[index]
			if event is DialogicEndBranchEvent:
				continue
			event_count += 1
			var context := str(identifier) + " event " + str(index + 1)
			if event is DialogicJumpEvent:
				jump_count += 1
				var target: String = event.timeline_identifier if event.timeline_identifier else str(identifier)
				if not timelines.has(target):
					fail(context + " jumps to unknown timeline: " + target)
				elif event.label_name and not labels[target].has(event.label_name):
					fail(context + " jumps to unknown label: " + target + "/" + event.label_name)
			elif event is DialogicBackgroundEvent:
				if event.scene.begins_with("res://") and not FileAccess.file_exists(event.scene):
					fail(context + " missing background scene: " + event.scene)
				if event.argument.begins_with("res://") and not FileAccess.file_exists(event.argument):
					fail(context + " missing background: " + event.argument)
			elif event is DialogicCharacterEvent:
				if event.character_identifier != "--All--":
					check_character(event.character_identifier, event.portrait, characters, context)
			elif event is DialogicTextEvent:
				var content: String = event.event_node_as_text.strip_edges()
				if event.character_identifier:
					check_character(event.character_identifier, event.portrait, characters, context)
				for prefix in ["- ", "if ", "elif ", "else:", "set ", "jump ", "label ", "join ", "leave ", "update ", "[background"]:
					if content.begins_with(prefix):
						fail(context + " parsed command as text: " + content.left(100))
						break
				if event.text:
					text_count += 1
		print(str(identifier), " (", timeline.resource_path, "): ", event_count, " events, ", text_count, " text, ", labels[identifier].size(), " labels, ", jump_count, " jumps")
		total_events += event_count
		total_text += text_count
		total_labels += labels[identifier].size()
		total_jumps += jump_count

	print("Validated ", timelines.size(), " timelines, ", total_events, " events, ", total_text, " text, ", total_labels, " labels, ", total_jumps, " jumps; errors=", errors)

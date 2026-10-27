extends Node
## Slightly dims every visible character except the one currently speaking.
## Narration and off-screen speakers leave everyone at normal brightness.

const NORMAL_COLOR := Color(1, 1, 1, 1)
const DIMMED_COLOR := Color(0.78, 0.76, 0.72, 1.0)
const FADE_TIME := 0.18

var current_speaker: DialogicCharacter = null


func _ready() -> void:
	Dialogic.Text.text_started.connect(_on_text_started)
	Dialogic.Portraits.character_joined.connect(_on_portraits_changed)
	Dialogic.Portraits.character_left.connect(_on_portraits_changed)
	Dialogic.Portraits.character_portrait_changed.connect(_on_portraits_changed)
	Dialogic.timeline_started.connect(_reset)
	Dialogic.timeline_ended.connect(_reset)


func _on_text_started(info: Dictionary) -> void:
	current_speaker = info.get("character") as DialogicCharacter
	_apply_focus()


func _on_portraits_changed(_info: Dictionary = {}) -> void:
	_apply_focus()


func _reset() -> void:
	current_speaker = null
	_apply_focus()


func _apply_focus() -> void:
	# A speaker without a visible portrait (voice-over) is treated like narration:
	# dimming everyone would leave the scene with no highlighted character.
	var has_visible_speaker := current_speaker != null and Dialogic.Portraits.is_character_joined(current_speaker)
	var speaker_id := current_speaker.get_identifier() if has_visible_speaker else ""

	for character_node in Dialogic.Portraits.character_nodes.values():
		if not is_instance_valid(character_node):
			continue
		var character: DialogicCharacter = character_node.get_meta("character", null)
		var target := NORMAL_COLOR
		if has_visible_speaker and character != null and character.get_identifier() != speaker_id:
			target = DIMMED_COLOR
		for portrait in character_node.get_children():
			if portrait is CanvasItem:
				_tween_portrait(portrait, target)


func _tween_portrait(portrait: CanvasItem, target: Color) -> void:
	if portrait.has_meta("_speaker_focus_tween"):
		var previous: Tween = portrait.get_meta("_speaker_focus_tween")
		if is_instance_valid(previous) and previous.is_valid():
			previous.kill()
	var tween := create_tween()
	portrait.set_meta("_speaker_focus_tween", tween)
	tween.tween_property(portrait, "modulate", target, FADE_TIME)

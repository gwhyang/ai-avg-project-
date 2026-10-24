extends Control

@onready var menu: VBoxContainer = $Menu
@onready var start_button: Button = $Menu/StartButton
@onready var quit_button: Button = $Menu/QuitButton

var story_running := false


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(get_tree().quit)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	start_button.grab_focus()


func _on_start_pressed() -> void:
	if story_running:
		return
	story_running = true
	menu.hide()
	Dialogic.start("timeline")


func _on_timeline_ended() -> void:
	story_running = false
	menu.show()
	start_button.grab_focus()

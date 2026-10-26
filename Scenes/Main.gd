extends Control
## 主菜单：在旧信卷轴上开始故事，或退出游戏。
## 视觉素材由 UI/Theme 与 UI/StyleBoxes 提供，对话框样式由 Dialogic 样式
## `res://UI/Dialogic/ink_wash_style.tres` 统一管理。

@onready var board_area: Control = $BoardArea
@onready var footer: Label = $Footer
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton

var story_running := false


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(get_tree().quit)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	start_button.grab_focus()


func _on_start_pressed() -> void:
	if story_running:
		return
	show_menu(false)
	Dialogic.start("timeline")


func _on_timeline_started() -> void:
	story_running = true
	show_menu(false)


func _on_timeline_ended() -> void:
	story_running = false
	show_menu(true)
	start_button.grab_focus()


func show_menu(shown: bool) -> void:
	board_area.visible = shown
	footer.visible = shown

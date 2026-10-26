extends Control
## 小游戏大厅：卡片由 GameCard.tscn 实例化，本脚本只负责数据与跳转。

const GAMES = [
	{"id": "reading", "title": "批文解读", "chapter": "第二章 · 学批", "kind": "quiz"},
	{"id": "pairing", "title": "隐语配对", "chapter": "第二章 · 学批", "kind": "pairing"},
	{"id": "envelope", "title": "批封辨识", "chapter": "第二章 · 学批", "kind": "quiz"},
	{"id": "counting", "title": "银两清点", "chapter": "第三章 · 送批", "kind": "quiz"},
	{"id": "route", "title": "送批路线", "chapter": "第三章 · 送批", "kind": "route"},
	{"id": "relief", "title": "救国批甄别", "chapter": "第四章 · 家国", "kind": "quiz"},
	{"id": "forgery", "title": "识破伪信", "chapter": "第五章 · 抉择", "kind": "quiz"},
	{"id": "restoration", "title": "批文还原", "chapter": "终章 · 现代", "kind": "quiz"},
]

const CARD_SCENE := preload("res://Minigames/GameCard.tscn")

@onready var menu: MarginContainer = %Menu
@onready var grid: GridContainer = %Grid
@onready var quit_button: Button = %QuitButton

var first_card: Button = null
var active_game: Control = null


func _ready() -> void:
	quit_button.pressed.connect(get_tree().quit)
	_populate_cards()
	_update_grid_columns()
	get_viewport().size_changed.connect(_update_grid_columns)
	if first_card:
		first_card.grab_focus()


func _populate_cards() -> void:
	for index in GAMES.size():
		var entry: Dictionary = GAMES[index]
		var card: Button = CARD_SCENE.instantiate()
		grid.add_child(card)
		card.setup(index, entry)
		card.pressed.connect(_open_game.bind(entry))
		if first_card == null:
			first_card = card


func _update_grid_columns() -> void:
	var viewport_width := get_viewport_rect().size.x
	grid.columns = 1 if viewport_width < 1100 else 2
	var side_margin := 24 if viewport_width < 700 else 70
	menu.add_theme_constant_override("margin_left", side_margin)
	menu.add_theme_constant_override("margin_right", side_margin)


func _open_game(entry: Dictionary) -> void:
	if active_game != null:
		return
	var scene_path := "res://Minigames/Quiz.tscn"
	match entry.kind:
		"pairing":
			scene_path = "res://Minigames/Pairing.tscn"
		"route":
			scene_path = "res://Minigames/Route.tscn"
	var scene: PackedScene = load(scene_path)
	active_game = scene.instantiate()
	if entry.kind == "quiz":
		active_game.configure(entry.id)
	active_game.exit_requested.connect(_return_to_hub)
	menu.hide()
	add_child(active_game)


func _return_to_hub() -> void:
	if active_game == null:
		return
	active_game.queue_free()
	active_game = null
	menu.show()
	if first_card:
		first_card.grab_focus()

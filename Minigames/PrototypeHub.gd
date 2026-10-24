extends Control

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

var menu: MarginContainer
var grid: GridContainer
var first_card: Button
var active_game: Control


func _ready() -> void:
	_build_ui()
	_update_grid_columns()
	get_viewport().size_changed.connect(_update_grid_columns)
	first_card.grab_focus()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://Asset/sprite/bg/13.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.035, 0.04, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	menu = MarginContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_theme_constant_override("margin_left", 70)
	menu.add_theme_constant_override("margin_top", 48)
	menu.add_theme_constant_override("margin_right", 70)
	menu.add_theme_constant_override("margin_bottom", 48)
	add_child(menu)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	menu.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var title := Label.new()
	title.text = "小游戏试玩"
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.9))
	heading.add_child(title)
	var brand := Label.new()
	brand.text = "一纸千山"
	brand.add_theme_font_size_override("font_size", 22)
	brand.add_theme_color_override("font_color", Color(0.91, 0.82, 0.68))
	heading.add_child(brand)
	var quit_button := Button.new()
	quit_button.text = "退出"
	quit_button.custom_minimum_size = Vector2(128, 52)
	quit_button.add_theme_font_size_override("font_size", 21)
	quit_button.add_theme_stylebox_override("normal", _card_style(Color(0.13, 0.17, 0.18, 0.95)))
	quit_button.add_theme_stylebox_override("hover", _card_style(Color(0.24, 0.29, 0.29, 0.98)))
	quit_button.pressed.connect(get_tree().quit)
	header.add_child(quit_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)

	for entry in GAMES:
		var card := _game_card(entry)
		grid.add_child(card)
		if first_card == null:
			first_card = card


func _game_card(entry: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(370, 156)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("normal", _card_style(Color(0.11, 0.16, 0.17, 0.95)))
	card.add_theme_stylebox_override("hover", _card_style(Color(0.22, 0.29, 0.29, 0.98)))
	card.add_theme_stylebox_override("pressed", _card_style(Color(0.31, 0.37, 0.35, 0.98)))
	card.pressed.connect(_open_game.bind(entry))
	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", 26)
	content.add_theme_constant_override("margin_top", 18)
	content.add_theme_constant_override("margin_right", 26)
	content.add_theme_constant_override("margin_bottom", 18)
	card.add_child(content)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(details)
	var index := Label.new()
	index.text = "%02d / 08" % (GAMES.find(entry) + 1)
	index.add_theme_font_size_override("font_size", 19)
	index.add_theme_color_override("font_color", Color(0.9, 0.7, 0.52))
	index.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(index)
	var title := Label.new()
	title.text = entry.title
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.97, 0.9))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(title)
	var chapter := Label.new()
	chapter.text = entry.chapter
	chapter.add_theme_font_size_override("font_size", 21)
	chapter.add_theme_color_override("font_color", Color(0.84, 0.86, 0.83))
	chapter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(chapter)
	return card


func _card_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.77, 0.68, 0.51, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _update_grid_columns() -> void:
	var viewport_width := get_viewport_rect().size.x
	grid.columns = 1 if viewport_width < 1040 else 2
	var side_margin := 24 if viewport_width < 700 else 70
	menu.add_theme_constant_override("margin_left", side_margin)
	menu.add_theme_constant_override("margin_right", side_margin)
	for card in grid.get_children():
		card.custom_minimum_size.x = 260 if viewport_width < 700 else 370


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
	active_game.queue_free()
	active_game = null
	menu.show()
	first_card.grab_focus()

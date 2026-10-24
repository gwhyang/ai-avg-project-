extends Control

signal exit_requested

const QUIZ_DATA = preload("res://Minigames/QuizData.gd")

var game_id := "reading"
var had_wrong_answer := false
var complete := false
var game: Dictionary
var option_buttons: Array[Button] = []
var screen_margin: MarginContainer
var feedback_label: Label
var retry_button: Button
var restart_button: Button


func configure(id: String) -> void:
	game_id = id


func _ready() -> void:
	if not QUIZ_DATA.GAMES.has(game_id):
		push_error("Unknown minigame: " + game_id)
		return
	game = QUIZ_DATA.GAMES[game_id]
	_build_ui()
	resized.connect(_update_side_margins)
	_update_side_margins()
	option_buttons[0].grab_focus()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load(game.background)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.035, 0.04, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	screen_margin = MarginContainer.new()
	screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_margin.add_theme_constant_override("margin_top", 44)
	screen_margin.add_theme_constant_override("margin_bottom", 44)
	add_child(screen_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	screen_margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var back_button := _button("返回", 21, Color(0.13, 0.17, 0.18, 0.92), Color(0.21, 0.27, 0.28, 0.96))
	back_button.custom_minimum_size = Vector2(140, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var order_label := _label(game.order, 21, Color(0.91, 0.85, 0.73))
	header.add_child(order_label)

	column.add_child(_label(game.title, 50, Color(1.0, 0.97, 0.89)))
	column.add_child(_label(game.chapter, 22, Color(0.89, 0.79, 0.66)))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	scroll.add_child(body)

	var paper := PanelContainer.new()
	paper.custom_minimum_size.y = 215
	paper.add_theme_stylebox_override("panel", _style(Color(0.95, 0.91, 0.81, 0.98), Color(0.73, 0.62, 0.45)))
	body.add_child(paper)
	var paper_margin := MarginContainer.new()
	paper_margin.add_theme_constant_override("margin_left", 30)
	paper_margin.add_theme_constant_override("margin_top", 24)
	paper_margin.add_theme_constant_override("margin_right", 30)
	paper_margin.add_theme_constant_override("margin_bottom", 24)
	paper.add_child(paper_margin)
	var paper_content := VBoxContainer.new()
	paper_content.add_theme_constant_override("separation", 18)
	paper_margin.add_child(paper_content)
	paper_content.add_child(_label(game.document_title, 22, Color(0.48, 0.15, 0.14)))
	var document := _label(game.document, 30, Color(0.16, 0.17, 0.16))
	document.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper_content.add_child(document)

	var question := _label(game.question, 29, Color(1.0, 0.97, 0.9))
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(question)

	for index in range(game.options.size()):
		var option := _button(game.options[index], 26, Color(0.12, 0.17, 0.18, 0.95), Color(0.22, 0.29, 0.29, 0.97))
		option.custom_minimum_size.y = 82
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option.pressed.connect(_on_answer.bind(index))
		body.add_child(option)
		option_buttons.append(option)

	feedback_label = _label("", 24, Color(1.0, 0.96, 0.87))
	feedback_label.custom_minimum_size.y = 66
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(feedback_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	body.add_child(actions)
	retry_button = _button("再试一次", 23, Color(0.5, 0.16, 0.15, 0.98), Color(0.64, 0.21, 0.18, 1.0))
	retry_button.custom_minimum_size = Vector2(200, 58)
	retry_button.pressed.connect(_on_retry)
	retry_button.hide()
	actions.add_child(retry_button)
	restart_button = _button("重新开始", 23, Color(0.13, 0.18, 0.18, 0.96), Color(0.23, 0.29, 0.29, 0.98))
	restart_button.custom_minimum_size = Vector2(200, 58)
	restart_button.pressed.connect(_on_restart)
	restart_button.hide()
	actions.add_child(restart_button)


func _on_answer(index: int) -> void:
	if complete or retry_button.visible:
		return
	var correct: bool = index == game.correct
	for option in option_buttons:
		option.disabled = true
	option_buttons[index].add_theme_stylebox_override("disabled", _style(
		Color(0.18, 0.44, 0.34, 0.98) if correct else Color(0.56, 0.18, 0.16, 0.98),
		Color(0.9, 0.84, 0.64)
	))
	option_buttons[index].add_theme_color_override("font_disabled_color", Color.WHITE)
	if correct:
		complete = true
		var reward: float = game.reward * (0.5 if had_wrong_answer else 1.0)
		feedback_label.text = game.success
		if reward > 0:
			feedback_label.text += "\n" + game.reward_name + " +" + _format_reward(reward)
		feedback_label.add_theme_color_override("font_color", Color(0.72, 0.94, 0.8))
		restart_button.show()
		restart_button.grab_focus()
	else:
		had_wrong_answer = true
		feedback_label.text = game.wrong
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.7))
		retry_button.show()
		retry_button.grab_focus()


func _on_retry() -> void:
	_clear_answer()
	option_buttons[0].grab_focus()


func _on_restart() -> void:
	had_wrong_answer = false
	complete = false
	_clear_answer()
	option_buttons[0].grab_focus()


func _clear_answer() -> void:
	for option in option_buttons:
		option.disabled = false
		option.remove_theme_stylebox_override("disabled")
	feedback_label.text = ""
	retry_button.hide()
	restart_button.hide()


func _format_reward(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)


func _on_back_pressed() -> void:
	var has_listener := not exit_requested.get_connections().is_empty()
	exit_requested.emit()
	if not has_listener:
		get_tree().quit()


func _update_side_margins() -> void:
	var side_margin := 24 if size.x < 700 else 70
	screen_margin.add_theme_constant_override("margin_left", side_margin)
	screen_margin.add_theme_constant_override("margin_right", side_margin)


func _label(content: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(content: String, size: int, normal: Color, hover: Color) -> Button:
	var button := Button.new()
	button.text = content
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(normal, Color(0.79, 0.72, 0.58, 0.5)))
	button.add_theme_stylebox_override("hover", _style(hover, Color(0.96, 0.86, 0.66, 0.9)))
	button.add_theme_stylebox_override("pressed", _style(hover, Color(0.96, 0.86, 0.66, 0.9)))
	return button


func _style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	return style


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

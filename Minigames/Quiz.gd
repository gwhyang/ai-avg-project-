extends Control
## 批文解读类小游戏。布局在 Quiz.tscn，本脚本只负责数据、答题状态与流程。

signal exit_requested

const QUIZ_DATA = preload("res://Minigames/QuizData.gd")

@onready var background: TextureRect = $Background
@onready var screen_margin: MarginContainer = %ScreenMargin
@onready var back_button: Button = %BackButton
@onready var order_label: Label = %OrderLabel
@onready var title_label: Label = %TitleLabel
@onready var chapter_label: Label = %ChapterLabel
@onready var document_title: Label = %DocumentTitle
@onready var document_label: Label = %Document
@onready var question_label: Label = %Question
@onready var option_a: Button = %OptionA
@onready var option_b: Button = %OptionB
@onready var option_c: Button = %OptionC
@onready var feedback_label: Label = %Feedback
@onready var retry_button: Button = %Retry
@onready var restart_button: Button = %Restart

var game_id := "reading"
var game: Dictionary = {}
var option_buttons: Array[Button] = []
var complete := false
var had_wrong_answer := false


func configure(id: String) -> void:
	game_id = id
	if is_node_ready() and QUIZ_DATA.GAMES.has(game_id):
		game = QUIZ_DATA.GAMES[game_id]
		_apply_data()


func _ready() -> void:
	if not QUIZ_DATA.GAMES.has(game_id):
		push_error("Unknown minigame: " + game_id)
		return
	game = QUIZ_DATA.GAMES[game_id]
	option_buttons = [option_a, option_b, option_c]

	for index in option_buttons.size():
		var option := option_buttons[index]
		option.visible = index < game.options.size()
		if option.visible:
			option.pressed.connect(_on_answer.bind(index))

	back_button.pressed.connect(_on_back_pressed)
	retry_button.pressed.connect(_on_retry)
	restart_button.pressed.connect(_on_restart)

	resized.connect(_update_side_margins)
	_update_side_margins()
	_apply_data()
	option_buttons[0].grab_focus()


func _apply_data() -> void:
	background.texture = load(game.background)
	order_label.text = game.order
	title_label.text = game.title
	chapter_label.text = game.chapter
	document_title.text = game.document_title
	document_label.text = game.document
	question_label.text = game.question
	for index in option_buttons.size():
		var option := option_buttons[index]
		if index < game.options.size():
			option.text = game.options[index]
	complete = false
	had_wrong_answer = false
	_clear_answer()


func _on_answer(index: int) -> void:
	if complete or retry_button.visible:
		return
	var correct: bool = index == game.correct
	for option in option_buttons:
		option.disabled = true
	var chosen := option_buttons[index]
	chosen.theme_type_variation = &"AnswerCorrect" if correct else &"AnswerWrong"

	if correct:
		complete = true
		var reward: float = game.reward * (0.5 if had_wrong_answer else 1.0)
		feedback_label.text = game.success
		if reward > 0:
			feedback_label.text += "\n" + game.reward_name + " +" + _format_reward(reward)
		feedback_label.theme_type_variation = &"FeedbackSuccess"
		restart_button.show()
		restart_button.grab_focus()
	else:
		had_wrong_answer = true
		feedback_label.text = game.wrong
		feedback_label.theme_type_variation = &"FeedbackFailure"
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
		option.theme_type_variation = &""
	feedback_label.text = ""
	feedback_label.theme_type_variation = &""
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

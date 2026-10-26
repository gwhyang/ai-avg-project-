extends Control
## 隐语配对。两组题目与连线画布都在 Pairing.tscn 里，本脚本只负责数据与判定。

signal exit_requested
signal story_finished(result: Dictionary)

const PHRASES := ["悦弟尾牙到莆", "分配米伍拾斤"]
const OPTIONS := [
	[
		"A  告知“一位叫‘悦弟’的亲人，年底要回莆田老家”",
		"B  一笔二十元汇款将于年底汇至莆田",
	],
	[
		"A  收到港币伍拾元",
		"B  收到大洋伍拾元",
		"C  分配米伍拾斤",
	],
]
const ANSWERS := [1, 0]
const ACCENTS := [Color("76c6b1"), Color("e2b76b")]
const TEXT := Color("f4f0e6")
const MUTED := Color("bcbdb3")

@onready var links: Node2D = $Links
@onready var padding: MarginContainer = $Workspace/Padding
@onready var header_grid: GridContainer = %HeaderGrid
@onready var footer_grid: GridContainer = %FooterGrid
@onready var scroll_view: ScrollContainer = %Scroll
@onready var status_label: Label = %Status
@onready var reward_label: Label = %Reward
@onready var submit_button: Button = %Submit
@onready var replay_button: Button = %Replay
@onready var continue_button: Button = %Continue
@onready var back_button: Button = %Back
@onready var source_buttons: Array = [%Phrase1, %Phrase2]
@onready var option_buttons: Array = [[%A1A, %A1B], [%A2A, %A2B, %A2C]]
@onready var group_grids: Array = [%Grid1, %Grid2]

var link_lines: Array[Line2D] = []
var chosen: Array[int] = [-1, -1]
var active_group := -1
var had_error := false
var completed := false
var story_mode := false
var _last_result: Dictionary = {}


func _ready() -> void:
	_bind_ui()
	resized.connect(_on_resized)
	_on_resized()
	_set_status("选择一条隐语，再选择它对应的实际含义。", MUTED)
	_refresh()
	source_buttons[0].grab_focus()


func _bind_ui() -> void:
	for group_index in PHRASES.size():
		source_buttons[group_index].text = PHRASES[group_index]
		source_buttons[group_index].pressed.connect(_select_source.bind(group_index))
		for option_index in OPTIONS[group_index].size():
			var option: Button = option_buttons[group_index][option_index]
			option.text = OPTIONS[group_index][option_index]
			option.pressed.connect(_select_answer.bind(group_index, option_index))
		var line := Line2D.new()
		line.width = 4.0
		line.antialiased = true
		line.default_color = ACCENTS[group_index]
		line.visible = false
		links.add_child(line)
		link_lines.append(line)

	back_button.pressed.connect(_on_back_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	continue_button.pressed.connect(_on_continue)
	scroll_view.get_v_scroll_bar().value_changed.connect(
		func(_value: float) -> void: _layout_links())


func _select_source(group_index: int) -> void:
	if completed:
		return
	active_group = group_index
	_set_status("已选中第 %d 组隐语，请选择右侧含义。" % (group_index + 1), ACCENTS[group_index])
	_refresh()


func _select_answer(group_index: int, option_index: int) -> void:
	if completed:
		return
	if active_group != group_index:
		_set_status("请先选择第 %d 组的隐语。" % (group_index + 1), MUTED)
		return
	chosen[group_index] = option_index
	active_group = -1
	_set_status("第 %d 组已连接。" % (group_index + 1), ACCENTS[group_index])
	_refresh()


func _on_submit_pressed() -> void:
	if completed or chosen.has(-1):
		return
	var wrong_groups: Array[int] = []
	for group_index in ANSWERS.size():
		if chosen[group_index] != ANSWERS[group_index]:
			wrong_groups.append(group_index)
	if wrong_groups.is_empty():
		completed = true
		var reward := 5 if had_error else 10
		_last_result = {
			"success": true,
			"retried": had_error,
			"reward": reward,
		}
		_set_status("两组配对正确。顺伯信任 +%d。" % reward, ACCENTS[0])
		if story_mode:
			submit_button.hide()
			continue_button.show()
			continue_button.grab_focus()
	else:
		had_error = true
		var wrong_numbers := PackedStringArray()
		for group_index in wrong_groups:
			wrong_numbers.append(str(group_index + 1))
			chosen[group_index] = -1
		active_group = wrong_groups[0]
		_set_status("第 %s 组仍不相符，已保留正确连线。" % ", ".join(wrong_numbers),
			Color("f0a99b"))
	_refresh()


func _on_replay_pressed() -> void:
	chosen = [-1, -1]
	active_group = -1
	had_error = false
	completed = false
	_last_result = {}
	submit_button.show()
	continue_button.hide()
	_set_status("选择一条隐语，再选择它对应的实际含义。", MUTED)
	_refresh()
	source_buttons[0].grab_focus()


func set_story_mode(enabled: bool) -> void:
	story_mode = enabled
	back_button.visible = not enabled
	replay_button.visible = not enabled
	continue_button.visible = false
	submit_button.show()
	if enabled and completed:
		submit_button.hide()
		continue_button.show()


func _on_continue() -> void:
	story_finished.emit(_last_result)


func _on_back_pressed() -> void:
	var has_listener := not exit_requested.get_connections().is_empty()
	exit_requested.emit()
	if not has_listener:
		get_tree().quit()


func _set_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)


func _refresh() -> void:
	reward_label.text = "奖励预览  顺伯信任 +%d" % (5 if had_error else 10)
	submit_button.disabled = completed or chosen.has(-1)
	for group_index in PHRASES.size():
		var source: Button = source_buttons[group_index]
		_set_chip_selected(source, active_group == group_index or chosen[group_index] >= 0)
		for option_index in OPTIONS[group_index].size():
			var option: Button = option_buttons[group_index][option_index]
			_set_chip_selected(option, chosen[group_index] == option_index)
	call_deferred("_layout_links")


func _set_chip_selected(button: Button, selected: bool) -> void:
	button.theme_type_variation = &"ChipSelected" if selected else &""


func _on_resized() -> void:
	var compact := size.x < 820
	var narrow := size.x < 680
	header_grid.columns = 1 if compact else 3
	footer_grid.columns = 1 if narrow else 3
	var padding_size := 18 if narrow else 36
	padding.add_theme_constant_override("margin_left", padding_size)
	padding.add_theme_constant_override("margin_right", padding_size)
	for grid in group_grids:
		grid.columns = 1 if compact else 2
	call_deferred("_layout_links")


func _layout_links() -> void:
	for group_index in PHRASES.size():
		var line := link_lines[group_index]
		var option_index: int = chosen[group_index]
		line.visible = option_index >= 0
		if option_index < 0:
			continue
		var source_button: Button = source_buttons[group_index]
		var source_rect: Rect2 = source_button.get_global_rect()
		var target: Button = option_buttons[group_index][option_index]
		var target_rect: Rect2 = target.get_global_rect()
		if not scroll_view.get_global_rect().intersects(source_rect) or not scroll_view.get_global_rect().intersects(target_rect):
			line.visible = false
			continue
		var start: Vector2
		var finish: Vector2
		if group_grids[group_index].columns == 1:
			start = Vector2(source_rect.end.x - 24, source_rect.end.y)
			finish = Vector2(target_rect.end.x - 24, target_rect.position.y)
		else:
			start = Vector2(source_rect.end.x, source_rect.get_center().y)
			finish = Vector2(target_rect.position.x, target_rect.get_center().y)
		line.points = PackedVector2Array([links.to_local(start), links.to_local(finish)])

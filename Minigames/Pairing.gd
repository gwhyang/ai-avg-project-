extends Control

signal exit_requested

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

@onready var content: VBoxContainer = $Workspace/Padding/Content
@onready var links: Node2D = $Links
@onready var padding: MarginContainer = $Workspace/Padding

var source_buttons: Array[Button] = []
var option_buttons: Array = []
var group_grids: Array[GridContainer] = []
var link_lines: Array[Line2D] = []
var chosen := [-1, -1]
var active_group := -1
var had_error := false
var completed := false

var title_label: Label
var reward_label: Label
var status_label: Label
var submit_button: Button
var scroll_view: ScrollContainer
var header_grid: GridContainer
var footer_grid: GridContainer


func _ready() -> void:
	_build_ui()
	resized.connect(_on_resized)
	_on_resized()
	_set_status("选择一条隐语，再选择它对应的实际含义。", MUTED)
	_refresh()
	source_buttons[0].grab_focus()


func _build_ui() -> void:
	header_grid = GridContainer.new()
	header_grid.columns = 3
	header_grid.add_theme_constant_override("h_separation", 20)
	header_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(header_grid)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 5)
	header_grid.add_child(heading)

	var eyebrow := _make_label("第二章  /  学批", 19, ACCENTS[1])
	heading.add_child(eyebrow)
	title_label = _make_label("隐语配对", 42, TEXT)
	heading.add_child(title_label)

	reward_label = _make_label("奖励预览  顺伯信任 +10", 22, ACCENTS[0])
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_grid.add_child(reward_label)

	var back_button := _make_button("返回", 144, 54)
	back_button.pressed.connect(_on_back_pressed)
	header_grid.add_child(back_button)

	content.add_child(HSeparator.new())
	var intro := _make_label("顺伯摆出两封批，请将隐语与其真正含义相连。", 24, TEXT)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)

	scroll_view = ScrollContainer.new()
	scroll_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_view.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: _layout_links())
	content.add_child(scroll_view)

	var groups := VBoxContainer.new()
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("separation", 22)
	scroll_view.add_child(groups)
	for group_index in PHRASES.size():
		_build_group(group_index, groups)

	content.add_child(HSeparator.new())
	footer_grid = GridContainer.new()
	footer_grid.columns = 3
	footer_grid.add_theme_constant_override("h_separation", 16)
	footer_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(footer_grid)

	status_label = _make_label("", 20, MUTED)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_grid.add_child(status_label)

	var replay_button := _make_button("重新开始", 156, 60)
	replay_button.pressed.connect(_on_replay_pressed)
	footer_grid.add_child(replay_button)

	submit_button = _make_button("核对配对", 156, 60)
	submit_button.pressed.connect(_on_submit_pressed)
	footer_grid.add_child(submit_button)


func _build_group(group_index: int, parent: VBoxContainer) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 12)
	parent.add_child(section)

	var heading := _make_label("0%d  /  %s" % [group_index + 1, "第一组" if group_index == 0 else "第二组"], 20, ACCENTS[group_index])
	section.add_child(heading)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 68)
	grid.add_theme_constant_override("v_separation", 18)
	section.add_child(grid)
	group_grids.append(grid)

	var phrase_column := VBoxContainer.new()
	phrase_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phrase_column.add_theme_constant_override("separation", 9)
	grid.add_child(phrase_column)
	phrase_column.add_child(_make_label("隐语", 18, MUTED))
	var phrase_button := _make_button(PHRASES[group_index], 0, 76)
	phrase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phrase_button.pressed.connect(_select_source.bind(group_index))
	phrase_column.add_child(phrase_button)
	source_buttons.append(phrase_button)

	var answer_column := VBoxContainer.new()
	answer_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_column.add_theme_constant_override("separation", 8)
	grid.add_child(answer_column)
	answer_column.add_child(_make_label("实际传递内容", 18, MUTED))
	var group_options: Array[Button] = []
	for option_index in OPTIONS[group_index].size():
		var answer_button := _make_button(OPTIONS[group_index][option_index], 0, 66)
		answer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		answer_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		answer_button.pressed.connect(_select_answer.bind(group_index, option_index))
		answer_column.add_child(answer_button)
		group_options.append(answer_button)
	option_buttons.append(group_options)

	var line := Line2D.new()
	line.width = 4.0
	line.antialiased = true
	line.default_color = ACCENTS[group_index]
	line.visible = false
	links.add_child(line)
	link_lines.append(line)

	if group_index == 0:
		parent.add_child(HSeparator.new())


func _make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(value: String, min_width: float, min_height: float) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(min_width, min_height)
	button.add_theme_font_size_override("font_size", 22)
	_style_button(button, Color("263332"), Color("71827b"), TEXT)
	return button


func _style_button(button: Button, fill: Color, border: Color, color: Color) -> void:
	button.add_theme_stylebox_override("normal", _style(fill, border))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.1), border.lightened(0.2)))
	button.add_theme_stylebox_override("pressed", _style(fill.lightened(0.17), border))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, border.lightened(0.25)))
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_disabled_color", color.darkened(0.35))


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


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
		_set_status("两组配对正确。顺伯信任 +%d。" % reward, ACCENTS[0])
	else:
		had_error = true
		var wrong_numbers := PackedStringArray()
		for group_index in wrong_groups:
			wrong_numbers.append(str(group_index + 1))
			chosen[group_index] = -1
		active_group = wrong_groups[0]
		_set_status("第 %s 组仍不相符，已保留正确连线。" % ", ".join(wrong_numbers), Color("f0a99b"))
	_refresh()


func _on_replay_pressed() -> void:
	chosen = [-1, -1]
	active_group = -1
	had_error = false
	completed = false
	_set_status("选择一条隐语，再选择它对应的实际含义。", MUTED)
	_refresh()
	source_buttons[0].grab_focus()


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
	_style_button(submit_button, Color("8d3e35"), Color("d49a77"), TEXT)
	for group_index in PHRASES.size():
		var accent: Color = ACCENTS[group_index]
		var source_selected: bool = active_group == group_index or chosen[group_index] >= 0
		_style_button(source_buttons[group_index], Color("29413e") if source_selected else Color("263332"), accent if source_selected else Color("71827b"), TEXT)
		source_buttons[group_index].disabled = completed
		for option_index in option_buttons[group_index].size():
			var button: Button = option_buttons[group_index][option_index]
			var selected: bool = chosen[group_index] == option_index
			_style_button(button, Color("29413e") if selected else Color("263332"), accent if selected else Color("71827b"), TEXT)
			button.disabled = completed
	call_deferred("_layout_links")


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
		var source_rect := source_buttons[group_index].get_global_rect()
		var target: Button = option_buttons[group_index][option_index]
		var target_rect := target.get_global_rect()
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

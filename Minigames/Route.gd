extends Control

signal exit_requested

const ROUTES := [
	{
		"name": "官道", "number": "01 / 路线甲", "pace": "路程较短",
		"description": "道路平坦，但必经日伪哨卡，容易遭到盘查。",
		"tradeoff": "哨卡盘查 · 批银有损失风险",
		"result": "在哨卡被拦下查验。批银有损失风险，具体损失尚未确定。",
		"color": Color("d8a077"),
	},
	{
		"name": "山道", "number": "02 / 路线乙", "pace": "绕开哨卡",
		"description": "路陡林深，人烟稀少，可能遇上野兽或盗匪。",
		"tradeoff": "平安送到 · 消耗体力",
		"result": "绕开哨卡，平安送到。山路陡峭，沿途耗去不少体力。",
		"color": Color("83bea8"),
	},
	{
		"name": "水路", "number": "03 / 路线丙", "pace": "隐蔽稳妥",
		"description": "乘小船沿河而上，但费时，雨天也有涨水之险。",
		"tradeoff": "晚到一个时辰 · 顺伯信任 +5",
		"result": "平安送达，却比预计晚了一个时辰。你向收批家属如实说明。",
		"color": Color("84b9d0"),
	},
]

const TEXT := Color("f4f0e6")
const MUTED := Color("bcbdb3")
const SURFACE := Color("263332")

@onready var content: VBoxContainer = $Workspace/Padding/Content

var route_grid: GridContainer
var route_panels: Array[PanelContainer] = []
var route_buttons: Array[Button] = []
var title_label: Label
var intro_label: Label
var result_heading: Label
var result_body: Label
var result_reward: Label
var status_label: Label
var selected_route := -1


func _ready() -> void:
	_build_ui()
	resized.connect(_on_resized)
	_on_resized()
	_refresh()
	route_buttons[0].grab_focus()


func _build_ui() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	content.add_child(header)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 5)
	header.add_child(heading)
	heading.add_child(_make_label("第三章  /  送批", 19, Color("e2b76b")))
	title_label = _make_label("送批路线", 42, TEXT)
	heading.add_child(title_label)

	var back_button := _make_button("返回", 144, 54)
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	content.add_child(HSeparator.new())
	intro_label = _make_label("出了镇子，三条路通往乡下。两户人家还等着批银与家书。", 24, TEXT)
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	route_grid = GridContainer.new()
	route_grid.columns = 3
	route_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_grid.add_theme_constant_override("h_separation", 20)
	route_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(route_grid)
	for route_index in ROUTES.size():
		_build_route(route_index)

	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size.y = 142
	result_panel.add_theme_stylebox_override("panel", _style(Color("172525"), Color("657973"), 1))
	content.add_child(result_panel)
	var result_padding := MarginContainer.new()
	_set_margins(result_padding, 20, 16)
	result_panel.add_child(result_padding)
	var result_content := VBoxContainer.new()
	result_content.add_theme_constant_override("separation", 6)
	result_padding.add_child(result_content)
	result_heading = _make_label("尚未选择路线", 24, TEXT)
	result_content.add_child(result_heading)
	result_body = _make_label("", 20, MUTED)
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_content.add_child(result_body)
	result_reward = _make_label("", 20, Color("84b9d0"))
	result_content.add_child(result_reward)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	content.add_child(footer)
	status_label = _make_label("", 19, MUTED)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(status_label)
	var replay_button := _make_button("重新开始", 156, 60)
	replay_button.pressed.connect(_on_replay_pressed)
	footer.add_child(replay_button)


func _build_route(route_index: int) -> void:
	var route: Dictionary = ROUTES[route_index]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 340)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_grid.add_child(panel)
	route_panels.append(panel)

	var padding := MarginContainer.new()
	_set_margins(padding, 22, 20)
	panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	padding.add_child(column)
	column.add_child(_make_label(route["number"], 18, route["color"]))
	var name_label := _make_label(route["name"], 31, TEXT)
	column.add_child(name_label)
	column.add_child(_make_label(route["pace"], 19, route["color"]))
	var description := _make_label(route["description"], 21, TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var tradeoff := _make_label(route["tradeoff"], 18, MUTED)
	tradeoff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(tradeoff)
	var button := _make_button("选择%s" % route["name"], 0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_select_route.bind(route_index))
	column.add_child(button)
	route_buttons.append(button)


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
	button.add_theme_stylebox_override("normal", _style(SURFACE, Color("71827b"), 2))
	button.add_theme_stylebox_override("hover", _style(SURFACE.lightened(0.1), Color("c8b185"), 2))
	button.add_theme_stylebox_override("pressed", _style(SURFACE.lightened(0.17), Color("c8b185"), 2))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("e2b76b"), 2))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	return button


func _style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(5)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _set_margins(container: MarginContainer, horizontal: int, vertical: int) -> void:
	container.add_theme_constant_override("margin_left", horizontal)
	container.add_theme_constant_override("margin_right", horizontal)
	container.add_theme_constant_override("margin_top", vertical)
	container.add_theme_constant_override("margin_bottom", vertical)


func _select_route(route_index: int) -> void:
	selected_route = route_index
	_refresh()


func _on_replay_pressed() -> void:
	selected_route = -1
	_refresh()
	route_buttons[0].grab_focus()


func _on_back_pressed() -> void:
	var has_listener := not exit_requested.get_connections().is_empty()
	exit_requested.emit()
	if not has_listener:
		get_tree().quit()


func _refresh() -> void:
	for route_index in ROUTES.size():
		var route: Dictionary = ROUTES[route_index]
		var selected := selected_route == route_index
		route_panels[route_index].add_theme_stylebox_override("panel", _style(Color("203333") if selected else Color("1b2929"), route["color"] if selected else Color("60716a"), 2 if selected else 1))
		route_buttons[route_index].text = "已选择" if selected else "选择%s" % route["name"]
	if selected_route < 0:
		result_heading.text = "尚未选择路线"
		result_body.text = "请从官道、山道、水路中选一条。"
		result_reward.text = ""
		status_label.text = ""
		return
	var selected: Dictionary = ROUTES[selected_route]
	result_heading.text = "已选：%s" % selected["name"]
	result_body.text = selected["result"]
	result_reward.text = "顺伯信任 +5" if selected_route == 2 else ""
	status_label.text = "可直接选择另一条路线，或重新开始。"


func _on_resized() -> void:
	var compact := size.x < 1100
	route_grid.columns = 1 if compact else 3
	for panel in route_panels:
		panel.custom_minimum_size.y = 265 if compact else 340

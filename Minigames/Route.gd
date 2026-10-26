extends Control
## 送批路线。路线卡由 RouteCard.tscn 实例化，本脚本只负责数据、选中与结果。

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

const ROUTE_CARD := preload("res://Minigames/RouteCard.tscn")

@onready var route_grid: GridContainer = %RouteGrid
@onready var result_heading: Label = %ResultHeading
@onready var result_body: Label = %ResultBody
@onready var result_reward: Label = %ResultReward
@onready var status_label: Label = %Status
@onready var replay_button: Button = %Replay
@onready var back_button: Button = %Back

var route_cards: Array = []
var route_buttons: Array = []
var selected_route := -1


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	_populate_cards()
	resized.connect(_on_resized)
	_on_resized()
	_refresh()
	route_buttons[0].grab_focus()


func _populate_cards() -> void:
	for route_index in ROUTES.size():
		var route: Dictionary = ROUTES[route_index]
		var card = ROUTE_CARD.instantiate()
		route_grid.add_child(card)
		card.setup(route_index, route, route["color"].darkened(0.45))
		card.chosen.connect(_select_route)
		route_cards.append(card)
		route_buttons.append(card.select_button)


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
	for route_index in route_cards.size():
		route_cards[route_index].set_selected(selected_route == route_index)
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
	route_grid.columns = 1 if size.x < 1100 else 3

extends PanelContainer
## 一张路线卡。布局在 RouteCard.tscn，本脚本只填充数据与选中状态。

signal chosen(index: int)

@onready var number_label: Label = $Column/Number
@onready var name_label: Label = $Column/Name
@onready var pace_label: Label = $Column/Pace
@onready var description_label: Label = $Column/Description
@onready var tradeoff_label: Label = $Column/Tradeoff
@onready var select_button: Button = $Column/SelectButton

var _index := -1
var _route_name := ""


func _ready() -> void:
	select_button.pressed.connect(_on_pressed)


func setup(index: int, route: Dictionary, accent: Color) -> void:
	_index = index
	_route_name = str(route.get("name", ""))
	number_label.text = str(route.get("number", ""))
	name_label.text = _route_name
	pace_label.text = str(route.get("pace", ""))
	description_label.text = str(route.get("description", ""))
	tradeoff_label.text = str(route.get("tradeoff", ""))
	number_label.add_theme_color_override("font_color", accent)
	pace_label.add_theme_color_override("font_color", accent)
	select_button.text = "选择" + _route_name


func set_selected(selected: bool) -> void:
	theme_type_variation = &"RouteCardSelected" if selected else &"RouteCard"
	select_button.text = "已选择" if selected else "选择" + _route_name


func _on_pressed() -> void:
	if _index >= 0:
		chosen.emit(_index)

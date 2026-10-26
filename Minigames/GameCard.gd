extends Button
## 小游戏大厅的一张卷轴卡片。布局在 GameCard.tscn，本脚本只填充数据。

@onready var order_label: Label = $Padding/Content/Order
@onready var title_label: Label = $Padding/Content/Title
@onready var chapter_label: Label = $Padding/Content/Chapter

var _index := 0
var _entry: Dictionary = {}


func setup(index: int, entry: Dictionary) -> void:
	_index = index
	_entry = entry
	if is_node_ready():
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	order_label.text = "%02d / 08" % (_index + 1)
	title_label.text = str(_entry.get("title", ""))
	chapter_label.text = str(_entry.get("chapter", ""))

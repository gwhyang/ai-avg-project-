extends SceneTree
## Verifies that the ink-wash UI art is wired up correctly:
## the project theme, the styleboxes, and the Dialogic style actually used at
## runtime by the opening timeline.

const THEME_PATH := "res://UI/Theme/ink_theme.tres"
const STYLE_PATH := "res://UI/Dialogic/ink_wash_style.tres"
const TEXTURE_DIALOG := "res://Asset/ui/panels/panel_002.png"
const TEXTURE_BUTTON := "res://Asset/ui/buttons/button_006.png"
const TEXTURE_BUTTON_HOVER := "res://Asset/ui/buttons/button_008.png"
const TEXTURE_NAMEPLATE := "res://Asset/ui/buttons/button_009.png"
const TEXTURE_NEXT := "res://Asset/ui/icons/icon_011.png"
const FONT_SERIF := "res://UI/Fonts/ink_serif.tres"
const FONT_KAI_BOLD := "res://UI/Fonts/ink_kai_bold.tres"

var errors := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_project_theme()
	_check_dialogic_style_file()
	_check_minigame_theme()
	await _check_runtime_layout()
	print("UI validation errors: ", errors)
	quit(1 if errors else 0)


func _fail(message: String) -> void:
	errors += 1
	printerr("ERROR: ", message)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _override_value(info: Dictionary, key: String) -> Variant:
	var raw: Variant = info.overrides.get(key)
	if raw is String and raw.begins_with("res://"):
		return raw
	return str_to_var(raw)


func _stylebox_texture(stylebox: StyleBox) -> String:
	if stylebox is StyleBoxTexture and stylebox.texture:
		return stylebox.texture.resource_path
	return ""


func _check_project_theme() -> void:
	var path: String = ProjectSettings.get_setting("gui/theme/custom", "")
	_expect(path == THEME_PATH, "project theme is not " + THEME_PATH + " (got '" + path + "')")
	_expect(ResourceLoader.exists(THEME_PATH), "project theme file is missing")
	var theme := load(THEME_PATH) as Theme
	_expect(theme != null, "project theme cannot be loaded as Theme")
	if theme == null:
		return
	_expect(theme.default_font != null, "theme has no default font")
	var default_font := theme.default_font as FontVariation
	_expect(default_font != null, "theme default font is not a FontVariation")
	if default_font:
		var base := default_font.base_font
		_expect(base != null, "theme default font has no base font")
		if base:
			_expect(base.resource_path.ends_with("NotoSerifSC-Subset.ttf"),
				"theme default font is not the bundled Noto Serif SC subset: " + base.resource_path)
	_expect(theme.get_font("font", "Button") != null, "Button font is not set")
	_expect(theme.get_font_size("font_size", "Button") > 0, "Button font size is not set")
	var normal := theme.get_stylebox("normal", "Button")
	_expect(_stylebox_texture(normal) == TEXTURE_BUTTON, "Button normal stylebox does not use " + TEXTURE_BUTTON)
	_expect(_stylebox_texture(theme.get_stylebox("hover", "Button")) == TEXTURE_BUTTON_HOVER,
		"Button hover stylebox does not use " + TEXTURE_BUTTON_HOVER)
	_expect(theme.get_stylebox("focus", "Button") != null, "Button focus stylebox is missing")
	_expect(theme.get_stylebox("focus", "Button") is StyleBoxFlat,
		"global Button focus must be a thin outline, not a full texture")
	var panel := theme.get_stylebox("panel", "PanelContainer")
	_expect(panel is StyleBoxFlat, "PanelContainer should use the flat parchment stylebox")
	_expect(_stylebox_texture(theme.get_stylebox("panel", "TooltipPanel")) == "res://Asset/ui/widgets/widget_001.png",
		"TooltipPanel stylebox does not use widget_001.png")


func _check_minigame_theme() -> void:
	var theme := load(THEME_PATH) as Theme
	_expect(theme != null, "theme cannot be loaded for minigame checks")
	if theme == null:
		return
	_expect(theme.get_type_variation_base("GameCard") == "Button", "GameCard variation is missing")
	_expect(_stylebox_texture(theme.get_stylebox("normal", "GameCard"))
		== "res://Asset/ui/buttons/button_001.png", "GameCard normal stylebox is wrong")
	_expect(_stylebox_texture(theme.get_stylebox("hover", "GameCard"))
		== "res://Asset/ui/buttons/button_003.png", "GameCard hover stylebox is wrong")
	_expect(theme.get_type_variation_base("ChipSelected") == "Button", "ChipSelected variation is missing")
	_expect(_stylebox_texture(theme.get_stylebox("disabled", "AnswerWrong"))
		== "res://Asset/ui/buttons/button_009.png", "AnswerWrong stylebox is wrong")
	_expect(_stylebox_texture(theme.get_stylebox("panel", "DocumentPanel"))
		== "res://Asset/ui/papers/paper_010.png", "DocumentPanel stylebox is wrong")
	_expect(_stylebox_texture(theme.get_stylebox("panel", "RouteCard"))
		== "res://Asset/ui/widgets/widget_001.png", "RouteCard stylebox is wrong")
	_expect(_stylebox_texture(theme.get_stylebox("panel", "RouteCardSelected"))
		== "res://Asset/ui/widgets/widget_002.png", "RouteCardSelected stylebox is wrong")


func _check_dialogic_style_file() -> void:
	_expect(ProjectSettings.get_setting("dialogic/layout/default_style", "") == STYLE_PATH,
		"dialogic/layout/default_style is not the ink-wash style")
	var list: Array = ProjectSettings.get_setting("dialogic/layout/style_list", [])
	_expect(STYLE_PATH in list, "dialogic/layout/style_list does not contain the ink-wash style")
	var directory: Dictionary = ProjectSettings.get_setting("dialogic/layout/style_directory", {})
	_expect(directory.get("水墨", "") == STYLE_PATH, "style_directory has no 水墨 entry")
	var style := load(STYLE_PATH) as DialogicStyle
	_expect(style != null, "ink-wash style cannot be loaded")
	if style == null:
		return
	_expect(style.name == "水墨", "style name is not 水墨")
	_expect(style.layer_list.size() == 8, "style should have 8 layers, has " + str(style.layer_list.size()))
	var base := style.get_layer_info("")
	_expect(_override_value(base, "global_font") == FONT_SERIF, "base layer global_font is wrong")
	_expect(int(_override_value(base, "global_font_size")) >= 30, "base layer global_font_size is too small")

	var textbox := style.get_layer_info("13")
	_expect(_override_value(textbox, "box_panel") == "res://UI/StyleBoxes/dialogue_box.tres",
		"textbox box_panel override is missing")
	_expect(_override_value(textbox, "name_label_box_panel") == "res://UI/StyleBoxes/name_plate.tres",
		"textbox name_label_box_panel override is missing")
	_expect(_override_value(textbox, "next_indicator_texture") == TEXTURE_NEXT,
		"textbox next indicator does not use icon_011.png")
	for key in ["box_panel", "name_label_box_panel", "next_indicator_texture", "name_label_font"]:
		var path_value: String = str(_override_value(textbox, key))
		_expect(ResourceLoader.exists(path_value), "textbox override " + key + " is missing: " + path_value)

	var choices := style.get_layer_info("15")
	for key in ["boxes_stylebox_normal", "boxes_stylebox_hovered", "boxes_stylebox_pressed",
			"boxes_stylebox_focused", "boxes_stylebox_disabled"]:
		var stylebox_path: String = str(_override_value(choices, key))
		_expect(ResourceLoader.exists(stylebox_path), "choice override " + key + " is missing: " + stylebox_path)


func _check_runtime_layout() -> void:
	var main: Control = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var start_button: Button = main.get_node("%StartButton")
	_expect(_stylebox_texture(start_button.get_theme_stylebox("normal")) == TEXTURE_BUTTON,
		"main menu button does not use the themed button art")

	start_button.pressed.emit()
	await create_timer(0.8).timeout
	await process_frame

	var text_panel: PanelContainer = root.find_child("DialogTextPanel", true, false)
	_expect(text_panel != null, "runtime textbox panel was not created")
	if text_panel:
		var panel_box := text_panel.get_theme_stylebox("panel")
		_expect(_stylebox_texture(panel_box) == TEXTURE_DIALOG,
			"runtime dialogue box does not use panel_002.png (got '" + _stylebox_texture(panel_box) + "')")
		_expect(is_equal_approx(panel_box.get_content_margin(SIDE_LEFT), 396.0),
			"dialogue box content margin is not applied")

	var name_panel: PanelContainer = root.find_child("NameLabelPanel", true, false)
	_expect(name_panel != null, "runtime nameplate panel was not created")
	if name_panel:
		_expect(_stylebox_texture(name_panel.get_theme_stylebox("panel")) == TEXTURE_NAMEPLATE,
			"runtime nameplate does not use button_009.png")

	var dialog_text: RichTextLabel = root.find_child("DialogicNode_DialogText", true, false)
	_expect(dialog_text != null, "runtime dialogue text was not created")
	if dialog_text:
		_expect(dialog_text.get_theme_font_size("normal_font_size") == 34,
			"runtime dialogue font size is not 34")
		_expect(dialog_text.get_theme_color("default_color") == Color(0.161, 0.113, 0.075),
			"runtime dialogue text color is wrong")

	var name_label: Label = root.find_child("DialogicNode_NameLabel", true, false)
	_expect(name_label != null, "runtime name label was not created")
	if name_label:
		_expect(name_label.get_theme_font_size("font_size") == 34, "runtime name label font size is not 34")
		var font := name_label.get_theme_font("font")
		_expect(font != null and font.resource_path == FONT_KAI_BOLD,
			"runtime name label does not use the Kai bold font")

	var indicator: Control = root.find_child("NextIndicator", true, false)
	_expect(indicator != null, "runtime next indicator was not created")
	if indicator:
		var indicator_texture: Texture2D = indicator.get("texture")
		_expect(indicator_texture != null and indicator_texture.resource_path == TEXTURE_NEXT,
			"runtime next indicator does not use icon_011.png")

	var choice_layer: Control = root.find_child("VN_ChoiceLayer", true, false)
	_expect(choice_layer != null, "runtime choice layer was not created")
	if choice_layer:
		var layer_theme := choice_layer.get("theme") as Theme
		_expect(layer_theme != null, "runtime choice layer has no theme")
		if layer_theme:
			_expect(_stylebox_texture(layer_theme.get_stylebox("normal", "Button")) == TEXTURE_BUTTON,
				"runtime choice normal stylebox does not use the button art")
			_expect(_stylebox_texture(layer_theme.get_stylebox("hover", "Button")) == TEXTURE_BUTTON_HOVER,
				"runtime choice hover stylebox does not use the gold button art")

	root.get_node("Dialogic").call("end_timeline", true)
	await process_frame
	print("runtime layout checked")

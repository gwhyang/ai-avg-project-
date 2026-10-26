extends SceneTree
## Regenerates the ink-wash UI resources (fonts, styleboxes, theme and the
## Dialogic style) from the cut UI art in `Asset/ui/`.
##
## Usage:
##   godot --headless --path . --script res://tools/build_ui_resources.gd
##
## The generated .tres files stay editable in the inspector. Rerun this script
## only when the art paths or the layout numbers below change.


const UI_DIR := "res://UI"
const FONT_DIR := UI_DIR + "/Fonts"
const BOX_DIR := UI_DIR + "/StyleBoxes"
const THEME_PATH := UI_DIR + "/Theme/ink_theme.tres"
const STYLE_PATH := UI_DIR + "/Dialogic/ink_wash_style.tres"

const ART_PANEL_BOARD := "res://Asset/ui/panels/panel_001.png"
const ART_PANEL_DIALOG := "res://Asset/ui/panels/panel_002.png"
const ART_DOCUMENT := "res://Asset/ui/papers/paper_010.png"
const ART_BUTTON := "res://Asset/ui/buttons/button_006.png"
const ART_BUTTON_HOVER := "res://Asset/ui/buttons/button_008.png"
const ART_BUTTON_PRESSED := "res://Asset/ui/buttons/button_009.png"
const ART_CARD := "res://Asset/ui/buttons/button_001.png"
const ART_CARD_HOVER := "res://Asset/ui/buttons/button_003.png"
const ART_CARD_PRESSED := "res://Asset/ui/buttons/button_004.png"
const ART_ROUTE_CARD := "res://Asset/ui/widgets/widget_001.png"
const ART_ROUTE_CARD_SELECTED := "res://Asset/ui/widgets/widget_002.png"
const ART_PANEL_GENERIC := "res://Asset/ui/widgets/widget_001.png"
const ART_LINE_EDIT := "res://Asset/ui/papers/paper_007.png"
const ART_NEXT_INDICATOR := "res://Asset/ui/icons/icon_011.png"

const INK := Color(0.161, 0.113, 0.075)
const INK_SOFT := Color(0.353, 0.251, 0.176)
const VERMILION := Color(0.647, 0.220, 0.145)
const GOLD := Color(0.784, 0.627, 0.353)
const CREAM := Color(0.965, 0.918, 0.839)

const DIALOGIC_DEFAULT_PARTS := "res://addons/dialogic/Modules/DefaultLayoutParts/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for directory in [FONT_DIR, BOX_DIR, UI_DIR + "/Theme", UI_DIR + "/Dialogic"]:
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if error != OK:
			printerr("Could not create ", directory, " (", error, ")")
			quit(1)
			return

	_make_fonts()
	_make_styleboxes()
	_make_theme()
	_make_dialogic_style()
	print("UI resources generated")
	quit()


func _save(resource: Resource, path: String) -> void:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		printerr("Could not save ", path, " (", error, ")")
		quit(1)
	else:
		print("saved ", path)


func _make_fonts() -> void:
	var serif_names := PackedStringArray([
		"Noto Serif CJK SC", "Source Han Serif SC", "Noto Serif SC",
		"Songti SC", "STSong", "SimSun", "serif",
	])
	var regular := _system_font(serif_names, 400)
	_save(regular, FONT_DIR + "/ink_serif.tres")

	var bold := _system_font(serif_names, 700)
	_save(bold, FONT_DIR + "/ink_serif_bold.tres")

	var kai_names := PackedStringArray([
		"Kaiti SC", "STKaiti", "KaiTi", "Noto Serif CJK SC", "SimSun", "serif",
	])
	var kai := _system_font(kai_names, 400)
	_save(kai, FONT_DIR + "/ink_kai.tres")

	var kai_bold := _system_font(kai_names, 700)
	_save(kai_bold, FONT_DIR + "/ink_kai_bold.tres")


func _system_font(names: PackedStringArray, weight: int) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = names
	font.font_weight = weight
	font.allow_system_fallback = true
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _make_styleboxes() -> void:
	# The four margins are left, top, right, bottom.
	var boxes := {
		"dialogue_box": _texture_box(ART_PANEL_DIALOG, [360, 30, 250, 28], [396, 50, 270, 36]),
		"name_plate": _texture_box(ART_BUTTON_PRESSED, [56, 24, 56, 24], [68, 12, 68, 18]),
		"button_normal": _texture_box(ART_BUTTON, [72, 26, 72, 26], [84, 16, 84, 22]),
		"button_hover": _texture_box(ART_BUTTON_HOVER, [72, 26, 72, 26], [84, 16, 84, 22]),
		"button_pressed": _texture_box(ART_BUTTON_PRESSED, [56, 24, 56, 24], [68, 16, 68, 22]),
		"button_disabled": _texture_box(
			ART_BUTTON, [72, 26, 72, 26], [84, 16, 84, 22], Color(0.82, 0.80, 0.76, 0.9)),
		# Only choices and the main menu use the gold button art as focus state.
		# A full-texture focus stylebox would cover the content of every other button.
		"button_focus_gold": _texture_box(ART_BUTTON_HOVER, [72, 26, 72, 26], [84, 16, 84, 22]),
		"button_focus": _outline_box(VERMILION, 2, 16, 2, Color(0, 0, 0, 0), [84, 16, 84, 22]),
		"menu_board": _texture_box(ART_PANEL_BOARD, [380, 64, 300, 64], [400, 76, 400, 54]),
		"panel_paper": _texture_box(ART_PANEL_GENERIC, [52, 48, 52, 48], [72, 54, 72, 50]),
		"panel_flat": _flat_box(Color(0.937, 0.878, 0.761, 0.97), 4, 18, 16, 18, 18),
		"game_card_normal": _texture_box(ART_CARD, [190, 24, 190, 24], [216, 14, 216, 18]),
		"game_card_hover": _texture_box(ART_CARD_HOVER, [190, 24, 190, 24], [216, 14, 216, 18]),
		"game_card_pressed": _texture_box(ART_CARD_PRESSED, [190, 24, 190, 24], [216, 14, 216, 18]),
		"document_panel": _texture_box(ART_DOCUMENT, [110, 20, 130, 20], [136, 34, 156, 28]),
		"route_card": _texture_box(ART_ROUTE_CARD, [52, 48, 52, 48], [64, 52, 64, 44]),
		"route_card_selected": _texture_box(ART_ROUTE_CARD_SELECTED, [56, 52, 56, 52], [64, 52, 64, 44]),
		"workspace_dark": _framed_box(
			Color(0.055, 0.085, 0.083, 0.94), Color(0.58, 0.50, 0.36, 0.7), 1, 6, [0, 0, 0, 0]),
		"result_panel": _framed_box(
			Color(0.09, 0.145, 0.145, 0.95), Color(0.40, 0.47, 0.44, 0.9), 1, 4),
		"line_edit": _texture_box(ART_LINE_EDIT, [40, 20, 90, 20], [48, 14, 96, 18]),
		"line_edit_focus": _outline_box(VERMILION, 2, 8, 0, Color(0.94, 0.89, 0.78, 0.55), [48, 14, 96, 18]),
		"progress_background": _flat_box(Color(0.16, 0.13, 0.10, 0.45), 6),
		"progress_fill": _flat_box(Color(0.72, 0.55, 0.28, 0.95), 6),
	}
	for name: String in boxes:
		_save(boxes[name], BOX_DIR + "/" + name + ".tres")


func _texture_box(texture_path: String, texture_margins: Array, content_margins: Array,
		modulate := Color.WHITE) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(texture_path) as Texture2D
	box.texture_margin_left = texture_margins[0]
	box.texture_margin_top = texture_margins[1]
	box.texture_margin_right = texture_margins[2]
	box.texture_margin_bottom = texture_margins[3]
	box.content_margin_left = content_margins[0]
	box.content_margin_top = content_margins[1]
	box.content_margin_right = content_margins[2]
	box.content_margin_bottom = content_margins[3]
	box.modulate_color = modulate
	return box


func _flat_box(fill: Color, radius: int, margin_left := 0, margin_top := 0,
		margin_right := 0, margin_bottom := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin_left
	box.content_margin_top = margin_top
	box.content_margin_right = margin_right
	box.content_margin_bottom = margin_bottom
	box.anti_aliasing = true
	return box


func _framed_box(fill: Color, border: Color, width: int, radius: int,
		content_margins := [20, 16, 20, 16]) -> StyleBoxFlat:
	var box := _flat_box(fill, radius, content_margins[0], content_margins[1],
		content_margins[2], content_margins[3])
	box.border_color = border
	box.set_border_width_all(width)
	return box


func _outline_box(line: Color, width: int, radius: int, grow: int, fill := Color(0, 0, 0, 0),
		content_margins := [0, 0, 0, 0]) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = line
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.set_expand_margin_all(grow)
	box.content_margin_left = content_margins[0]
	box.content_margin_top = content_margins[1]
	box.content_margin_right = content_margins[2]
	box.content_margin_bottom = content_margins[3]
	box.anti_aliasing = true
	return box


func _make_theme() -> void:
	var theme := Theme.new()
	theme.default_font = load(FONT_DIR + "/ink_serif.tres") as Font
	theme.default_font_size = 26

	# Buttons -------------------------------------------------------------
	theme.set_font("font", "Button", load(FONT_DIR + "/ink_serif.tres") as Font)
	theme.set_font_size("font_size", "Button", 32)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color(0.44, 0.15, 0.10))
	theme.set_color("font_pressed_color", "Button", CREAM)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(0.28, 0.25, 0.21, 0.9))
	theme.set_stylebox("normal", "Button", load(BOX_DIR + "/button_normal.tres"))
	theme.set_stylebox("hover", "Button", load(BOX_DIR + "/button_hover.tres"))
	theme.set_stylebox("pressed", "Button", load(BOX_DIR + "/button_pressed.tres"))
	theme.set_stylebox("disabled", "Button", load(BOX_DIR + "/button_disabled.tres"))
	theme.set_stylebox("focus", "Button", load(BOX_DIR + "/button_focus.tres"))

	# Labels and rich text ------------------------------------------------
	theme.set_font("font", "Label", load(FONT_DIR + "/ink_serif.tres") as Font)
	theme.set_font_size("font_size", "Label", 26)
	theme.set_color("font_color", "Label", INK)

	theme.set_font("normal_font", "RichTextLabel", load(FONT_DIR + "/ink_serif.tres") as Font)
	theme.set_font("bold_font", "RichTextLabel", load(FONT_DIR + "/ink_serif_bold.tres") as Font)
	theme.set_font("italics_font", "RichTextLabel", load(FONT_DIR + "/ink_serif.tres") as Font)
	theme.set_font("bold_italics_font", "RichTextLabel", load(FONT_DIR + "/ink_serif_bold.tres") as Font)
	theme.set_font_size("normal_font_size", "RichTextLabel", 26)
	theme.set_font_size("bold_font_size", "RichTextLabel", 26)
	theme.set_font_size("italics_font_size", "RichTextLabel", 26)
	theme.set_font_size("bold_italics_font_size", "RichTextLabel", 26)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_constant("line_separation", "RichTextLabel", 6)

	# Panels and popups ---------------------------------------------------
	for type in ["Panel", "PanelContainer"]:
		theme.set_stylebox("panel", type, load(BOX_DIR + "/panel_flat.tres"))
	for type in ["PopupPanel", "TooltipPanel"]:
		theme.set_stylebox("panel", type, load(BOX_DIR + "/panel_paper.tres"))
	theme.set_font("font", "TooltipLabel", load(FONT_DIR + "/ink_serif.tres") as Font)
	theme.set_font_size("font_size", "TooltipLabel", 24)
	theme.set_color("font_color", "TooltipLabel", INK)

	# Thin ink divider used by the minigame scenes.
	var separator := StyleBoxLine.new()
	separator.color = Color(0.72, 0.62, 0.45, 0.30)
	separator.thickness = 1
	theme.set_stylebox("separator", "HSeparator", separator)

	# Text input ----------------------------------------------------------
	theme.set_font("font", "LineEdit", load(FONT_DIR + "/ink_serif.tres") as Font)
	theme.set_font_size("font_size", "LineEdit", 30)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color(0.36, 0.30, 0.24, 0.65))
	theme.set_color("caret_color", "LineEdit", VERMILION)
	theme.set_color("selection_color", "LineEdit", Color(0.65, 0.22, 0.14, 0.35))
	theme.set_stylebox("normal", "LineEdit", load(BOX_DIR + "/line_edit.tres"))
	theme.set_stylebox("focus", "LineEdit", load(BOX_DIR + "/line_edit_focus.tres"))
	theme.set_stylebox("read_only", "LineEdit", load(BOX_DIR + "/line_edit.tres"))

	# Progress bar (used by Dialogic auto-advance) ------------------------
	theme.set_stylebox("background", "ProgressBar", load(BOX_DIR + "/progress_background.tres"))
	theme.set_stylebox("fill", "ProgressBar", load(BOX_DIR + "/progress_fill.tres"))
	theme.set_color("font_color", "ProgressBar", INK)
	theme.set_font_size("font_size", "ProgressBar", 24)

	_add_minigame_variations(theme)
	_save(theme, THEME_PATH)


func _add_minigame_variations(theme: Theme) -> void:
	# Hub cards use the wide painted banner (boat on the left, pass on the right).
	theme.set_type_variation("GameCard", "Button")
	theme.set_stylebox("normal", "GameCard", load(BOX_DIR + "/game_card_normal.tres"))
	theme.set_stylebox("hover", "GameCard", load(BOX_DIR + "/game_card_hover.tres"))
	theme.set_stylebox("pressed", "GameCard", load(BOX_DIR + "/game_card_pressed.tres"))
	theme.set_stylebox("focus", "GameCard", load(BOX_DIR + "/game_card_hover.tres"))
	theme.set_stylebox("disabled", "GameCard", load(BOX_DIR + "/game_card_normal.tres"))
	theme.set_color("font_color", "GameCard", INK)
	theme.set_color("font_hover_color", "GameCard", INK)
	theme.set_color("font_focus_color", "GameCard", INK)
	theme.set_color("font_pressed_color", "GameCard", INK)

	# Selected pairing chip.
	theme.set_type_variation("ChipSelected", "Button")
	theme.set_stylebox("normal", "ChipSelected", load(BOX_DIR + "/button_hover.tres"))
	theme.set_stylebox("hover", "ChipSelected", load(BOX_DIR + "/button_hover.tres"))
	theme.set_stylebox("pressed", "ChipSelected", load(BOX_DIR + "/button_pressed.tres"))
	theme.set_stylebox("focus", "ChipSelected", load(BOX_DIR + "/button_focus_gold.tres"))
	theme.set_color("font_color", "ChipSelected", INK)
	theme.set_color("font_hover_color", "ChipSelected", INK)
	theme.set_color("font_focus_color", "ChipSelected", INK)
	theme.set_color("font_pressed_color", "ChipSelected", CREAM)
	theme.set_font_size("font_size", "ChipSelected", 22)

	# Revealed quiz answers.
	theme.set_type_variation("AnswerCorrect", "Button")
	theme.set_stylebox("disabled", "AnswerCorrect", load(BOX_DIR + "/button_hover.tres"))
	theme.set_color("font_disabled_color", "AnswerCorrect", INK)
	theme.set_type_variation("AnswerWrong", "Button")
	theme.set_stylebox("disabled", "AnswerWrong", load(BOX_DIR + "/button_pressed.tres"))
	theme.set_color("font_disabled_color", "AnswerWrong", CREAM)

	# Route cards and other parchment surfaces.
	theme.set_type_variation("RouteCard", "PanelContainer")
	theme.set_stylebox("panel", "RouteCard", load(BOX_DIR + "/route_card.tres"))
	theme.set_type_variation("RouteCardSelected", "PanelContainer")
	theme.set_stylebox("panel", "RouteCardSelected", load(BOX_DIR + "/route_card_selected.tres"))
	theme.set_type_variation("DocumentPanel", "PanelContainer")
	theme.set_stylebox("panel", "DocumentPanel", load(BOX_DIR + "/document_panel.tres"))
	theme.set_type_variation("WorkspacePanel", "PanelContainer")
	theme.set_stylebox("panel", "WorkspacePanel", load(BOX_DIR + "/workspace_dark.tres"))
	theme.set_type_variation("ResultPanel", "PanelContainer")
	theme.set_stylebox("panel", "ResultPanel", load(BOX_DIR + "/result_panel.tres"))

	# Feedback text states.
	theme.set_type_variation("FeedbackSuccess", "Label")
	theme.set_color("font_color", "FeedbackSuccess", Color(0.72, 0.94, 0.80))
	theme.set_type_variation("FeedbackFailure", "Label")
	theme.set_color("font_color", "FeedbackFailure", Color(1.0, 0.75, 0.70))


func _export_overrides(overrides: Dictionary) -> Dictionary:
	# Dialogic stores style overrides as strings and parses them with str_to_var().
	var converted := {}
	for key: String in overrides:
		var value: Variant = overrides[key]
		converted[key] = value if value is String else var_to_str(value)
	return converted


func _make_dialogic_style() -> void:
	var style := DialogicStyle.new("水墨")
	style.set_layer_overrides("", _export_overrides({
		"canvas_layer": 1,
		"follow_viewport": false,
		"global_bg_color": Color(1, 1, 1, 1),
		"global_font_color": INK,
		"global_font": FONT_DIR + "/ink_serif.tres",
		"global_font_size": 34,
	}))

	var layers := [
		["10", "Layer_FullBackground/full_background_layer.tscn", {}],
		["11", "Layer_VN_Portraits/vn_portrait_layer.tscn", {}],
		["12", "Layer_Input/full_advance_input_layer.tscn", {}],
		["13", "Layer_VN_Textbox/vn_textbox_layer.tscn", {
			"box_panel": BOX_DIR + "/dialogue_box.tres",
			"box_color_use_global": false,
			"box_color_custom": Color(1, 1, 1, 1),
			"box_size": Vector2(1680, 330),
			"box_margin_bottom": 40,
			"box_animation_in": 2,
			"box_animation_out": 2,
			"box_animation_new_text": 0,
			"text_alignment": 0,
			"text_use_global_size": false,
			"text_size": 34,
			"text_use_global_color": false,
			"text_custom_color": INK,
			"text_use_global_font": true,
			"name_label_use_global_color": false,
			"name_label_custom_color": CREAM,
			"name_label_use_character_color": false,
			"name_label_use_global_font": false,
			"name_label_font": FONT_DIR + "/ink_kai_bold.tres",
			"name_label_use_global_font_size": false,
			"name_label_custom_font_size": 34,
			"name_label_box_panel": BOX_DIR + "/name_plate.tres",
			"name_label_box_use_global_color": false,
			"name_label_box_modulate": Color(1, 1, 1, 1),
			"name_label_alignment": 0,
			"name_label_box_offset": Vector2(320, 0),
			"next_indicator_enabled": true,
			"next_indicator_show_on_questions": true,
			"next_indicator_show_on_autoadvance": false,
			"next_indicator_animation": 0,
			"next_indicator_texture": ART_NEXT_INDICATOR,
			"next_indicator_size": Vector2(30, 42),
			"next_indicator_position_offset": Vector2(-46, -58),
			"autoadvance_progressbar": true,
			"typing_sounds_enabled": false,
		}],
		["14", "Layer_Glossary/glossary_popup_layer.tscn", {
			"box_modulate_mode": 1,
			"box_base_modulate": Color(1, 1, 1, 1),
		}],
		["15", "Layer_VN_Choices/vn_choice_layer.tscn", {
			"font_use_global": true,
			"font_size_use_global": false,
			"font_size_custom": 34,
			"text_color_use_global": false,
			"text_color_custom": INK,
			"text_color_pressed": CREAM,
			"text_color_hovered": INK,
			"text_color_disabled": Color(0.38, 0.34, 0.29, 0.8),
			"text_color_focused": INK,
			"boxes_stylebox_normal": BOX_DIR + "/button_normal.tres",
			"boxes_stylebox_hovered": BOX_DIR + "/button_hover.tres",
			"boxes_stylebox_pressed": BOX_DIR + "/button_pressed.tres",
			"boxes_stylebox_disabled": BOX_DIR + "/button_disabled.tres",
			"boxes_stylebox_focused": BOX_DIR + "/button_focus_gold.tres",
			"boxes_v_separation": 18,
			"boxes_fill_width": true,
			"boxes_min_size": Vector2(820, 86),
			"boxes_offset": Vector2.ZERO,
		}],
		["16", "Layer_TextInput/text_input_layer.tscn", {}],
		["17", "Layer_History/history_layer.tscn", {
			"font_use_global_size": false,
			"font_custom_size": 26,
			"font_use_global_fonts": true,
		}],
	]

	for layer in layers:
		style.add_layer(DIALOGIC_DEFAULT_PARTS + layer[1], _export_overrides(layer[2]), layer[0])

	_save(style, STYLE_PATH)

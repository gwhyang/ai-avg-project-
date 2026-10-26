# UI 配置说明（水墨主题）

本轮把 `Asset/ui/` 里已切好的界面素材接入到引擎与 Dialogic，原则是：

- 能用 Dialogic 内置布局层与 Style 系统解决的，就只写 overrides，不新造一套对话框系统。
- 通用控件（按钮、面板、输入框、提示框、进度条）走 Godot `Theme`，场景只做局部覆盖。
- 主菜单用 `Control` / `PanelContainer` / `VBoxContainer` 等引擎容器搭，不写自绘代码。
- 九宫格边界、内容边距集中维护，方便美术以后用同名文件替换切图。

## 目录

```text
UI/
  Fonts/                      SystemFont 字体资源（宋体/楷体，含中文回退栈）
  StyleBoxes/                 九宫格 StyleBoxTexture / StyleBoxFlat
  Theme/ink_theme.tres        全局主题（project.godot -> gui/theme/custom）
  Dialogic/ink_wash_style.tres Dialogic 样式（默认样式，8 个内置层）
tools/
  build_ui_resources.gd       从切图批量生成上述资源
  validate_ui.gd              校验主题、样式、运行时对话框
  capture_ui.gd               截图主菜单/对话/选项/小游戏，输出到 user://
```

## 素材映射

所有素材都来自 `Asset/ui/{panels,buttons,widgets,papers,icons}/`，没有使用 `_reference_sheets/` 原图。

| 用途 | 切图 | 九宫格边距（左/上/右/下） | 内容边距 | 资源 |
| --- | --- | --- | --- | --- |
| VN 对话框 | `panels/panel_002.png` | 360 / 30 / 250 / 28 | 396 / 50 / 270 / 36 | `StyleBoxes/dialogue_box.tres` |
| 说话人名牌 | `buttons/button_009.png`（红底金云角） | 56 / 24 / 56 / 24 | 68 / 12 / 68 / 18 | `StyleBoxes/name_plate.tres` |
| 按钮悬停 | `buttons/button_008.png`（金） | 72 / 26 / 72 / 26 | 84 / 16 / 84 / 22 | `button_hover.tres` |
| 按钮按下 | `buttons/button_009.png`（红） | 56 / 24 / 56 / 24 | 68 / 16 / 68 / 22 | `button_pressed.tres` |
| 按钮正常 | `buttons/button_006.png`（蓝） | 72 / 26 / 72 / 26 | 84 / 16 / 84 / 22 | `button_normal.tres` |
| 主菜单卷轴板 | `panels/panel_001.png` | 380 / 64 / 300 / 64 | 400 / 76 / 400 / 54 | `menu_board.tres` |
| 通用小面板 / 提示框 | `widgets/widget_001.png` | 52 / 48 / 52 / 48 | 72 / 54 / 72 / 50 | `panel_paper.tres` |
| 小游戏大厅卡片 | `buttons/button_001.png` / `003` 金 / `004` 红 | 190 / 24 / 190 / 24 | 216 / 14 / 216 / 18 | `game_card_normal/hover/pressed.tres` |
| 小游戏公文纸 | `papers/paper_010.png` | 110 / 20 / 130 / 20 | 136 / 34 / 156 / 28 | `document_panel.tres` |
| 路线卡 | `widgets/widget_001.png` | 52 / 48 / 52 / 48 | 64 / 52 / 64 / 44 | `route_card.tres` |
| 路线卡选中 | `widgets/widget_002.png`（金框） | 56 / 52 / 56 / 52 | 64 / 52 / 64 / 44 | `route_card_selected.tres` |
| 单行输入框 | `papers/paper_007.png` | 40 / 20 / 90 / 20 | 48 / 14 / 96 / 18 | `line_edit.tres` |
| 下一句指示 | `icons/icon_011.png`（红三角） | — | Dialogic 尺寸 30×42 | `ink_wash_style.tres` |
| 主菜单 / 大厅分隔线 | `icons/icon_035.png` | — | 场景内 520×46 / 640×46 | `Main.tscn`、`PrototypeHub.tscn` |

补充说明：

- 对话框左右需要保留画面（左：竹与楼阁，右：批信与流苏），所以九宫格左右边距很大，正文实际可写区约 1014×244（34px 字号约 5 行）。
- 面板类没有强行用大图拉伸：主菜单与对话框用专门九宫格切图，普通 `PanelContainer` 用纸色 `StyleBoxFlat`，小游戏的工作区/结果框用深墨色 `StyleBoxFlat`；路线卡、公文纸、提示框各自用对应切图。
- 进度条（Dialogic 自动播放指示）用 `StyleBoxFlat`，因为它在场景里只有 10px 高，直接套切图会被九宫格边界裁切。
- 按钮焦点态分两种：
  - 全局主题用细描边（`button_focus.tres`），避免整张金色按钮图盖住其他深色按钮的内容；
  - 主菜单按钮、Dialogic 选项、小游戏卡片用金色按钮图（`button_focus_gold.tres` / `game_card_hover`），因为这几处按钮本来就是同一套切图。

## 字体

`UI/Fonts/` 下是 `SystemFont` 资源，按优先级回退：

- 正文 / 界面：Noto Serif CJK SC → 思源宋体 → Songti SC → STSong → SimSun → serif
- 标题 / 名牌：Kaiti SC → STKaiti → KaiTi → 宋体回退

不把字体文件打进工程（当前导出目标是 Windows 与 Android，两者都有中文字体）。如果以后增加 Web 导出，需要在工程内嵌一份可再分发的中文字体，并把 `ink_serif*.tres`、`ink_kai*.tres` 换成 `FontFile`，否则浏览器端会缺字。

## 全局主题

`project.godot`：

```ini
[gui]
theme/custom="res://UI/Theme/ink_theme.tres"
```

主题覆盖：

- `Button`：切图 normal / hover / pressed / disabled，字体、字号、字色、焦点描边
- `Label` / `RichTextLabel`：宋体、墨色、行距
- `Panel` / `PanelContainer`：纸色 `StyleBoxFlat`
- `TooltipPanel` / `PopupPanel`：`widget_001` 小面板
- `LineEdit`：`paper_007` 纸条 + 焦点描边
- `ProgressBar`：半透明墨底 + 金棕填充
- `HSeparator`：细金线
- `TooltipLabel`

### 小游戏用的类型变体

`ink_theme.tres` 里还定义了以下 Theme type variation，场景里只写 `theme_type_variation`，不写样式覆盖：

| 变体 | 基类 | 用途 |
| --- | --- | --- |
| `GameCard` | Button | 大厅卷轴卡片（正常/悬停/焦点=金） |
| `ChipSelected` | Button | 配对已选中的隐语/含义 |
| `AnswerCorrect` / `AnswerWrong` | Button | 答题后揭晓的金/红禁用态 |
| `RouteCard` / `RouteCardSelected` | PanelContainer | 路线卡与选中金框 |
| `DocumentPanel` | PanelContainer | 公文纸 |
| `WorkspacePanel` / `ResultPanel` | PanelContainer | 深墨工作区 / 结果框 |
| `FeedbackSuccess` / `FeedbackFailure` | Label | 答题反馈字色 |

## Dialogic 样式

`project.godot` 中：

```ini
layout/style_list=["res://UI/Dialogic/ink_wash_style.tres"]
layout/default_style="res://UI/Dialogic/ink_wash_style.tres"
layout/style_directory={
"水墨": "res://UI/Dialogic/ink_wash_style.tres"
}
```

`ink_wash_style.tres` 沿用 Dialogic 内置的 8 个布局层（背景、立绘、输入、文本框、名词解释、选项、文本输入、历史），只写覆盖项：

- 基础层：全局字体 34、墨色、白色叠色
- 文本框（13）：`box_panel` 用 `panel_002`；名字牌用 `button_009`，楷体粗体 34；正文 34、左对齐；淡入上浮 / 淡出下沉；下一句指示 `icon_011`；关闭打字音
- 选项（15）：同一套蓝 / 金 / 红按钮切图，820×86，间距 18，深墨字色，保持 Dialogic 默认按钮音效
- 名词解释（14）：白色叠色，继承内置面板
- 历史（17）：字号 26，字体沿用全局宋体
- 文本输入（16）：继承内置层，输入框样式来自全局主题

要换美术时，优先覆盖 `Asset/ui/` 下的同名文件；若新图比例变化，改 `tools/build_ui_resources.gd` 顶部的路径与边距常量后重跑：

```bash
godot --headless --path . --script res://tools/build_ui_resources.gd
```

注意：重跑会覆盖在检查器里对 `UI/` 下 .tres 的手工改动。

## 主菜单

`Scenes/Main.tscn`：

- 背景 `Asset/sprite/bg/13.png` + 压暗层
- 居中的卷轴板 `PanelContainer`（`menu_board.tres`），尺寸随视口宽度伸缩、高度固定 440，九宫格只横向拉伸，卷轴左下的帆船不会被纵向拉变形
- 标题「一纸千山」楷体 80；副标题「一封未能寄出的家书」30；`icon_035` 分隔线
- 开始 / 退出按钮使用全局按钮切图，焦点态为金色按钮图
- 底部小字说明赛事与题材
- `Main.gd` 只保留开始故事 / 返回菜单的流程逻辑，节点用 `%` 唯一名引用

## 小游戏 UI

`Minigames/` 是独立试玩，不参与主线。上一版的小游戏界面直接在脚本里 `new` 控件；这一版全部改成“场景负责布局、脚本负责数据与状态、Theme 负责样式”：

| 场景 | 布局内容 | 脚本职责 |
| --- | --- | --- |
| `PrototypeHub.tscn` | 背景、压暗、标题、分隔线、卡片滚动区、页脚 | 只把 `GAMES` 数据填进 `GameCard.tscn`，处理打开/返回 |
| `GameCard.tscn` | 卷轴卡 `GameCard` 变体 + 序号/标题/章节标签 | 填充一条游戏数据 |
| `Quiz.tscn` | 返回/序号、标题、章节、深墨工作区、公文纸、题面、固定 A/B/C 选项、反馈、重试/重开/继续剧情 | 按 `QuizData` 填文本，处理答题状态与奖励 |
| `Pairing.tscn` | 两组“隐语/实际传递内容”静态布局、状态栏、提交/重开/继续剧情、`Links` 连线层 | 绑定两组数据、选中态、对错判定、连线坐标 |
| `Route.tscn` | 标题、路线滚动区、结果框、状态、重开/确认路线 | 实例化 `RouteCard.tscn`，处理选中与结果 |
| `RouteCard.tscn` | 路线卡 `RouteCard` 变体 + 路线名/说明/取舍/选择按钮 | 填充一条路线数据，切换选中变体 |

美术接入：

- 大厅卡片用 `button_001/003/004` 的宽幅帆船/关楼画，正好按原生 864×147 比例放在 882×148 卡片里，不做纵向拉伸。
- 公文纸用 `paper_010`（两端梅花、带横线的撕纸），`Quiz` 的批信与题目文本落在纸面内。
- 路线卡用 `widget_001`，选中时换成 `widget_002` 金框；卡片文字用深墨色，按钮仍用全局蓝/金/红切图。
- 配对按钮沿用全局按钮切图，选中态用 `ChipSelected`（金色）。
- 工作区与结果框是深墨 `StyleBoxFlat`，只用细金线分隔，不再写一整套 `StyleBoxFlat` 在脚本里。

交互状态都走 Theme 变体：`AnswerCorrect/AnswerWrong`、`ChipSelected`、`RouteCardSelected`、`FeedbackSuccess/Failure`；脚本只切换 `theme_type_variation` 或改文本，不拼 UI。

## 小游戏接入主线

- autoload `Minigames` → `Minigames/MinigameBridge.gd`
- Timeline 用 `do Minigames.run("reading")` 调用；Dialogic call 事件会 await，剧情停在小游戏
- 桥接层用 `CanvasLayer(layer=50)` 盖在 Dialogic 布局上，完成后释放；不暂停背景音乐
- 结果写入 `minigame_success / minigame_retried / minigame_reward / minigame_choice`
- Timeline 再用 `set {shunbo_trust} += {minigame_reward}` 结算，重试成功为半额（7.5 存 float）
- 剧情模式隐藏返回/重新开始，成功/选定路线后显示「继续剧情 / 确认路线」；Esc 不会跳过剧情节点

接入点、八个 id 与奖励表见 `Minigames/README.md`。小游戏剧情模式截图见 `tools/capture_ui.gd` 的 `ui_story_quiz*`。

## 验证

```bash
# 主题 / 样式 / 运行时对话框断言
godot --headless --path . --script res://tools/validate_ui.gd

# 小游戏剧情模式、桥接变量与 Timeline 接入点
godot --headless --path . --script res://tools/validate_story_flow.gd

# 原有流程回归
godot --headless --path . --script res://tools/validate_main.gd
godot --headless --path . --script res://tools/validate_dialogic.gd
godot --headless --path . --script res://tools/validate_minigames.gd
godot --headless --path . --script res://tools/validate_music.gd

# 目视检查（需要真实渲染，不能用 --headless）
godot --path . --script res://tools/capture_ui.gd
```

`capture_ui.gd` 会输出 `user://ui_menu.png`、`ui_dialogue.png`、`ui_speaker.png`、`ui_choices.png`、`ui_hub.png`、`ui_quiz.png`、`ui_quiz_answer.png`、`ui_pairing.png`、`ui_pairing_selected.png`、`ui_route.png`、`ui_route_selected.png`、`ui_story_quiz.png`、`ui_story_quiz_done.png`。

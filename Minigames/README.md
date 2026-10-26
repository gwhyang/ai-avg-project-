# 小游戏

两种入口：

- **独立试玩**：在 Godot 中打开 `res://Minigames/PrototypeHub.tscn`，按 F6。大厅包含八个主题小游戏，可重试或返回大厅。
- **主线剧情**：Timeline 在对应剧情点通过 `do Minigames.run("id")` 调用，完成后自动回到时间线并结算。

## 剧情接入

桥接层是 autoload `Minigames`（`Minigames/MinigameBridge.gd`）。Timeline 里写：

```text
do Minigames.run("reading")
```

Dialogic 的 call 事件会 `await` 这个方法，所以剧情会停在小游戏上。玩家完成并按下「继续剧情 / 确认路线」后，桥接层写入：

| 变量 | 类型 | 含义 |
| --- | --- | --- |
| `minigame_success` | bool | 是否完成（剧情模式下必须成功才能继续） |
| `minigame_retried` | bool | 是否重试过 |
| `minigame_reward` | float | 本次奖励，重试成功为半额 |
| `minigame_choice` | int | 路线选择 0/1/2，其它小游戏为 -1 |

Timeline 再按目标数值变量结算，例如：

```text
if {minigame_reward} > 0:
	set {shunbo_trust} += {minigame_reward}
	if {shunbo_trust} > 100:
		set {shunbo_trust} = 100
```

八个接入点：

| id | 场景 | 结算变量 | 首次 / 重试 |
| --- | --- | --- | --- |
| `reading` 批文解读 | `Quiz.tscn` | `shunbo_trust` | +15 / +7.5 |
| `pairing` 隐语配对 | `Pairing.tscn` | `shunbo_trust` | +10 / +5 |
| `envelope` 批封辨识 | `Quiz.tscn` | `shunbo_trust` | +10 / +5 |
| `counting` 银两清点 | `Quiz.tscn` | `shunbo_trust` | +10 / +5 |
| `route` 送批路线 | `Route.tscn` | `shunbo_trust` | 水路 +5，其它 0 |
| `relief` 救国批甄别 | `Quiz.tscn` | `aquanbo_bond` | +10 / +5 |
| `forgery` 识破伪信 | `Quiz.tscn` | `shunbo_trust` | +10 / +5 |
| `restoration` 批文还原 | `Quiz.tscn` | — | 0（无数值奖励） |

剧情模式下：

- 隐藏「返回 / 重新开始」，避免跳过未完成的剧情节点
- 答题正确 / 配对成功 / 选定路线后显示「继续剧情 / 确认路线」，由玩家确认后再回时间线
- 错误答案仍可「再试一次」，重试成功按半额结算
- Esc 不会退出剧情模式的小游戏

独立试玩（`PrototypeHub`）不经过桥接层，不写 Dialogic 变量。

## 界面结构

界面不再在脚本里 `new` 控件。布局在 `.tscn`，样式在 `UI/Theme/ink_theme.tres`，脚本只处理数据、选中态与判定：

- `PrototypeHub.tscn`：大厅骨架；卡片由 `GameCard.tscn` 实例化
- `GameCard.tscn`：卷轴卡（`button_001/003/004` 切图）
- `Quiz.tscn`：批文解读类页面；选项固定 A/B/C，答题状态用 `AnswerCorrect/AnswerWrong` 主题变体
- `Pairing.tscn`：两组配对、`Links` 连线层；选中用 `ChipSelected` 主题变体
- `Route.tscn`：路线选择页；路线卡由 `RouteCard.tscn` 实例化，选中用 `RouteCardSelected`
- `RouteCard.tscn`：路线卡（`widget_001/002` 切图）

新增界面时优先复用主题变体与 `UI/StyleBoxes`，不要在脚本里拼布局。

## 待定规则

- 重试半额目前按 `7.5` 存入 Dialogic 变量（float），不做取整；若后续关系值要求整数，应统一在结算处取整并同步小游戏显示。
- 送批路线没有标准答案。官道只显示盘查和批银损失风险，不擅自确定损失概率或数额；山道显示体力消耗，不新增体力变量；水路结算顺伯信任 +5。
- 批封辨识的剧本要求检查日期，但候选批封没有日期信息；试玩只依据剧本写出的款项、落款与印章判定。
- 批文还原没有数值奖励。原剧本画了八个空格，但三个候选句均为七字，试玩界面按答案长度画七格。
- 尾声展厅的扫码与接力写批是附录列出的第九项互动，尚缺二维码目标、故事数据和数字批封规则，不属于当前八项主题小游戏。
- 小游戏进行中若存档/读档，时间线会从 call 事件重来；当前没有把“小游戏进行中”做进存档状态。

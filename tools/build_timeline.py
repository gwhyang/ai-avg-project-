"""Build chapter-sized Dialogic timelines from the approved screenplay.

The branching structure is explicit here; prose is read from the screenplay so
later copy edits do not require retyping hundreds of dialogue events.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "_docs" / "【第3版】一纸千山-江门五邑版完整剧本.md"
TIMELINES_DIR = ROOT / "Timelines"
SEGMENTS = (
    ("timeline", "start"),
    ("chapter_1", "chapter_1"),
    ("chapter_2", "chapter_2"),
    ("chapter_3", "chapter_3"),
    ("chapter_4", "chapter_4"),
    ("chapter_5", "chapter_5"),
    ("postwar", "postwar"),
    ("ending_return", "ending_return"),
    ("ending_steadfast", "ending_steadfast"),
    ("ending_south", "ending_south"),
    ("ending_relief", "ending_relief"),
    ("ending_unfinished", "ending_unfinished"),
    ("modern", "modern"),
)

SPEAKERS = {
    "阿棠": "atang",
    "林灯": "lindeng",
    "顺伯": "shunbo",
    "阿妹": "amei",
    "阿全伯": "aquanbo",
    "赖四": "laisi",
    "陈顺成": "chenshuncheng",
    "奶奶": "grandma_lindeng",
    "李寡妇": "widow_li",
    "邻乡老人": "elder_villager",
    "伪兵": "soldier",
}

HEADING = re.compile(r"^#{1,2}\s+\*\*(.+?)\*\*")
SPEECH = re.compile(r"^([^：（:]{1,12})(?:（([^）]*)）)?[：:](.+)$")
SPEECH_WITHOUT_COLON = re.compile(r"^([^：（:]{1,12})（([^）]*)）(.+)$")
BG_NUMBER = re.compile(r"对应bg(\d+)")
ANNOTATION = re.compile(r"【[^】]*】")


def load_sections() -> list[tuple[str, list[str]]]:
    sections: list[tuple[str, list[str]]] = []
    for raw in SOURCE.read_text(encoding="utf-8").splitlines():
        heading = HEADING.match(raw)
        if heading:
            sections.append((heading.group(1).strip(), []))
        elif sections:
            sections[-1][1].append(raw.rstrip())
    return sections


SECTIONS = load_sections()


def section(prefix: str) -> list[str]:
    matches = [body for title, body in SECTIONS if title.startswith(prefix)]
    if len(matches) != 1:
        raise ValueError(f"Expected one section for {prefix!r}; found {len(matches)}")
    return matches[0]


def cut_before(lines: list[str], needle: str) -> list[str]:
    for index, line in enumerate(lines):
        if needle in line:
            return lines[:index]
    raise ValueError(f"Missing section boundary: {needle}")


def cut_after(lines: list[str], needle: str) -> list[str]:
    for index, line in enumerate(lines):
        if needle in line:
            return lines[index + 1 :]
    raise ValueError(f"Missing section boundary: {needle}")


def between(lines: list[str], start: str, end: str) -> list[str]:
    return cut_before(cut_after(lines, start), end)


def chunks(text: str, limit: int = 82) -> list[str]:
    sentences = re.split(r"(?<=[。！？；])", text)
    result: list[str] = []
    current = ""
    for sentence in sentences:
        while len(sentence) > limit:
            split_at = sentence.rfind("，", 0, limit)
            if split_at < limit // 3:
                split_at = limit - 1
            part, sentence = sentence[: split_at + 1], sentence[split_at + 1 :]
            if current:
                result.append(current)
                current = ""
            result.append(part)
        if current and len(current) + len(sentence) > limit:
            result.append(current)
            current = ""
        current += sentence
    if current:
        result.append(current)
    return [part.strip() for part in result if part.strip()]


class Timeline:
    def __init__(self) -> None:
        self.lines: list[str] = []
        self.visible: dict[str, str] = {}
        self.era = "modern"

    def add(self, text: str = "", depth: int = 0) -> None:
        self.lines.append("\t" * depth + text if text else "")

    def label(self, name: str, title: str = "") -> None:
        self.add()
        if title:
            self.add(f"# {title}")
        self.add(f"label {name}")
        self.add("leave --All--")
        self.visible.clear()

    def jump(self, name: str, depth: int = 0) -> None:
        self.add(f"jump {name}", depth)

    def choice(self, text: str, target: str, condition: str = "") -> None:
        suffix = f" | [if {condition}]" if condition else ""
        self.add(f"- {text}{suffix}")
        self.jump(target, 1)

    def set(self, name: str, value: str, depth: int = 0) -> None:
        self.add(f"set {{{name}}} = {value}", depth)

    def stat(self, name: str, amount: int, depth: int = 0) -> None:
        sign = "+=" if amount >= 0 else "-="
        self.add(f"set {{{name}}} {sign} {abs(amount)}", depth)
        if amount >= 0:
            self.add(f"if {{{name}}} > 100:", depth)
            self.set(name, "100", depth + 1)
        else:
            self.add(f"if {{{name}}} < 0:", depth)
            self.set(name, "0", depth + 1)

    def say(self, text: str, speaker: str = "", depth: int = 0) -> None:
        if not text.strip():
            return
        portrait_speaker = speaker and not (
            self.era == "past" and speaker == "lindeng"
        ) and speaker != "grandma_lindeng"
        if portrait_speaker:
            position = "left" if speaker in {"atang", "lindeng"} else "right"
            previous = self.visible.get(position)
            if previous != speaker:
                if previous:
                    self.add(f"leave {previous}", depth)
                self.add(f"join {speaker} ({'normal'}) {position}", depth)
                self.visible[position] = speaker
        for part in chunks(text):
            part = part.replace(":", r"\:").replace("|", r"\|")
            self.add(f"{speaker}: {part}" if speaker else part, depth)

    def bg(self, number: int, depth: int = 0) -> None:
        self.add("leave --All--", depth)
        self.visible.clear()
        self.add(f'[background arg="res://Asset/sprite/bg/{number}.png"]', depth)

    def story(self, lines: list[str], depth: int = 0) -> None:
        for raw in lines:
            line = raw.strip().replace("**", "")
            if not line:
                continue
            if line.startswith(("【BG：", "【BG】")):
                match = BG_NUMBER.search(line)
                if not match:
                    raise ValueError(f"Background has no image mapping: {line}")
                number = int(match.group(1))
                if "江门侨乡老宅，傍晚" in line:
                    number = 13
                elif "雨还没有停下，批局内" in line or "雨夜，阿棠独自跪" in line:
                    number = 6
                elif "战后侨乡，断壁残垣" in line:
                    number = 12
                self.bg(number, depth)
                continue
            if line.startswith("【林灯·意识回响】"):
                self.say(line.removeprefix("【林灯·意识回响】"), "lindeng", depth)
                continue
            if line.startswith("【字幕】"):
                self.say(line.removeprefix("【字幕】"), depth=depth)
                continue
            if line.startswith("【对应bg"):
                continue
            if line.startswith((
                "【BGM", "【SE", "【特写", "【CG", "【橙光", "【指令", "【判定",
                "【数值", "【跳转", "【解锁", "【返回", "【条件", "【前置",
                "【剧情", "【弹出", "【开启", "【信件虚拟投影",
            )):
                continue
            if line.startswith((
                "选项", "路线", "批封甲", "批封乙", "批封丙", "批信一", "批信二",
                "批信三", "破绽选项", "触发条件", "问：", "A：", "B：", "C：",
                "A【", "B【", "（正确答案", "（选择A）", "（选择B）",
                "①", "②", "③", "④", "if（", "else {", "\\#", "{", "}",
                "对应bg", "硬性条件全部达成",
            )):
                continue
            if line.startswith("【") and line.endswith("】"):
                line = line[1:-1]
            line = ANNOTATION.sub("", line).strip()
            line = line.removeprefix("剧情后续：").strip()
            if not line:
                continue
            speech = SPEECH.match(line) or SPEECH_WITHOUT_COLON.match(line)
            if speech and speech.group(1) in SPEAKERS:
                direction = speech.group(2)
                text = speech.group(3).strip()
                if direction:
                    text = f"（{direction}）{text}"
                self.say(text, SPEAKERS[speech.group(1)], depth)
            else:
                self.say(line, depth=depth)

    def placeholder(self, name: str, award: tuple[str, int] | None = None) -> None:
        self.add(f"# TODO mini-game: {name}; auto-complete during story-only build")
        if award:
            self.stat(*award)

    def save(self) -> None:
        label_positions = {
            match.group(1): index
            for index, line in enumerate(self.lines)
            if (match := re.fullmatch(r"label (\w+)", line))
        }
        label_count = sum(bool(re.fullmatch(r"label \w+", line)) for line in self.lines)
        if len(label_positions) != label_count:
            raise ValueError("Duplicate timeline label")
        boundaries = []
        for identifier, root_label in SEGMENTS:
            if root_label not in label_positions:
                raise ValueError(f"Missing segment root: {root_label}")
            start = label_positions[root_label]
            if start > 0 and self.lines[start - 1].startswith("# "):
                start -= 1
            if start > 0 and not self.lines[start - 1]:
                start -= 1
            boundaries.append((identifier, start))
        if boundaries[0][1] != 0 or any(
            left[1] >= right[1] for left, right in zip(boundaries, boundaries[1:])
        ):
            raise ValueError("Timeline segment boundaries are out of order")

        segments = {}
        label_owner = {}
        for index, (identifier, start) in enumerate(boundaries):
            end = boundaries[index + 1][1] if index + 1 < len(boundaries) else len(self.lines)
            segments[identifier] = self.lines[start:end]
            for line in segments[identifier]:
                if match := re.fullmatch(r"label (\w+)", line):
                    label_owner[match.group(1)] = identifier

        for identifier, lines in segments.items():
            rendered = []
            for line in lines:
                jump = re.fullmatch(r"(?P<indent>\s*)jump (?P<label>\w+)", line)
                if jump:
                    target = jump.group("label")
                    if target not in label_owner:
                        raise ValueError(f"Unknown jump target: {target}")
                    if label_owner[target] != identifier:
                        line = f"{jump.group('indent')}jump {label_owner[target]}/{target}"
                background = re.search(r'\[background arg="res://([^\"]+)"\]', line)
                if background and not (ROOT / background.group(1)).is_file():
                    raise ValueError(f"Missing background: {background.group(1)}")
                rendered.append(line)
            (TIMELINES_DIR / f"{identifier}.dtl").write_text(
                "\n".join(rendered).rstrip() + "\n", encoding="utf-8"
            )


def build() -> None:
    t = Timeline()
    t.label("start", "序章：迟到的批")
    for variable in ("shunbo_trust", "amei_affection", "aquanbo_bond", "father_roll", "batch_loss_count"):
        t.set(variable, "0")
    for variable in ("used_batch_money", "joined_relief_batch", "father_letter", "widow_li_batch_lost"):
        t.set(variable, "false")
    t.story(section("序章·现代"))
    t.choice("小心翼翼拆开批信", "prologue_open")
    t.choice("先拍照建档", "prologue_photo")
    t.label("prologue_open")
    t.story(section("选项1 · 小心翼翼拆开批信"))
    t.jump("chapter_1")
    t.label("prologue_photo")
    t.story(section("选项2 · 先拍照建档"))
    t.jump("chapter_1")

    t.label("chapter_1", "第一章：入局")
    t.era = "past"
    t.story(section("第一章·入局"))
    t.choice("为父寻亲", "first_father")
    t.choice("为家生计", "first_livelihood")
    t.choice("为护阿妹", "first_amei")
    for label, title, award in (
        ("first_father", "选项1 · 为父寻亲", ("aquanbo_bond", 10)),
        ("first_livelihood", "选项2 · 为家生计", ("shunbo_trust", 10)),
        ("first_amei", "选项3 · 为护阿妹", ("amei_affection", 10)),
    ):
        t.label(label)
        t.stat(*award)
        t.story(section(title))
        t.jump("chapter_1_merge")
    t.label("chapter_1_merge")
    t.story(section("分支统一汇合剧情"))
    t.jump("chapter_2")

    t.label("chapter_2", "第二章：学批")
    t.story(cut_before(section("第二章·学批"), "【指令：批文解读玩法"))
    t.placeholder("批文解读", ("shunbo_trust", 15))
    t.story(section("答对 B · 港币二百元"))
    t.placeholder("隐语配对", ("shunbo_trust", 10))
    t.say("阿棠一一配对，越对越顺，终于把隐语的规矩彻底刻进心里。")
    t.story(cut_after(section("小游戏一 · 隐语配对"), "（正确答案："))
    t.placeholder("批封辨识", ("shunbo_trust", 10))
    t.say("阿棠端详片刻，指尖点在批封乙上。")
    t.story(cut_after(section("小游戏二·批封辨识"), "（正确答案："))
    t.story(section("日常小支线·阿妹来探"))
    t.jump("chapter_3")

    t.label("chapter_3", "第三章：送批")
    t.story(section("第三章·送批"))
    t.placeholder("银两清点", ("shunbo_trust", 10))
    t.story(cut_after(section("小游戏三·银两清点"), "【判定】"))
    t.placeholder("送批路线选择")
    t.say("阿棠背着包裹走上乡间土路。走到半山腰岔路口，路边灌木丛猛地窜出几个人。赖四一身灰布汉奸短打，嘴角挂着狞笑，身后跟着两个手持木棍的跟班，拦死整条小路。")
    t.story(cut_after(section("小游戏四·送批路线选择"), "【特写：赖四"))
    t.choice("冒险保批", "ambush_defend")
    t.choice("藏批待机", "ambush_hide")
    t.choice("冒险求援", "ambush_help")
    for label, title, updates in (
        ("ambush_defend", "分支1 · 冒险保批", (("shunbo_trust", -10), ("amei_affection", -5))),
        ("ambush_hide", "分支2 · 藏批待机", (("shunbo_trust", 10),)),
        ("ambush_help", "分支3 · 冒险求援", (("aquanbo_bond", 15), ("shunbo_trust", -5))),
    ):
        t.label(label)
        for update in updates:
            t.stat(*update)
        if label == "ambush_defend":
            t.stat("batch_loss_count", 1)
            t.set("widow_li_batch_lost", "true")
        t.story(section(title))
        t.jump("ambush_merge")
    t.label("ambush_merge")
    merge = section("三条分支统一汇合剧情")
    t.story(cut_before(merge, "阿妹（眼神骤然慌张"))
    t.add("join amei (normal) right")
    t.visible["right"] = "amei"
    t.add("if {batch_loss_count} > 0:")
    t.say("你的肩膀在渗血！路上真遇上歹人了？", "amei", 1)
    t.add("else:")
    t.say("你回来了。我坐在门口等你，心里一直不安。", "amei", 1)
    t.say("祖母卧病在床，家里野菜吃完，已经断粮两日。", "amei")
    t.story(between(merge, "阿妹（眼神骤然慌张", "选项A【绝不挪用"))
    t.choice("绝不挪用他人批银，用自己的工钱接济", "refuse_misuse")
    t.choice("偷偷挪一小部分批银救急", "misuse")
    t.label("refuse_misuse")
    t.set("used_batch_money", "false")
    t.stat("shunbo_trust", 20)
    t.story(section("选择 A · 绝不挪用他人批银"))
    t.jump("chapter_4")
    t.label("misuse")
    t.set("used_batch_money", "true")
    t.stat("shunbo_trust", -30)
    t.story(section("选择 B · 偷偷挪一小部分"))
    t.jump("chapter_4")

    t.label("chapter_4", "第四章：家国")
    t.story(section("第四章·家国"))
    t.choice("参与秘密运送救国批", "join_relief")
    t.choice("固守普通家书", "decline_relief")
    t.label("join_relief")
    t.set("joined_relief_batch", "true")
    t.stat("aquanbo_bond", 20)
    t.story(section("分支1 · 参与秘密运送救国批"))
    t.placeholder("救国批甄别", ("aquanbo_bond", 10))
    t.story(cut_after(section("小游戏五 · 救国批甄别"), "【橙光判定】"))
    t.jump("chapter_5")
    t.label("decline_relief")
    t.set("joined_relief_batch", "false")
    t.story(section("分支2 · 固守普通家书"))
    t.jump("chapter_5")

    t.label("chapter_5", "第五章：抉择")
    t.story(section("第五章·抉择"))
    t.placeholder("识破伪信", ("shunbo_trust", 10))
    t.say("阿棠瞥见墨迹在灯光下微微反光，心里顿时有了底。")
    t.story(between(section("小游戏六 · 识破伪信"), "（正确答案：", "【前置条件自动判定】"))
    t.choice("坚守诚信硬抗", "final_resist")
    t.choice("虚与委蛇周旋", "final_delay")
    t.choice("被迫妥协", "final_compromise")
    t.label("final_resist")
    t.story(section("选项1 · 坚守诚信硬抗"))
    t.add("if {joined_relief_batch} and {aquanbo_bond} >= 45:")
    t.jump("ending_relief", 1)
    t.add("elif {shunbo_trust} >= 70 and not {used_batch_money}:")
    t.jump("postwar", 1)
    t.add("else:")
    t.jump("ending_unfinished", 1)
    t.label("final_delay")
    delay = section("选项2 · 虚与委蛇周旋")
    t.story(cut_before(delay, "趁着赖四与伪军注意力"))
    t.add("if {joined_relief_batch}:")
    t.story(between(delay, "（压下胸中怒火", "【判断：顺伯信任≥70"), 1)
    t.add("else:")
    t.say("阿棠趁赖四翻查库房，悄悄护住普通家批。", depth=1)
    t.say("伪军翻查良久，再也找不到半点相关证据。勒索了少量零碎财物之后，悻悻离去。满屋狼藉，地上到处散落被踩踏的银信。顺伯扶着受伤的阿棠缓缓站起。", depth=1)
    t.add("if {shunbo_trust} >= 70 and not {used_batch_money}:")
    t.jump("postwar", 1)
    t.add("else:")
    t.jump("ending_unfinished", 1)
    t.label("final_compromise")
    compromise = section("选项3 · 被迫妥协")
    t.story(cut_before(compromise, "【数值：顺伯信任大幅下降"))
    t.add("if {shunbo_trust} >= 90 and not {used_batch_money} and {batch_loss_count} == 0:")
    t.stat("shunbo_trust", -20, 1)
    t.stat("batch_loss_count", 1, 1)
    t.jump("postwar", 1)
    t.add("else:")
    t.stat("shunbo_trust", -20, 1)
    t.stat("batch_loss_count", 1, 1)
    t.jump("ending_unfinished", 1)

    t.label("postwar", "战后：海路重开")
    t.say("硝烟散去，海路重开，一批批南洋银信陆续抵达侨乡。")
    t.say("战争结束，阿棠可以留守侨乡接管顺兴批局，守着等待家书的人家；也可以随阿全伯下南洋寻父，在海外批局继续送批。")
    t.choice("留守侨乡，接管顺兴批局", "postwar_stay")
    t.choice("随阿全伯下南洋寻父", "ending_south", "{aquanbo_bond} >= 45")
    t.label("postwar_stay")
    t.set("father_letter", "false")
    t.add("if not {used_batch_money} and {shunbo_trust} >= 70:")
    t.set("father_roll", "range(1,101).pick_random()", 1)
    t.add("\tif {aquanbo_bond} >= 45:")
    t.add("\t\tif {father_roll} <= 70:")
    t.set("father_letter", "true", 3)
    t.add("\telse:")
    t.add("\t\tif {father_roll} <= 30:")
    t.set("father_letter", "true", 3)
    t.add("if {father_letter}:")
    t.say("海路重开，一批南洋银信陆续抵达侨乡。其中，一封来自新加坡的信，悄然寄达顺兴批局。", depth=1)
    t.add("\tif {amei_affection} >= 15:")
    t.jump("ending_return", 2)
    t.add("\telse:")
    t.jump("ending_letter_pending", 2)
    t.add("else:")
    t.say("海路虽已重开，源源不断的南洋银信陆续抵达，可依旧没有陈顺成的音讯。", depth=1)
    t.jump("ending_steadfast", 1)
    t.label("ending_letter_pending", "待补：收到父亲来信但阿妹好感不足")
    t.add("# TODO screenplay: father_letter=true and amei<15 has no defined ending.")
    t.say("阿棠留在侨乡，接下顺兴批局的担子。来自新加坡的那封信被他郑重收好；他仍将手中的银信送往千家万户。")
    t.jump("modern")

    t.label("ending_return", "结局：批归")
    ending_return = section("结局一 ·《批归》")
    t.story(cut_before(ending_return, "【指令：批局复工小事件】"))
    t.say("复工之后，第一日的批该先送往哪一家？")
    t.choice("先送最远的李家", "return_li")
    t.choice("先送等待最久的老人", "return_elder")
    t.label("return_li")
    t.stat("shunbo_trust", 5)
    t.jump("return_continue")
    t.label("return_elder")
    t.stat("amei_affection", 5)
    t.jump("return_continue")
    t.label("return_continue")
    t.story(cut_after(ending_return, "选项B【先送等待最久的老人】"))
    t.jump("modern")

    t.label("ending_steadfast", "结局：守信")
    steadfast = section("结局二 ·《守信》")
    t.story(cut_before(steadfast, "【指令：重要选择】"))
    t.say("父亲仍下落不明，你会怎样选择？")
    t.choice("随全伯下南洋寻父", "ending_south", "{aquanbo_bond} >= 45")
    t.choice("留守侨乡送批", "steadfast_stay")
    t.label("steadfast_stay")
    t.stat("shunbo_trust", 10)
    t.say("有人劝他放下一切去南洋寻父，阿棠却选择留下。他说：村里那些老人、妇人、孩子，都还在盼着海外的亲人。我不能为了自己的念想，丢下他们。")
    t.story(cut_after(steadfast, "（选择B）"))
    t.jump("modern")

    for label, title in (
        ("ending_south", "结局三 ·《下南洋》"),
        ("ending_relief", "结局四 ·《救国批》"),
    ):
        t.label(label, title)
        t.story(section(title))
        t.jump("modern")
    t.label("ending_unfinished", "结局：未竟")
    unfinished = section("结局五 ·《未竟》")
    t.story(cut_before(unfinished, "他记得送批那日"))
    t.say("阿棠一封一封拾起那些被踩踏、被泥水浸透的银信。有些信纸已经模糊成一团，再也辨认不出字迹。")
    t.add("if {widow_li_batch_lost}:")
    t.say("他记得李寡妇捧着少了大半的银元，嘴唇哆嗦的样子；也记得邻乡老人拄着拐杖，望穿村口的神情。", depth=1)
    t.add("else:")
    t.say("他记得邻乡老人拄着拐杖，望穿村口的神情；也记得一户又一户等批的人家。", depth=1)
    post_memory = between(unfinished, "他记得送批那日", "阿棠把攒下的工钱")
    t.story(cut_before(post_memory, "李寡妇（看着"))
    t.add("if {widow_li_batch_lost}:")
    t.story(cut_after(post_memory, "战后第一年"), 1)
    t.add("leave --All--")
    t.visible.clear()
    t.say("一户人家，战乱中失了丈夫，也失了从南洋寄来的银钱，孩子瘦得脱相。")
    t.say("阿棠把攒下的工钱和刚收来的批银匀出一部分，悄悄塞进那户人家的门缝。")
    t.set("used_batch_money", "true")
    t.say("他不敢当面给，怕人家不肯收，也怕自己这点心意，弥补不了那样深的亏欠。")
    t.story(cut_after(unfinished, "阿棠把攒下的工钱"))
    t.jump("modern")

    t.label("modern", "终章：纸落千山")
    t.era = "modern"
    t.story(section("终章·现代"))
    t.placeholder("批文还原")
    t.say("林灯补全了被潮气晕染的文字：儿在故土心常念。")
    t.story(cut_before(cut_after(section("小游戏七 · 批文还原"), "【橙光判定】"), "【橙光指令：隐藏结局条件校验】"))
    t.add("if not {used_batch_money} and ({shunbo_trust} >= 70 or {amei_affection} >= 15 or {aquanbo_bond} >= 45):")
    t.jump("hidden", 1)
    t.add("else:")
    t.jump("ordinary", 1)
    t.label("ordinary")
    t.story(section("普通终章收尾"))
    t.jump("finish")
    t.label("hidden", "隐藏结局：一纸千山")
    t.story(section("隐藏结局 ·《一纸千山》"))
    t.add("# TODO interaction: 银信记忆地图；待光点与故事资料接入")
    t.jump("exhibition")
    t.label("exhibition", "尾声：青年文创展")
    t.story(section("尾声·青年文创展"))
    t.add("# TODO interaction: 扫码故事与接力写批；待内容与界面接入")
    t.label("finish")
    t.save()


if __name__ == "__main__":
    build()

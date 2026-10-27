# 字体

Web 平台不支持 Godot 的 `SystemFont`，因此工程改为随包携带 **Noto Serif SC** 子集字体（OFL 1.1）。

- `NotoSerifSC-Subset.ttf`：Noto Serif SC 变量字体的子集，只保留当前工程用到的 1662 个字符（含 ASCII、中文标点、剧情/UI 全部汉字）
- `font_chars.txt`：子集使用的字符表
- `OFL-NotoSerifSC.txt`：字体许可证
- `ink_serif.tres` / `ink_serif_bold.tres` / `ink_kai.tres` / `ink_kai_bold.tres`：基于该字体的 `FontVariation`，分别使用 wght 400 / 700 / 500 / 700

## 更新文案后重新生成子集

如果剧情或 UI 增加了新的汉字，需要重新生成子集，否则 Web 端会缺字。使用本机安装的 Noto Serif SC 变量字体（或从 Google Fonts / notofonts 下载）：

```bash
python -m fontTools.subset NotoSerifSC-VF.ttf \
  --text-file=UI/Fonts/font_chars.txt \
  --output-file=UI/Fonts/NotoSerifSC-Subset.ttf \
  --layout-features='*' --name-IDs='*' --name-languages='*' \
  --notdef-glyph --notdef-outline --recommended-glyphs
```

`font_chars.txt` 由工程内 `.dtl` / `.tscn` / `.gd` / `.dch` 的全部字符加 ASCII、中文标点生成。重新生成后运行一次 Godot 编辑器导入，再运行：

```bash
godot --headless --path . --script res://tools/build_ui_resources.gd
```

以重建 `FontVariation` 资源。

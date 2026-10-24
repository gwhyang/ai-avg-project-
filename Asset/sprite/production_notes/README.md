# 《一纸千山》人物资源包 / Character Sprites

所有PNG已统一为538×1080、RGBA真透明、符合英文小写/数字/下划线命名规范。
正式位置: assets/sprites/characters/<character>/<name>.png
7名核心角色均包含 normal.png，另外包含剧情所需的表情/动作候选。
注意：AI独立生成的不同情绪图存在手势、角度、体态甚至服装微差，**不符合严格的仅表情变化/完全同构图差分要求**。本包通过固定画布、人物居中及脚底基线对齐完成第一层适配，但不能等同于像素锁定差分。前端可优先使用 normal.png。其他图用于动作切换/审核，不能承诺切换完全无跳动。
- variant = 情绪候选，需再核验五官、着装、站位一致性
- action = 剧情动作候选，不建议直接用作无跳动表情差分
- base = normal 初稿，需美术确认人物身份和风格

角色:
atang 阿棠
shunbo 顺伯
amei 阿妹
aquanbo 阿全伯
lindeng 林灯
laisi 赖四
chenshuncheng 陈顺成
grandma_lindeng 林灯奶奶
widow_li 李家寡妇
elder_villager 邻乡老人
soldier 通用伪军（服装细节待历史考证）

特殊提醒: 赖四和阿全伯的部分AI差分与normal形象可能不一致，不应当默认为已经锁定的差分；李家寡妇sad年龄不一致更明显，仍作为候选。
改稿覆盖同名文件即可。

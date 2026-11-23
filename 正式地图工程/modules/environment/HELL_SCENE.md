# 按最新版原图编辑地图

地图依据 `D:/YU/PS/素材/游戏界面.png`（1920×52000）导入，26 张图块保留原始像素和坐标。编辑器底图来自 `assets/art/reference_map/`。动态机关运行时使用分离素材，保持此前的漂浮、碎裂和移动效果。

打开 `scenes/levels/formal_hell_entry.tscn`，在 2D 场景树中展开：

- `Ground/Collision`：左下角地面。
- `Platforms/<平台>/Collision`：普通、浮动、移动和碎裂平台。
- `Terrain/<岩壁>/CollisionPolygon2D`：岩壁和固定岩块。
- `Hazards/<危险区>/CollisionPolygon2D`：尖刺和岩浆。

以上地图碰撞均为 CollisionPolygon2D，可通过编辑器顶部多边形工具拖动顶点、添加或删除顶点。节点已保存到场景文件，运行时不会重新生成或覆盖 polygon。普通矩形碰撞也已改为四顶点多边形，可以进一步贴合画面轮廓。角色本身继续使用原有胶囊碰撞。

平台位置和运动范围在对应平台节点编辑，`kind`、`travel`、`middle_speed` 和 `break_seconds` 可在检查器中调整。原来的 layout.json 和 walls.json 现在只作历史参考，运行不再读取。

保留首页、下潜、追逐和开场拼接；幽灵从洞口出现后可唤醒并附身恶魔，按一次左 Shift 投叉，命中团团后自动传送并弹射，无需再次按键。按 F6 单独试玩场景，按 F5 从首页进入。

验证：原图图块逐像素比对通过；54 个地图多边形已验证保存；编辑顶点后启动保持不变；地狱交互检查通过。碰撞轮廓仍可按个人手感继续微调。

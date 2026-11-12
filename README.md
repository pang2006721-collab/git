# 借身登天

一只小灵魂从地狱出发，借助不同宿主不断向上，穿过海底、森林和天空，最终抵达天堂的 2D 平台跳跃游戏原型。

本仓库仅保留当前完整流程原型的 Godot 工程、代码和所需美术素材。所有美术由作者绘制。

## 下载并运行

1. 在 GitHub 点击 **Code → Download ZIP**，把下载的 ZIP 完整解压。
2. 使用 **Godot 4.7.2 标准版**。本工程使用 GDScript，不需要 .NET、第三方插件或额外代码依赖。
3. 在 Godot 项目管理器点击 **导入**，选择解压目录根部的 **project.godot**。
4. 打开工程，等待首次素材导入完成，按 **F5** 打开首页，点击作者绘制的 START 开始完整流程。

也可以使用 Git 克隆后，直接导入根目录的 `project.godot`。

画面为横屏 1920×1080，默认窗口为 1280×720，使用 Compatibility 渲染模式。不要只下载单个场景文件；场景使用的脚本和素材已一并包含在工程中。

## 操作

| 阶段 | 操作 |
| --- | --- |
| 通用 | A/D 左右移动，左 Shift 接近后附身，R 重来 |
| 地狱 | 幽灵靠近恶魔后附身；W 或空格跳跃，向上跳入火山口 |
| 海底 | W 持续上浮，不按自然下沉；S 快速下沉，A/D 左右游动并保留水中惯性；从水面跃出并落到岸上 |
| 森林 | 上岸后接近松鼠附身；W 或空格跳跃，S 抓藤蔓；抓住后 W/S 攀爬、A/D 摆荡、空格跳离；按住 S 到藤蔓底端可滑下 |
| 树冠 | 松鼠首次自动跳出；A/D 控制空中方向；落回后再按 W，从刚才的落点跳出。接近小鸟后按左 Shift 附身 |
| 天空 | 反复点按 W 扇翅上升，按住不连续扇翅，松开自然下坠；A/D 控制方向，向顶部云层飞行 |
| 天堂 | 到达后切回白色幽灵；A/D 移动，W 或空格跳跃。上帝的眼睛会追踪玩家，并定时弹性回弹 |

各阶段之间使用同一世界中的连续运镜。宿主附身前会由 AI 自主移动。当前内容是可玩的流程原型，尚未包含最初构想中的全部追逐、陷阱和结局。

## 在 Godot 中编辑

启动首页：`scenes/ui/main_menu.tscn`；完整流程：`scenes/game_flow.tscn`。

首页 Logo 和上帝定时弹性回弹；上帝眼睛追踪鼠标，小鸟使用游戏扇翅模块自主飞行，鼠标左键按住可拖动，松开后继续自主飞行。SETTING 当前仅做点击回弹。首页节点、按钮位置和独立的弹性模块参数都可在编辑器调整。

| 场景文件 | 内容 |
| --- | --- |
| `scenes/levels/hell_prototype.tscn` | 地狱 |
| `scenes/levels/ocean_prototype.tscn` | 海底及岸边 |
| `scenes/levels/jungle_prototype.tscn` | 森林、藤蔓，以及上方实际连接的天空与天堂子场景 |
| `scenes/levels/sky_prototype.tscn` | 树冠弹跳、小鸟附身与飞行 |
| `scenes/levels/heaven_prototype.tscn` | 天堂、幽灵、云地面及上帝 |

打开对应场景后可按 **F6** 单独试玩。地图背景、主要碰撞和角色均保存在场景文件中，可在编辑器中调整。

- 天空树冠轮廓：`CanopySurface/CollisionPolygon2D`。
- 天空两侧碰撞：`SkyBounds/Left`、`SkyBounds/Right`。
- 天堂云地面：`CloudSurface/Collision`；出生点：`GhostSpawn`。
- 上帝回弹间隔与眼神幅度：`God/Visual` 的 `Pulse Interval` 和 `Eye Travel`。
- 松鼠落回深度：`Bouncer` 的 `Burial Depth`。
- 褶皱下方同色遮挡块：天空场景中的 `RippleCover`。

## 目录

- `assets/`：当前原型所需的作者美术与 Godot 导入参数。
- `scenes/`：角色、地图、场景衔接与主流程。
- `modules/`：独立的移动、输入、AI、附身、镜头、软藤蔓与视觉弹性模块。
- `shaders/`：原型使用的材质与图层表现。
- `project.godot`：Godot 工程入口。

首次导入产生的 `.godot/` 缓存由 Godot 自动重建，不需要下载或提交。

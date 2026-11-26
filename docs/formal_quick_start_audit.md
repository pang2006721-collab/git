# 正式与快捷入口核对

本轮核对代码路径并运行实际 Godot 检查。没有假装完整手动通关每张地图；正常天堂测试使用真实首页 Gameplay 嵌套结构，在天空云边触发实际进入条件，不调用快捷键或云的_enter。

| 入口 | 保留的试玩差异 | 核对结果 |
|---|---|---|
| 1 | 跳过首页下降与追逐，直接洞口弹出 | 原出场、附身、1.35倍及跟随共用；正常首页交接另测 |
| 2 | 位于地狱最后平台，已附身、岩浆按高处起点启动 | 玩家起跳触发原火山/海底转场，交还控制和镜头共用 |
| 3 | 从海底y32400已附身小鱼开始，展示水母入场 | 使用原小鱼与攻击系统，跳过前半海底不是效果漏接 |
| 4 | 直接上岸小鱼、重新给上岸计时，已完成最后水面攻击 | 原上岸图、Shift松鼠提示及附身共用 |
| 5 | 已附身松鼠，自动摆放/松开顶端藤蔓 | 后续进入真实树冠转场、褶皱弹出及原小鸟附身 |
| 6 | 天空偏上、已附身小鸟，热量从初始状态开始 | 原飞行/老鹰/冰雹/钻云共用 |
| 7 | 从钻云开始，固定100橘子，携带切换前快照 | 原先独占结算交接，现与正常登顶共用heaven_ending_handoff |

## 已修的漏接

正常天堂原来没有连接新封赏、钻云回顾和主页收尾，仍是旧云面。共享入口从云的entered_cloud主线程准备素材，从arrived接续；支持current_scene本身是关卡，以及首页包含Gameplay子场景的实际正式流程。直接继承实际视口变换与角色速度、比例，不黑屏、不重新弹出，回顾保留真实死亡及录像。正常按实际橘子数，7键才覆盖100。100以下授环音效也不播放。

原生诊断直接对CompressedTexture2D执行get_image导致当前图形环境出现底部噪点；改为验证最终视口内的光环黄色像素及底部云颜色，37/100及7入口重测正常，不改美术。

## 内容缺口

目前真正放置的橘子仅地狱40颗。海底、丛林、天空的剩余数量尚未完成，因此正常玩法目前无法收齐100；7键只是奖励预览。此轮没有代填计数或擅自布置其他关卡橘子。

## 检查

通过：main_menu_camera_handoff、segment_quick_start、upper_ocean_quick_start、shore_quick_start、canopy_quick_start、upper_sky_quick_start、ocean_camera_handoff、formal_ocean_link、formal_ocean_fish、formal_fish_shore_exit、squirrel_canopy_transition、formal_canopy_bird、formal_sky_cloud_exit、seamless_halo_cloud_gate、settlement_return_home。原生通过：natural_heaven_ending（37/100、嵌套/独立）、ending_quick_start、settlement_opening_background。

upper_ocean_quick_start两条旧断言要求死亡立刻清除锁定鲨鱼，已按后来的用户约定修正为“停止追加攻击、已有攻击继续”，不改变当前运行行为。

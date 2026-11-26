# 光环奖励预览：第二版动作依据

参考并应用：
- [godot-2d-animation](https://github.com/bgrenat/godot-game-dev-studio/tree/main/skills/godot-2d-animation)，已安装到本机 Codex skills；阅读了 procedural_squash_stretch.gd。采用单一动画驱动、可恢复的形变及动作间连续交接。
- [Animator Survival Kit skill](https://github.com/sumyunq/custom_skills/blob/master/skills/animatorsSurvivalKit/SKILL.md)。采用反向预备、轻物体快速弹出、动作分层和弧线，按实际60帧回放检查。

实际改动：
- 升起前先下压；分裂前压扁蓄力，第二个光环约0.1秒弹出并超过正常尺寸，再收稳。
- 用连续三次曲线衔接位置关键姿态，取代每段重新开始的慢速插值。
- 戴回上帝时先接触头顶、压扁，再拉伸回弹；小幽灵先轻蹲，再被光环带动回弹，光环稍晚收稳。
- 小幽灵形变保持面积，表情只使用眼睛，没有嘴；加抬眼和眨眼，引导视线先于光环移动。
- 分裂与两次戴上使用原有 bounce 音效和短促的小笔画，保留原图，不加满屏闪光。
- 仍是独立预览，正式100橘子结局尚未连接。

导出：1280×720，60 FPS，8.4秒，MP4含音效。

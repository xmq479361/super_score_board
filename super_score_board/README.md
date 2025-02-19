# 超级计分板 (Super Score Board)

超级计分板是一个功能丰富的Flutter应用,专为记录和管理各种比赛的得分而设计。它提供了直观的界面和多样化的功能,适用于多种竞技场景。

## 主要功能

1. **双人计分**: 支持左右两名选手的得分记录。
2. **计时功能**:
    - 总体计时: 为整场比赛设置时间限制。
    - 回合计时: 可选择为每个回合单独计时。
3. **选手管理**:
    - 添加、编辑和删除选手信息。
    - 记录每位选手的最高分和胜率。
4. **实时得分调整**:
    - 通过点击或滑动手势快速调整得分。
    - 带有动画效果的得分变化,模拟翻页效果。
5. **游戏设置**:
    - 自定义比赛时长。
    - 开启/关闭倒计时功能。
    - 设置单轮计时。
6. **界面定制**:
    - 支持面对面模式,适应不同的观看角度。
    - 可切换显示顺序,满足不同场景需求。
7. **数据持久化**:
    - 自动保存游戏状态,支持恢复未完成的比赛。
    - 记录并展示选手的历史数据。
8. **多语言支持**: 目前支持中文,易于扩展其他语言。

## 技术特性

- 使用Flutter框架开发,支持跨平台部署。
- 采用响应式设计,适配不同尺寸的设备。
- 使用SharedPreferences进行本地数据存储。
- 实现了自定义动画效果,提升用户体验。
- 采用模块化设计,便于功能扩展和维护。

## 环境要求

- Flutter SDK: 2.5.0 或更高版本
- Dart: 2.14.0 或更高版本
- 支持的平台: iOS, Android

## 集成步骤

1. 克隆项目仓库:


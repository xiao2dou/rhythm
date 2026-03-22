# Rhythm V1 设计文档

## 1. 目标与范围

Rhythm V1 目标：在 macOS 上提供稳定可用的休息提醒能力，帮助用户建立专注与休息节奏。

范围包含：

1. 用户可自定义专注时长、休息时长
2. 系统锁屏后重置当前计时周期
3. 休息提醒为全屏半透明遮罩，可按 `ESC` 跳过
4. 记录每次休息会话（计划时长、实际时长、跳过信息）
5. 以菜单栏常驻应用形式运行

## 2. 用户流

1. 用户在菜单栏设置专注 25 分钟，休息 5 分钟
2. 应用进入专注计时
3. 到点后弹出全屏半透明休息遮罩
4. 用户选择：
   - 等待倒计时结束：记为完成
   - 按 `ESC`：记为跳过
5. 结束后自动进入下一轮专注计时
6. 若期间系统锁屏：重置周期，解锁后重新开始专注计时

## 3. 架构设计

### 3.1 模块划分

- `TimerEngine`
  - 维护专注/休息状态机
  - 驱动计时与状态切换
- `OverlayManager`
  - 管理全屏半透明窗口
  - 处理 `ESC` 跳过、倒计时结束回调
- `LockMonitor`
  - 监听系统锁屏通知
  - 通知 `TimerEngine` 执行 reset
- `SessionStore`
  - 将休息记录持久化到本地 JSON
- `SettingsStore`
  - 维护用户节奏配置并写入 `UserDefaults`

### 3.2 状态机

- `focusing`
- `resting`

状态转移：

1. `focusing` 到时 -> `resting`
2. `resting` 倒计时结束 -> `focusing`
3. `resting` ESC -> `focusing`
4. 任意状态锁屏 -> `focusing`（重置）

## 4. 数据模型

### 4.1 用户配置

`UserDefaults`

- `focusMinutes: Int`
- `restMinutes: Int`

### 4.2 休息记录 `RestSession`

- `id: UUID`
- `scheduledRestSeconds: Int`
- `actualRestSeconds: Int`
- `startedAt: Date`
- `endedAt: Date`
- `skipped: Bool`
- `skipReason: String?` (`esc`)
- `createdAt: Date`

## 5. 关键实现点

1. 计时准确性
   - 用系统时间差计算剩余时间，避免定时器漂移
2. 全屏遮罩
   - `NSWindow` + `NSHostingView`
   - `window.level = .screenSaver`
   - 背景半透明，居中显示倒计时
3. ESC 响应
   - `NSEvent.addLocalMonitorForEvents(.keyDown)`
4. 锁屏重置
   - 监听 `com.apple.screenIsLocked` 通知

## 6. V1 非目标

- 云同步
- 跨设备
- 复杂统计分析图表
- 开机自启动配置界面

## 7. 验收标准

1. 修改专注/休息时长后立即生效
2. 到点显示全屏半透明休息遮罩
3. 按 `ESC` 可以跳过并产生跳过记录
4. 锁屏后计时重置
5. 最近记录可在菜单栏查看

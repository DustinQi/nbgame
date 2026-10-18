# 嘉悦云上 Godot 核心玩法原型实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **当前迭代说明（2026-10-18）：** 当前迭代只做「工程地基 + 可视化移动验收」：测试框架、常量、输入映射、玩家第一人称移动和一个能走动的空场地，不含投掷、敌人和 HUD。拆细后的执行计划见 `docs/superpowers/plans/2026-10-18-jiayue-cloud-foundation-plan.md`。本文件保留为后续完整原型的路线图，等移动验收通过后再按需拆后续任务。

**Goal:** 在 Godot 4.7.2 中用 GDScript 做出「第一人称移动 + 投掷武器 + 可击杀目标 + HUD」的最小可玩原型。

**Architecture:** 采用节点组件化：`CharacterBody3D` 玩家负责移动与视角，`WeaponManager` 节点负责冷却与投掷，`RigidBody3D` 投掷物负责飞行与命中，`StaticBody3D` 目标假人负责承伤与死亡，`Arena` 负责统计剩余目标与清场信号，`HUD` 负责显示。纯逻辑（属性、冷却、伤害）放在 `RefCounted` 类里，用无界面测试脚本验证；场景与手感由王总运行游戏试玩验证。

**Tech Stack:** Godot 4.7.2 stable、GDScript、文本场景 `.tscn` / 资源 `.tres`、headless 测试脚本。无第三方插件。

**Spec:** `docs/superpowers/specs/2026-08-02-jiayue-cloud-design.md`（技术方案见第五节）

## Global Constraints

- 引擎固定为 Godot 4.7.2 stable，脚本全部使用 GDScript，不引入 C#、不安装任何插件。
- 项目根目录是 `game/`，所有资源路径使用 `res://`；不要手动修改 `.godot/` 缓存目录。
- 命名规范：类名/节点名 PascalCase；函数和变量 snake_case；私有成员 `_` 前缀；每个方法不超过 50 行；关键逻辑写中文注释。
- 碰撞层约定：第 1 层 = 玩家，第 2 层 = 场景（地面/墙），第 4 层 = 敌人，第 8 层 = 投掷物。数值分别为 1、2、4、8。
- 玩家移动速度 6 m/s，跳跃初速度 8 m/s，重力 24 m/s²，鼠标灵敏度 0.0025。
- 初始生命 100，能量上限 100，每次击杀获得 15 能量。
- 游戏内中文使用 `SystemFont`，字体候选顺序：`PingFang SC`、`Microsoft YaHei`、`Noto Sans CJK SC`，避免中文显示成方块。
- 每完成一个任务必须运行 `./game/test.sh`（或等价的 headless 命令）并保证全部测试通过，然后提交。
- 提交信息格式：`feat/fix/refactor/docs: <中文描述>`，结尾追加 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 所有场景/资源文件必须是纯文本，方便 AI 直接编写和维护。

## Review Focus

以下五类是设计文档隐含、但普通单元测试容易漏掉的失败场景，最可能影响试玩体验：

1. **鼠标未捕获时的误触**：按 Esc 释放鼠标后点击窗口，不应该把手里的东西扔出去。由 Task 6 在 `WeaponManager._unhandled_input` 里加捕获判断，Task 10 试玩时人工确认。
2. **投掷物击中玩家自己**：投掷物从相机前方 0.6 米处生成，并且碰撞遮罩必须排除玩家层。由 Task 5 的自动化测试锁定碰撞层。
3. **清场信号重复触发**：所有目标死亡后 `cleared` 只应触发一次，后续多余的击杀不应再次触发。由 Task 9 的自动化测试锁定。
4. **冷却期间连续点击**：冷却未结束时连点左键不能连续投掷。由 Task 4 的 `Cooldown` 测试和 Task 6 的 `can_throw` 测试锁定。
5. **中文显示成方块**：HUD 里的中文必须通过 `SystemFont` 回退链正常显示。由 Task 10 的人工试玩确认。

---

## 文件结构

```
game/
├── project.godot                      # 项目配置（已存在）
├── run.sh                             # 一键运行游戏（Task 10 创建）
├── test.sh                            # 一键运行全部测试（Task 1 创建）
├── scenes/
│   ├── main.tscn                      # 竞技场主场景（Task 9 重写，Task 10 加 HUD）
│   ├── player/player.tscn             # 玩家场景（Task 8）
│   ├── weapons/throwable.tscn         # 通用投掷物场景（Task 5）
│   ├── enemies/target_dummy.tscn      # 目标假人场景（Task 7）
│   └── ui/hud.tscn                    # HUD 场景（Task 10）
├── scripts/
│   ├── core/
│   │   ├── game_constants.gd          # 全局数值常量（Task 1）
│   │   └── input_setup.gd             # 运行时注册按键动作（Task 2）
│   ├── player/
│   │   ├── player_stats.gd            # 玩家生命/能量（Task 3）
│   │   └── player_controller.gd       # 第一人称移动与视角（Task 8）
│   ├── weapons/
│   │   ├── cooldown.gd                # 通用冷却计时器（Task 4）
│   │   ├── weapon_data.gd             # 武器数据资源（Task 4）
│   │   ├── weapon_manager.gd          # 投掷与冷却管理（Task 6）
│   │   └── throwable.gd               # 投掷物飞行与命中（Task 5）
│   ├── enemies/
│   │   ├── enemy_stats.gd             # 敌人生命逻辑（Task 7）
│   │   └── target_dummy.gd            # 目标假人节点（Task 7）
│   ├── level/
│   │   └── arena.gd                   # 剩余目标统计与清场（Task 9）
│   └── ui/
│       └── hud.gd                     # 准星、血条、能量条、提示（Task 10）
├── resources/weapons/
│   └── chopsticks.tres                # 筷子武器数据（Task 4）
└── tests/
    ├── test_runner.gd                 # 自动发现并运行测试（Task 1）
    ├── test_game_constants.gd
    ├── test_input_setup.gd
    ├── test_player_stats.gd
    ├── test_cooldown.gd
    ├── test_weapon_data.gd
    ├── test_throwable.gd
    ├── test_weapon_manager.gd
    ├── test_enemy_stats.gd
    ├── test_target_dummy.gd
    ├── test_player_scene.gd
    ├── test_main_scene.gd
    └── test_hud.gd
```

---

### Task 1: 测试框架与游戏常量

**Files:**
- Create: `game/scripts/core/game_constants.gd`
- Create: `game/tests/test_runner.gd`
- Create: `game/tests/test_game_constants.gd`
- Create: `game/test.sh`

**Interfaces:**
- Consumes: 无
- Produces: 全局常量类 `GameConstants`，后续任务直接引用 `GameConstants.GRAVITY` 等；测试入口 `tests/test_runner.gd`，自动发现 `tests/test_*.gd`。

- [ ] **Step 1: 写测试运行器**

创建 `game/tests/test_runner.gd`：

```gdscript
extends SceneTree

# 简单的无界面测试运行器：自动发现 tests/test_*.gd 并逐个执行
var _passed := 0
var _failed := 0

func _initialize() -> void:
    var files := _collect_test_files()
    if files.is_empty():
        push_error("没有找到任何测试文件")
        quit(1)
        return
    for path in files:
        var script: GDScript = load(path)
        if script == null:
            _failed += 1
            push_error("无法加载测试文件: " + path)
            continue
        print("== %s ==" % path)
        var test_case = script.new()
        test_case.run(self)
    print("测试完成：通过 %d，失败 %d" % [_passed, _failed])
    quit(0 if _failed == 0 else 1)

func _collect_test_files() -> Array[String]:
    var files: Array[String] = []
    var dir := DirAccess.open("res://tests")
    if dir == null:
        return files
    for file_name in dir.get_files():
        if file_name.begins_with("test_") and file_name.ends_with(".gd"):
            files.append("res://tests/" + file_name)
    files.sort()
    return files

# 断言条件为真
func check(condition: bool, message: String) -> void:
    if condition:
        _passed += 1
    else:
        _failed += 1
        push_error("测试失败: " + message)
        print("  ✗ " + message)

# 断言两个值相等
func check_equal(actual, expected, message: String) -> void:
    check(actual == expected, "%s（期望 %s，实际 %s）" % [message, str(expected), str(actual)])
```

- [ ] **Step 2: 写常量的失败测试**

创建 `game/tests/test_game_constants.gd`：

```gdscript
extends RefCounted

# 验证全局常量都是合理的正数
func run(t) -> void:
    t.check(GameConstants.GRAVITY > 0.0, "重力为正数")
    t.check(GameConstants.WALK_SPEED > 0.0, "移动速度为正数")
    t.check(GameConstants.JUMP_VELOCITY > 0.0, "跳跃速度为正数")
    t.check(GameConstants.MOUSE_SENSITIVITY > 0.0, "鼠标灵敏度为正数")
    t.check_equal(GameConstants.MAX_HEALTH, 100.0, "初始生命为 100")
    t.check_equal(GameConstants.MAX_ENERGY, 100.0, "能量上限为 100")
    t.check(GameConstants.ENERGY_PER_KILL > 0.0, "击杀回能为正数")
```

- [ ] **Step 3: 创建测试脚本并运行，确认失败**

创建 `game/test.sh`：

```bash
#!/bin/bash
# 运行全部自动化测试
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PWD" -s tests/test_runner.gd
```

运行：

```bash
chmod +x /Volumes/work/repo/nbgame/game/test.sh
/Volumes/work/repo/nbgame/game/test.sh
```

预期：出现 `GameConstants` 未定义的解析错误，测试非零退出。

- [ ] **Step 4: 写最小实现**

创建 `game/scripts/core/game_constants.gd`：

```gdscript
class_name GameConstants
extends RefCounted

# 玩法数值统一放在这里，方便后续调手感
const GRAVITY := 24.0
const WALK_SPEED := 6.0
const JUMP_VELOCITY := 8.0
const MOUSE_SENSITIVITY := 0.0025
const MAX_HEALTH := 100.0
const MAX_ENERGY := 100.0
const ENERGY_PER_KILL := 15.0
```

- [ ] **Step 5: 再次运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期输出包含 `测试完成：通过 7，失败 0`，退出码为 0。

- [ ] **Step 6: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/game_constants.gd game/tests/test_runner.gd game/tests/test_game_constants.gd game/test.sh
git commit -m "feat: 添加测试框架与游戏常量" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 输入映射

**Files:**
- Create: `game/scripts/core/input_setup.gd`
- Create: `game/tests/test_input_setup.gd`

**Interfaces:**
- Consumes: 无
- Produces: `InputSetup.ensure_actions()` 静态方法（幂等）；注册 `move_forward` / `move_back` / `move_left` / `move_right` / `jump` / `throw` 六个动作。后续玩家和武器管理器在 `_ready()` 里调用。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_input_setup.gd`：

```gdscript
extends RefCounted

# 验证按键动作被正确注册且重复调用不会重复绑定
func run(t) -> void:
    InputSetup.ensure_actions()
    for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "throw"]:
        t.check(InputMap.has_action(action), "动作存在: " + action)
        t.check(InputMap.action_get_events(action).size() > 0, "动作有按键绑定: " + action)
    InputSetup.ensure_actions()
    t.check_equal(InputMap.action_get_events("jump").size(), 1, "重复初始化不会重复绑定")
    t.check_equal(InputMap.action_get_events("throw").size(), 1, "投掷动作只有一个绑定")
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`InputSetup` 未定义，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/core/input_setup.gd`：

```gdscript
class_name InputSetup
extends RefCounted

# 运行时注册按键动作，避免手动编辑 project.godot 的二进制式事件配置
static func ensure_actions() -> void:
    _add_key("move_forward", KEY_W)
    _add_key("move_back", KEY_S)
    _add_key("move_left", KEY_A)
    _add_key("move_right", KEY_D)
    _add_key("jump", KEY_SPACE)
    _add_mouse("throw", MOUSE_BUTTON_LEFT)

static func _add_key(action: StringName, keycode: Key) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)

static func _add_mouse(action: StringName, mouse_button: MouseButton) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var event := InputEventMouseButton.new()
    event.button_index = mouse_button
    InputMap.action_add_event(action, event)
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 高数量，失败 0`。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/input_setup.gd game/tests/test_input_setup.gd
git commit -m "feat: 添加运行时输入映射" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 玩家属性

**Files:**
- Create: `game/scripts/player/player_stats.gd`
- Create: `game/tests/test_player_stats.gd`

**Interfaces:**
- Consumes: `GameConstants.MAX_HEALTH`、`GameConstants.MAX_ENERGY`
- Produces: `class_name PlayerStats extends RefCounted`；信号 `health_changed(current: float, maximum: float)`、`energy_changed(current: float, maximum: float)`、`died`；方法 `get_health() -> float`、`get_energy() -> float`、`is_dead() -> bool`、`take_damage(amount: float) -> void`、`heal(amount: float) -> void`、`add_energy(amount: float) -> void`、`spend_energy(amount: float) -> bool`。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_player_stats.gd`：

```gdscript
extends RefCounted

# 验证玩家生命、治疗、能量和死亡信号
func run(t) -> void:
    var stats := PlayerStats.new()
    t.check_equal(stats.get_health(), 100.0, "初始血量")
    t.check_equal(stats.get_energy(), 0.0, "初始能量")
    t.check(not stats.is_dead(), "初始未死亡")

    stats.take_damage(30.0)
    t.check_equal(stats.get_health(), 70.0, "受伤后血量")

    var death_count := [0]
    stats.died.connect(func(): death_count[0] += 1)
    stats.take_damage(999.0)
    t.check_equal(stats.get_health(), 0.0, "血量不会小于 0")
    t.check(stats.is_dead(), "血量归零后死亡")
    t.check_equal(death_count[0], 1, "死亡信号触发一次")
    stats.take_damage(10.0)
    t.check_equal(death_count[0], 1, "死亡后不再重复触发")

    var healed := PlayerStats.new()
    healed.take_damage(30.0)
    healed.heal(50.0)
    t.check_equal(healed.get_health(), 100.0, "治疗恢复且不超过上限")

    t.check(not healed.spend_energy(10.0), "能量不足时不能消耗")
    healed.add_energy(30.0)
    t.check_equal(healed.get_energy(), 30.0, "获得能量")
    t.check(healed.spend_energy(20.0), "能量足够时可以消耗")
    t.check_equal(healed.get_energy(), 10.0, "消耗后剩余能量")
    healed.add_energy(999.0)
    t.check_equal(healed.get_energy(), 100.0, "能量不超过上限")
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`PlayerStats` 未定义，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/player/player_stats.gd`：

```gdscript
class_name PlayerStats
extends RefCounted

signal health_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float)
signal died

var _health := GameConstants.MAX_HEALTH
var _energy := 0.0

func get_health() -> float:
    return _health

func get_energy() -> float:
    return _energy

func is_dead() -> bool:
    return _health <= 0.0

# 扣血：死亡后不再响应，避免重复触发死亡信号
func take_damage(amount: float) -> void:
    if is_dead() or amount <= 0.0:
        return
    _health = clampf(_health - amount, 0.0, GameConstants.MAX_HEALTH)
    health_changed.emit(_health, GameConstants.MAX_HEALTH)
    if _health <= 0.0:
        died.emit()

# 治疗：死亡状态不可治疗（本作没有复活）
func heal(amount: float) -> void:
    if is_dead() or amount <= 0.0:
        return
    _health = clampf(_health + amount, 0.0, GameConstants.MAX_HEALTH)
    health_changed.emit(_health, GameConstants.MAX_HEALTH)

func add_energy(amount: float) -> void:
    if amount <= 0.0:
        return
    _energy = clampf(_energy + amount, 0.0, GameConstants.MAX_ENERGY)
    energy_changed.emit(_energy, GameConstants.MAX_ENERGY)

# 消耗能量：足够则扣除并返回 true
func spend_energy(amount: float) -> bool:
    if amount <= 0.0:
        return true
    if _energy < amount:
        return false
    _energy -= amount
    energy_changed.emit(_energy, GameConstants.MAX_ENERGY)
    return true
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/player/player_stats.gd game/tests/test_player_stats.gd
git commit -m "feat: 添加玩家生命与能量属性" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 冷却、武器数据与筷子资源

**Files:**
- Create: `game/scripts/weapons/cooldown.gd`
- Create: `game/scripts/weapons/weapon_data.gd`
- Create: `game/resources/weapons/chopsticks.tres`
- Create: `game/tests/test_cooldown.gd`
- Create: `game/tests/test_weapon_data.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name Cooldown extends RefCounted`，方法 `_init(duration: float)`、`start()`、`tick(delta: float)`、`is_ready() -> bool`、`time_left() -> float`；`class_name WeaponData extends Resource`，字段 `display_name: String`、`damage: float`、`throw_speed: float`、`cooldown: float`、`gravity_scale: float`、`color: Color`。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_cooldown.gd`：

```gdscript
extends RefCounted

# 验证冷却计时器的边界行为
func run(t) -> void:
    var cd := Cooldown.new(0.5)
    t.check(cd.is_ready(), "初始可用")
    cd.start()
    t.check(not cd.is_ready(), "启动后不可用")
    cd.tick(0.25)
    t.check(not cd.is_ready(), "时间未到仍不可用")
    cd.tick(0.25)
    t.check(cd.is_ready(), "时间到后恢复可用")
    t.check_equal(cd.time_left(), 0.0, "剩余时间归零")
    cd.start()
    cd.tick(10.0)
    t.check_equal(cd.time_left(), 0.0, "超时不会变成负数")
```

创建 `game/tests/test_weapon_data.gd`：

```gdscript
extends RefCounted

# 验证武器默认值和筷子资源文件
func run(t) -> void:
    var weapon := WeaponData.new()
    t.check_equal(weapon.display_name, "筷子", "默认名称")
    t.check_equal(weapon.damage, 20.0, "默认伤害")
    t.check(weapon.throw_speed > 0.0, "投掷速度为正数")
    t.check(weapon.cooldown > 0.0, "冷却为正数")
    t.check(weapon.gravity_scale >= 0.0, "重力缩放不为负")

    var chopsticks: WeaponData = load("res://resources/weapons/chopsticks.tres")
    t.check(chopsticks != null, "筷子资源可加载")
    if chopsticks != null:
        t.check_equal(chopsticks.damage, 20.0, "筷子伤害")
        t.check_equal(chopsticks.throw_speed, 30.0, "筷子投掷速度")
        t.check_equal(chopsticks.cooldown, 0.35, "筷子冷却")
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`Cooldown` / `WeaponData` 未定义，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/weapons/cooldown.gd`：

```gdscript
class_name Cooldown
extends RefCounted

var _duration := 0.0
var _left := 0.0

func _init(duration: float) -> void:
    _duration = maxf(duration, 0.0)

# 开始冷却
func start() -> void:
    _left = _duration

# 每帧递减，最低到 0
func tick(delta: float) -> void:
    _left = maxf(_left - maxf(delta, 0.0), 0.0)

func is_ready() -> bool:
    return _left <= 0.0

func time_left() -> float:
    return _left
```

创建 `game/scripts/weapons/weapon_data.gd`：

```gdscript
class_name WeaponData
extends Resource

@export var display_name := "筷子"
@export var damage := 20.0
@export var throw_speed := 30.0
@export var cooldown := 0.35
@export var gravity_scale := 0.3
@export var color := Color(0.85, 0.65, 0.35, 1.0)
```

创建 `game/resources/weapons/chopsticks.tres`：

```
[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/weapons/weapon_data.gd" id="1"]

[resource]
script = ExtResource("1")
display_name = "筷子"
damage = 20.0
throw_speed = 30.0
cooldown = 0.35
gravity_scale = 0.3
color = Color(0.85, 0.65, 0.35, 1)
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/weapons/cooldown.gd game/scripts/weapons/weapon_data.gd game/resources/weapons/chopsticks.tres game/tests/test_cooldown.gd game/tests/test_weapon_data.gd
git commit -m "feat: 添加冷却计时器与武器数据" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 投掷物

**Files:**
- Create: `game/scripts/weapons/throwable.gd`
- Create: `game/scenes/weapons/throwable.tscn`
- Create: `game/tests/test_throwable.gd`

**Interfaces:**
- Consumes: `WeaponData`（Task 4）
- Produces: `class_name Throwable extends RigidBody3D`；方法 `launch(direction: Vector3, weapon_data: WeaponData) -> void`；碰撞层 8、遮罩 6（场景层 + 敌人层，不含玩家层）；命中带 `take_damage(amount: float)` 的节点时造成一次伤害。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_throwable.gd`：

```gdscript
extends RefCounted

# 模拟一个可受伤目标，用于验证命中逻辑
class DummyTarget extends Node:
    var damage_taken := 0.0

    func take_damage(amount: float) -> void:
        damage_taken += amount

# 验证投掷速度、方向和命中只结算一次
func run(t) -> void:
    var weapon := WeaponData.new()
    weapon.throw_speed = 20.0
    weapon.damage = 15.0
    weapon.gravity_scale = 0.5

    var projectile := Throwable.new()
    projectile.launch(Vector3.FORWARD, weapon)
    t.check_equal(projectile.linear_velocity.length(), 20.0, "投掷速度")
    t.check(projectile.linear_velocity.z < 0.0, "朝前方飞出")
    t.check_equal(projectile.gravity_scale, 0.5, "重力缩放生效")

    var target := DummyTarget.new()
    projectile._on_body_entered(target)
    t.check_equal(target.damage_taken, 15.0, "命中造成武器伤害")
    projectile._on_body_entered(target)
    t.check_equal(target.damage_taken, 15.0, "同一次投掷只造成一次伤害")

    projectile.free()
    target.free()

    var packed: PackedScene = load("res://scenes/weapons/throwable.tscn")
    t.check(packed != null, "投掷物场景可加载")
    if packed == null:
        return
    var scene_projectile := packed.instantiate() as Throwable
    t.check(scene_projectile != null, "投掷物场景脚本正确")
    t.check_equal(scene_projectile.collision_mask & 1, 0, "碰撞遮罩不含玩家层")
    t.check((scene_projectile.collision_mask & 2) != 0, "碰撞遮罩含场景层")
    t.check((scene_projectile.collision_mask & 4) != 0, "碰撞遮罩含敌人层")
    scene_projectile.free()
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`Throwable` 未定义或场景加载失败，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/weapons/throwable.gd`：

```gdscript
class_name Throwable
extends RigidBody3D

@export var lifetime := 6.0

var data: WeaponData
var _hit_done := false

func _ready() -> void:
    contact_monitor = true
    max_contacts_reported = 2
    body_entered.connect(_on_body_entered)
    # 超时自动回收，防止场景里堆积垃圾
    get_tree().create_timer(lifetime).timeout.connect(queue_free)

# 发射：设置速度、重力缩放和外观颜色
func launch(direction: Vector3, weapon_data: WeaponData) -> void:
    data = weapon_data
    gravity_scale = weapon_data.gravity_scale
    linear_velocity = direction.normalized() * weapon_data.throw_speed
    _apply_color(weapon_data.color)

func _apply_color(color: Color) -> void:
    var mesh := get_node_or_null("Mesh") as MeshInstance3D
    if mesh == null:
        return
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material

# 命中：只对带 take_damage 的节点结算一次
func _on_body_entered(body: Node) -> void:
    if _hit_done or data == null:
        return
    if body.has_method("take_damage"):
        _hit_done = true
        body.take_damage(data.damage)
```

创建 `game/scenes/weapons/throwable.tscn`：

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/weapons/throwable.gd" id="1"]

[sub_resource type="SphereShape3D" id="SphereShape3D_1"]
radius = 0.08

[sub_resource type="BoxMesh" id="BoxMesh_1"]
size = Vector3(0.06, 0.06, 0.35)

[node name="Throwable" type="RigidBody3D"]
collision_layer = 8
collision_mask = 6
contact_monitor = true
max_contacts_reported = 2
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("SphereShape3D_1")

[node name="Mesh" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_1")
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/weapons/throwable.gd game/scenes/weapons/throwable.tscn game/tests/test_throwable.gd
git commit -m "feat: 添加投掷物飞行与命中" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 武器管理器

**Files:**
- Create: `game/scripts/weapons/weapon_manager.gd`
- Create: `game/tests/test_weapon_manager.gd`

**Interfaces:**
- Consumes: `WeaponData`、`Cooldown`（Task 4）、`Throwable` 场景（Task 5）、`InputSetup`（Task 2）
- Produces: `class_name WeaponManager extends Node3D`；`@export var weapon: WeaponData`、`@export var throwable_scene: PackedScene`；信号 `threw(weapon: WeaponData)`、`cooldown_changed(remaining: float, duration: float)`；方法 `can_throw() -> bool`、`try_throw() -> bool`。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_weapon_manager.gd`：

```gdscript
extends RefCounted

# 验证装备检查和冷却阻断
func run(t) -> void:
    InputSetup.ensure_actions()
    var manager := WeaponManager.new()
    t.check(not manager.can_throw(), "没有武器时不能投掷")

    manager.weapon = load("res://resources/weapons/chopsticks.tres")
    t.check(not manager.can_throw(), "没有投掷物场景时不能投掷")

    manager.throwable_scene = load("res://scenes/weapons/throwable.tscn")
    t.check(manager.can_throw(), "装备齐全且冷却结束时可以投掷")

    manager._get_cooldown().start()
    t.check(not manager.can_throw(), "冷却中不能投掷")

    manager._get_cooldown().tick(999.0)
    t.check(manager.can_throw(), "冷却结束后恢复投掷")
    manager.free()
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`WeaponManager` 未定义，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/weapons/weapon_manager.gd`：

```gdscript
class_name WeaponManager
extends Node3D

signal threw(weapon: WeaponData)
signal cooldown_changed(remaining: float, duration: float)

@export var weapon: WeaponData
@export var throwable_scene: PackedScene

var _cooldown: Cooldown

func _ready() -> void:
    InputSetup.ensure_actions()

func _process(delta: float) -> void:
    if _cooldown == null or _cooldown.is_ready():
        return
    _cooldown.tick(delta)
    cooldown_changed.emit(_cooldown.time_left(), _cooldown_duration())

func _unhandled_input(event: InputEvent) -> void:
    # 鼠标没被捕获时（例如按了 Esc），点击不投掷
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return
    if event.is_action_pressed("throw"):
        try_throw()

func can_throw() -> bool:
    return weapon != null and throwable_scene != null and _get_cooldown().is_ready()

# 真正执行投掷：从相机中心朝前飞出
func try_throw() -> bool:
    if not can_throw():
        return false
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return false
    var projectile := throwable_scene.instantiate() as Throwable
    if projectile == null:
        return false
    var forward := -camera.global_transform.basis.z
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = camera.global_position + forward * 0.6
    projectile.launch(forward, weapon)
    _get_cooldown().start()
    threw.emit(weapon)
    return true

# 延迟创建冷却计时器，方便测试时无需进入场景树
func _get_cooldown() -> Cooldown:
    if _cooldown == null:
        _cooldown = Cooldown.new(_cooldown_duration())
    return _cooldown

func _cooldown_duration() -> float:
    return weapon.cooldown if weapon != null else 0.0
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/weapons/weapon_manager.gd game/tests/test_weapon_manager.gd
git commit -m "feat: 添加武器管理器" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: 敌人与目标假人

**Files:**
- Create: `game/scripts/enemies/enemy_stats.gd`
- Create: `game/scripts/enemies/target_dummy.gd`
- Create: `game/scenes/enemies/target_dummy.tscn`
- Create: `game/tests/test_enemy_stats.gd`
- Create: `game/tests/test_target_dummy.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name EnemyStats extends RefCounted`；方法 `_init(maximum_health: float = 100.0)`、`get_health() -> float`、`get_max_health() -> float`、`is_dead() -> bool`、`take_damage(amount: float) -> void`；信号 `health_changed`、`died`。`class_name TargetDummy extends StaticBody3D`；信号 `killed`；`@export var max_health := 60.0`；方法 `take_damage(amount: float) -> void`、`get_health() -> float`、`is_dead() -> bool`；死亡后 `queue_free()`。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_enemy_stats.gd`：

```gdscript
extends RefCounted

# 验证敌人血量、死亡信号和重复受击
func run(t) -> void:
    var enemy := EnemyStats.new(60.0)
    t.check_equal(enemy.get_health(), 60.0, "初始血量")
    t.check_equal(enemy.get_max_health(), 60.0, "最大血量")

    var death_count := [0]
    enemy.died.connect(func(): death_count[0] += 1)

    enemy.take_damage(20.0)
    t.check_equal(enemy.get_health(), 40.0, "受伤后血量")
    t.check_equal(death_count[0], 0, "未死亡不触发信号")

    enemy.take_damage(999.0)
    t.check_equal(enemy.get_health(), 0.0, "血量下限为 0")
    t.check(enemy.is_dead(), "死亡状态正确")
    t.check_equal(death_count[0], 1, "死亡信号触发一次")

    enemy.take_damage(10.0)
    t.check_equal(death_count[0], 1, "死亡后不再触发")
```

创建 `game/tests/test_target_dummy.gd`：

```gdscript
extends RefCounted

# 验证假人场景加载、受伤和死亡移除
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/enemies/target_dummy.tscn")
    t.check(packed != null, "假人场景可加载")
    if packed == null:
        return
    var dummy = packed.instantiate()
    t.root.add_child(dummy)
    var killed := [0]
    dummy.killed.connect(func(): killed[0] += 1)

    t.check(not dummy.is_dead(), "初始存活")
    dummy.take_damage(20.0)
    t.check_equal(dummy.get_health(), 40.0, "受伤后剩余血量")
    t.check_equal(killed[0], 0, "未死亡不触发信号")

    dummy.take_damage(999.0)
    t.check(dummy.is_dead(), "血量归零后死亡")
    t.check_equal(killed[0], 1, "死亡信号触发一次")
    t.check(dummy.is_queued_for_deletion(), "死亡后自动移除")
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`EnemyStats` 未定义或场景加载失败，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/enemies/enemy_stats.gd`：

```gdscript
class_name EnemyStats
extends RefCounted

signal health_changed(current: float, maximum: float)
signal died

var _maximum := 1.0
var _health := 1.0

func _init(maximum_health: float = 100.0) -> void:
    _maximum = maxf(maximum_health, 1.0)
    _health = _maximum

func get_health() -> float:
    return _health

func get_max_health() -> float:
    return _maximum

func is_dead() -> bool:
    return _health <= 0.0

# 扣血：死亡后忽略后续伤害
func take_damage(amount: float) -> void:
    if is_dead() or amount <= 0.0:
        return
    _health = clampf(_health - amount, 0.0, _maximum)
    health_changed.emit(_health, _maximum)
    if _health <= 0.0:
        died.emit()
```

创建 `game/scripts/enemies/target_dummy.gd`：

```gdscript
class_name TargetDummy
extends StaticBody3D

signal killed

@export var max_health := 60.0

var _stats: EnemyStats

func _ready() -> void:
    _stats = EnemyStats.new(max_health)
    _stats.died.connect(_on_died)

func take_damage(amount: float) -> void:
    if _stats != null:
        _stats.take_damage(amount)

func get_health() -> float:
    return _stats.get_health() if _stats != null else 0.0

func is_dead() -> bool:
    return _stats != null and _stats.is_dead()

func _on_died() -> void:
    killed.emit()
    queue_free()
```

创建 `game/scenes/enemies/target_dummy.tscn`：

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/enemies/target_dummy.gd" id="1"]

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(0.8, 2, 0.8)

[sub_resource type="BoxMesh" id="BoxMesh_1"]
size = Vector3(0.8, 2, 0.8)

[sub_resource type="StandardMaterial3D" id="Material_1"]
albedo_color = Color(0.8, 0.2, 0.2, 1)

[node name="TargetDummy" type="StaticBody3D" groups=["enemies"]]
collision_layer = 4
collision_mask = 0
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
shape = SubResource("BoxShape3D_1")

[node name="Mesh" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)
mesh = SubResource("BoxMesh_1")
material_override = SubResource("Material_1")
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/enemies/enemy_stats.gd game/scripts/enemies/target_dummy.gd game/scenes/enemies/target_dummy.tscn game/tests/test_enemy_stats.gd game/tests/test_target_dummy.gd
git commit -m "feat: 添加敌人属性与目标假人" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: 玩家场景与第一人称移动

**Files:**
- Create: `game/scripts/player/player_controller.gd`
- Create: `game/scenes/player/player.tscn`
- Create: `game/tests/test_player_scene.gd`

**Interfaces:**
- Consumes: `GameConstants`、`InputSetup`、`PlayerStats`、`WeaponManager`、`Throwable` 场景、筷子资源
- Produces: `class_name PlayerController extends CharacterBody3D`；成员 `stats: PlayerStats`、`@onready var camera: Camera3D`；节点结构 `Player/Head/Camera3D`、`Player/Head/WeaponManager`；玩家在组 `player` 中。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_player_scene.gd`：

```gdscript
extends RefCounted

# 验证玩家场景的节点结构和武器挂载
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/player/player.tscn")
    t.check(packed != null, "玩家场景可加载")
    if packed == null:
        return
    var player = packed.instantiate()
    t.root.add_child(player)
    t.check(player is CharacterBody3D, "玩家是 CharacterBody3D")
    t.check(player.get_node_or_null("Head/Camera3D") is Camera3D, "有第一人称相机")
    var manager := player.get_node_or_null("Head/WeaponManager")
    t.check(manager is WeaponManager, "有武器管理器")
    if manager is WeaponManager:
        t.check(manager.weapon != null, "武器管理器已装备武器")
        t.check(manager.throwable_scene != null, "武器管理器已绑定投掷物场景")
    t.check_equal(player.collision_mask, 6, "玩家会与场景和敌人碰撞")
    t.check(player.stats is PlayerStats, "玩家持有属性对象")
    t.check_equal(player.stats.get_health(), 100.0, "玩家初始血量")
    player.free()
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：玩家场景加载失败，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/player/player_controller.gd`：

```gdscript
class_name PlayerController
extends CharacterBody3D

const PITCH_MIN := -1.45
const PITCH_MAX := 1.45

@onready var camera: Camera3D = get_node_or_null("Head/Camera3D") as Camera3D

# 玩家属性对象在实例化时就创建，保证 HUD 随时能连接信号
var stats: PlayerStats = PlayerStats.new()

var _pitch := 0.0

func _ready() -> void:
    InputSetup.ensure_actions()
    # 无界面测试时不捕获鼠标
    if DisplayServer.get_name() != "headless":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# 鼠标视角、点击重新捕获、Esc 释放
func _unhandled_input(event: InputEvent) -> void:
    # 鼠标释放状态下点击窗口，重新捕获鼠标，但这一下不投掷
    if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * GameConstants.MOUSE_SENSITIVITY)
        _pitch = clampf(
            _pitch - event.relative.y * GameConstants.MOUSE_SENSITIVITY,
            PITCH_MIN,
            PITCH_MAX
        )
        if camera != null:
            camera.rotation.x = _pitch
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# 第一人称移动与跳跃
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GameConstants.GRAVITY * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = GameConstants.JUMP_VELOCITY

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
    if direction.length_squared() > 0.0:
        velocity.x = direction.x * GameConstants.WALK_SPEED
        velocity.z = direction.z * GameConstants.WALK_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, GameConstants.WALK_SPEED * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, GameConstants.WALK_SPEED * 4.0 * delta)
    move_and_slide()
```

创建 `game/scenes/player/player.tscn`：

```
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/player/player_controller.gd" id="1"]
[ext_resource type="Script" path="res://scripts/weapons/weapon_manager.gd" id="2"]
[ext_resource type="Resource" path="res://resources/weapons/chopsticks.tres" id="3"]
[ext_resource type="PackedScene" path="res://scenes/weapons/throwable.tscn" id="4"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_1"]
radius = 0.4
height = 1.8

[node name="Player" type="CharacterBody3D" groups=["player"]]
collision_layer = 1
collision_mask = 6
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
shape = SubResource("CapsuleShape3D_1")

[node name="Head" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 0)

[node name="Camera3D" type="Camera3D" parent="Head"]
current = true

[node name="WeaponManager" type="Node3D" parent="Head"]
script = ExtResource("2")
weapon = ExtResource("3")
throwable_scene = ExtResource("4")
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/player/player_controller.gd game/scenes/player/player.tscn game/tests/test_player_scene.gd
git commit -m "feat: 添加第一人称玩家控制" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: 竞技场与清场判定

**Files:**
- Create: `game/scripts/level/arena.gd`
- Modify: `game/scenes/main.tscn`（用正式竞技场替换试验场景）
- Create: `game/tests/test_main_scene.gd`

**Interfaces:**
- Consumes: `PlayerController`、`TargetDummy`（组 `enemies`）、`GameConstants.ENERGY_PER_KILL`
- Produces: `class_name Arena extends Node3D`；信号 `enemies_remaining_changed(remaining: int)`、`cleared`；主场景根节点在组 `arena` 中，包含 `Player`、`Dummy1`、`Dummy2`、`Dummy3`；玩家击杀目标后获得能量。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_main_scene.gd`：

```gdscript
extends RefCounted

# 验证主场景结构、清场信号只触发一次、击杀回能
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    t.check(packed != null, "主场景可加载")
    if packed == null:
        return
    var main = packed.instantiate()
    t.root.add_child(main)

    t.check(main.get_node_or_null("Player") is PlayerController, "主场景包含玩家")
    t.check_equal(main.get_tree().get_nodes_in_group("enemies").size(), 3, "主场景有 3 个目标")
    t.check(main.get_node_or_null("Ground") is StaticBody3D, "主场景有地面")

    var cleared := [0]
    main.cleared.connect(func(): cleared[0] += 1)
    for i in 3:
        main._on_enemy_killed()
    t.check_equal(cleared[0], 1, "清场信号只触发一次")
    main._on_enemy_killed()
    t.check_equal(cleared[0], 1, "清场后多余击杀不会重复触发")

    var player := main.get_node("Player") as PlayerController
    t.check(player.stats.get_energy() > 0.0, "击杀后获得能量")
    main.free()
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`Arena` 未定义或场景结构不符，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/level/arena.gd`：

```gdscript
class_name Arena
extends Node3D

signal enemies_remaining_changed(remaining: int)
signal cleared

var _remaining := 0
var _player: PlayerController

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player") as PlayerController
    var enemies := get_tree().get_nodes_in_group("enemies")
    _remaining = enemies.size()
    for enemy in enemies:
        if enemy.has_signal("killed"):
            enemy.killed.connect(_on_enemy_killed)
    # 延迟一帧发送初始数量，确保 HUD 已经连接好信号
    call_deferred("_emit_initial_remaining")

func _emit_initial_remaining() -> void:
    enemies_remaining_changed.emit(_remaining)

# 每死亡一个目标：回能、更新剩余数、清场时发信号
func _on_enemy_killed() -> void:
    if _remaining <= 0:
        return
    _remaining -= 1
    if _player != null:
        _player.stats.add_energy(GameConstants.ENERGY_PER_KILL)
    enemies_remaining_changed.emit(_remaining)
    if _remaining == 0:
        cleared.emit()
```

用以下内容替换 `game/scenes/main.tscn`：

```
[gd_scene load_steps=13 format=3]

[ext_resource type="Script" path="res://scripts/level/arena.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/enemies/target_dummy.tscn" id="3"]

[sub_resource type="ProceduralSkyMaterial" id="SkyMat"]

[sub_resource type="Sky" id="Sky"]
sky_material = SubResource("SkyMat")

[sub_resource type="Environment" id="Env"]
background_mode = 2
sky = SubResource("Sky")
tonemap_mode = 2

[sub_resource type="BoxShape3D" id="GroundShape"]
size = Vector3(30, 1, 30)

[sub_resource type="BoxMesh" id="GroundMesh"]
size = Vector3(30, 1, 30)

[sub_resource type="StandardMaterial3D" id="GroundMat"]
albedo_color = Color(0.42, 0.52, 0.42, 1)

[sub_resource type="BoxShape3D" id="WallShape"]
size = Vector3(30, 4, 1)

[sub_resource type="BoxMesh" id="WallMesh"]
size = Vector3(30, 4, 1)

[sub_resource type="StandardMaterial3D" id="WallMat"]
albedo_color = Color(0.55, 0.55, 0.6, 1)

[node name="Main" type="Node3D" groups=["arena"]]
script = ExtResource("1")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Env")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 8, 0)
shadow_enabled = true

[node name="Ground" type="StaticBody3D" parent="."]
collision_layer = 2
collision_mask = 0

[node name="CollisionShape3D" type="CollisionShape3D" parent="Ground"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
shape = SubResource("GroundShape")

[node name="Mesh" type="MeshInstance3D" parent="Ground"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
mesh = SubResource("GroundMesh")
material_override = SubResource("GroundMat")

[node name="WallNorth" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, -15)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape3D" type="CollisionShape3D" parent="WallNorth"]
shape = SubResource("WallShape")

[node name="Mesh" type="MeshInstance3D" parent="WallNorth"]
mesh = SubResource("WallMesh")
material_override = SubResource("WallMat")

[node name="WallSouth" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, 15)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape3D" type="CollisionShape3D" parent="WallSouth"]
shape = SubResource("WallShape")

[node name="Mesh" type="MeshInstance3D" parent="WallSouth"]
mesh = SubResource("WallMesh")
material_override = SubResource("WallMat")

[node name="WallEast" type="StaticBody3D" parent="."]
transform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 15, 2, 0)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape3D" type="CollisionShape3D" parent="WallEast"]
shape = SubResource("WallShape")

[node name="Mesh" type="MeshInstance3D" parent="WallEast"]
mesh = SubResource("WallMesh")
material_override = SubResource("WallMat")

[node name="WallWest" type="StaticBody3D" parent="."]
transform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, -15, 2, 0)
collision_layer = 2
collision_mask = 0

[node name="CollisionShape3D" type="CollisionShape3D" parent="WallWest"]
shape = SubResource("WallShape")

[node name="Mesh" type="MeshInstance3D" parent="WallWest"]
mesh = SubResource("WallMesh")
material_override = SubResource("WallMat")

[node name="Player" parent="." instance=ExtResource("2")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 10)

[node name="Dummy1" parent="." instance=ExtResource("3")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -6)

[node name="Dummy2" parent="." instance=ExtResource("3")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6, 0, -10)

[node name="Dummy3" parent="." instance=ExtResource("3")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6, 0, -10)
```

- [ ] **Step 4: 运行测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：全部通过。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/level/arena.gd game/scenes/main.tscn game/tests/test_main_scene.gd
git commit -m "feat: 添加竞技场与清场判定" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: HUD、运行脚本与试玩验收

**Files:**
- Create: `game/scripts/ui/hud.gd`
- Create: `game/scenes/ui/hud.tscn`
- Create: `game/tests/test_hud.gd`
- Create: `game/run.sh`
- Modify: `game/scenes/main.tscn`（加入 HUD 实例）
- Modify: `docs/项目进度.md`（标记原型完成）

**Interfaces:**
- Consumes: `Arena` 信号、`PlayerStats` 信号、`WeaponManager` 信号与 `weapon.display_name`
- Produces: `class_name HUD extends CanvasLayer`；显示准星、生命条、能量条、冷却条、剩余目标数、武器名、胜利文字和操作提示。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_hud.gd`：

```gdscript
extends RefCounted

# 验证 HUD 场景可以独立加载
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/ui/hud.tscn")
    t.check(packed != null, "HUD 场景可加载")
    if packed == null:
        return
    var hud = packed.instantiate()
    t.root.add_child(hud)
    t.check(hud is HUD, "HUD 脚本正确")
    t.check(hud.get_child_count() > 0, "HUD 已创建界面节点")
    hud.free()
```

- [ ] **Step 2: 运行测试，确认失败**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：HUD 场景加载失败，测试失败。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/ui/hud.gd`：

```gdscript
class_name HUD
extends CanvasLayer

var _health_bar: ProgressBar
var _energy_bar: ProgressBar
var _cooldown_bar: ProgressBar
var _weapon_label: Label
var _remaining_label: Label
var _victory_label: Label

func _ready() -> void:
    _build_ui()
    _connect_signals()

# 用代码搭建界面，避免手写复杂的 Control 场景结构
func _build_ui() -> void:
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC"])
    var theme := Theme.new()
    theme.default_font = font
    theme.default_font_size = 20

    var root := Control.new()
    root.theme = theme
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    # 屏幕中心准星
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var dot := ColorRect.new()
    dot.custom_minimum_size = Vector2(4, 4)
    dot.color = Color(1, 1, 1, 0.9)
    center.add_child(dot)
    root.add_child(center)

    # 左下角状态条
    var status := VBoxContainer.new()
    status.anchor_top = 1.0
    status.anchor_bottom = 1.0
    status.offset_left = 24.0
    status.offset_top = -190.0
    status.offset_right = 284.0
    status.offset_bottom = -24.0
    root.add_child(status)
    _health_bar = _add_bar(status, "生命", Color(0.85, 0.2, 0.2))
    _energy_bar = _add_bar(status, "能量", Color(0.2, 0.5, 0.95))
    _cooldown_bar = _add_bar(status, "冷却", Color(0.9, 0.8, 0.2))

    # 右上角武器名
    _weapon_label = Label.new()
    _weapon_label.text = "武器：筷子"
    _weapon_label.anchor_left = 1.0
    _weapon_label.anchor_right = 1.0
    _weapon_label.offset_left = -220.0
    _weapon_label.offset_top = 24.0
    _weapon_label.offset_right = -24.0
    _weapon_label.offset_bottom = 54.0
    _weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    root.add_child(_weapon_label)

    # 顶部剩余目标数
    _remaining_label = Label.new()
    _remaining_label.text = "剩余目标：-"
    _remaining_label.anchor_left = 0.5
    _remaining_label.anchor_right = 0.5
    _remaining_label.offset_left = -120.0
    _remaining_label.offset_right = 120.0
    _remaining_label.offset_top = 24.0
    _remaining_label.offset_bottom = 54.0
    _remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(_remaining_label)

    # 底部操作提示
    var hint := Label.new()
    hint.text = "点击窗口捕获鼠标 · WASD 移动 · 空格跳跃 · 左键投掷 · Esc 释放鼠标"
    hint.anchor_left = 0.5
    hint.anchor_right = 0.5
    hint.anchor_top = 1.0
    hint.anchor_bottom = 1.0
    hint.offset_left = -320.0
    hint.offset_right = 320.0
    hint.offset_top = -40.0
    hint.offset_bottom = -12.0
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(hint)

    # 清场提示
    _victory_label = Label.new()
    _victory_label.text = "清场！"
    _victory_label.visible = false
    _victory_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _victory_label.add_theme_font_size_override("font_size", 48)
    root.add_child(_victory_label)

func _add_bar(parent: VBoxContainer, text: String, color: Color) -> ProgressBar:
    var label := Label.new()
    label.text = text
    parent.add_child(label)
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(240, 16)
    bar.max_value = 100.0
    bar.value = 100.0
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    bar.add_theme_stylebox_override("fill", fill)
    parent.add_child(bar)
    return bar

func _connect_signals() -> void:
    var arena := get_tree().get_first_node_in_group("arena") as Arena
    if arena != null:
        arena.enemies_remaining_changed.connect(_on_remaining_changed)
        arena.cleared.connect(_on_cleared)

    var player := get_tree().get_first_node_in_group("player") as PlayerController
    if player == null:
        return
    player.stats.health_changed.connect(_on_health_changed)
    player.stats.energy_changed.connect(_on_energy_changed)
    _on_health_changed(player.stats.get_health(), GameConstants.MAX_HEALTH)
    _on_energy_changed(player.stats.get_energy(), GameConstants.MAX_ENERGY)

    var manager := player.get_node_or_null("Head/WeaponManager") as WeaponManager
    if manager != null:
        manager.cooldown_changed.connect(_on_cooldown_changed)
        if manager.weapon != null:
            _weapon_label.text = "武器：" + manager.weapon.display_name
            _cooldown_bar.max_value = manager.weapon.cooldown
            _cooldown_bar.value = 0.0

func _on_health_changed(current: float, maximum: float) -> void:
    _health_bar.max_value = maximum
    _health_bar.value = current

func _on_energy_changed(current: float, maximum: float) -> void:
    _energy_bar.max_value = maximum
    _energy_bar.value = current

func _on_cooldown_changed(remaining: float, duration: float) -> void:
    _cooldown_bar.max_value = maxf(duration, 0.001)
    _cooldown_bar.value = duration - remaining

func _on_remaining_changed(remaining: int) -> void:
    _remaining_label.text = "剩余目标：%d" % remaining

func _on_cleared() -> void:
    _victory_label.visible = true
```

创建 `game/scenes/ui/hud.tscn`：

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1")
```

- [ ] **Step 4: 把 HUD 加入主场景**

在 `game/scenes/main.tscn` 顶部的外部资源列表中增加一行：

```
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="4"]
```

把文件第一行的 `load_steps=13` 改成 `load_steps=14`，并在文件末尾追加：

```
[node name="HUD" parent="." instance=ExtResource("4")]
```

- [ ] **Step 5: 创建一键运行脚本**

创建 `game/run.sh`：

```bash
#!/bin/bash
# 运行嘉悦云上游戏
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD" "$@"
```

运行：

```bash
chmod +x /Volumes/work/repo/nbgame/game/run.sh
```

- [ ] **Step 6: 运行全部测试，确认通过**

运行：

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期全部通过；确认输出里没有 `SCRIPT ERROR` 或 `ERROR` 字样。

- [ ] **Step 7: 交给王总试玩验收**

运行游戏：

```bash
/Volumes/work/repo/nbgame/game/run.sh
```

请王总按以下步骤测试，发现问题先截图（`Cmd+Shift+4`），有红色报错就复制终端文字：

1. 点击游戏窗口，鼠标被捕获；移动鼠标能转动视角。
2. `WASD` 能前后左右走动，空格能跳跃，撞墙会被挡住。
3. 准星对准红色假人，按左键投掷筷子；投掷物从画面中心飞出。
4. 每个假人需要命中 3 次（每次 20 伤害，假人 60 血），命中后假人消失。
5. 顶部「剩余目标」从 3 递减到 0，然后中央出现「清场！」。
6. 左下角能量条每击杀一个目标增加 15。
7. 冷却期间连续点击左键，不会连续投掷；按 Esc 释放鼠标后点击窗口，不会误投掷。
8. 界面上所有中文正常显示，没有方块乱码。

- [ ] **Step 8: 更新进度文档**

把 `docs/项目进度.md` 功能清单中的「原型开发」行改为：

```
| ✅ | 核心玩法原型 | 第一人称移动 + 投掷 + 目标假人 + HUD | 2026-10-18 |
```

并在待办清单中勾选「开始原型开发」。

- [ ] **Step 9: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/ui/hud.gd game/scenes/ui/hud.tscn game/tests/test_hud.gd game/run.sh game/scenes/main.tscn docs/项目进度.md
git commit -m "feat: 添加 HUD 与试玩验收" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## 自检结果

- **规格覆盖**：移动（Task 8）、投掷（Task 4/5/6）、敌人受击与死亡（Task 7）、清场（Task 9）、HUD（Task 10）、能量回复（Task 3/9）。超能力、武器切换、敌人 AI、多关卡不在本原型计划内，属于下一份计划。
- **占位符检查**：所有代码、场景、资源、命令均为可直接执行的内容，没有 TBD/TODO。
- **类型一致性**：`WeaponData`、`Cooldown`、`Throwable`、`WeaponManager`、`PlayerStats`、`EnemyStats`、`TargetDummy`、`Arena`、`HUD` 的类名和方法名在各任务中保持一致。
- **Review Focus 对应测试**：投掷物层遮罩（Task 5 自动化）、清场只触发一次（Task 9 自动化）、冷却阻断（Task 4/6 自动化）；鼠标误触与中文乱码由 Task 10 人工验收。

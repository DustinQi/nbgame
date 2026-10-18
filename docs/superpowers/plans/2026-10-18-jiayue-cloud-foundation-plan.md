# 嘉悦云上 Godot 工程地基与可视化移动验收计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 先建立自动测试体系、游戏常量和六个输入动作，再做出「玩家第一人称移动 + 一个能走动的空场地」，让王总可以直接打开游戏窗口，用画面验收移动、跳跃和视角手感。

**Architecture:** 前九个任务只写纯 GDScript 逻辑，不碰场景；后三个任务加入玩家场景（`CharacterBody3D` + 相机）和一个最小的 30 米见方场地（地面、四面墙、天空、灯光），并交给王总试玩。玩家脚本用 `preload` 引用常量和输入脚本，避免依赖 Godot 的全局类名缓存。本次不做投掷、敌人和 HUD，这些留到下一份计划。

**Tech Stack:** Godot 4.7.2 stable、GDScript、文本场景 `.tscn`、headless 命令行测试。

**Spec:** `docs/superpowers/specs/2026-08-02-jiayue-cloud-design.md`（本次落实工程约定、输入和第一人称移动；投掷与战斗后续实现）

## Global Constraints

- 引擎固定为 Godot 4.7.2 stable，路径 `/Applications/Godot.app/Contents/MacOS/Godot`，只使用 GDScript。
- 项目根目录是 `game/`，所有资源路径使用 `res://`；不要手动修改 `.godot/` 缓存目录。
- 命名规范：类名 PascalCase；函数和变量 snake_case；私有成员 `_` 前缀；每个方法不超过 50 行；关键逻辑写中文注释。
- 输入动作固定为六个：`move_forward`、`move_back`、`move_left`、`move_right`、`jump`、`throw`。
- WASD 使用 `physical_keycode`（物理键位），保证非 QWERTY 键盘布局下位置不变。
- 玩家数值：移动速度 6 m/s，跳跃初速度 8 m/s，重力 24 m/s²，鼠标灵敏度 0.0025。
- 碰撞层约定：第 1 层 = 玩家，第 2 层 = 场景（地面/墙）；玩家 `collision_layer = 1`、`collision_mask = 2`，地面和墙 `collision_layer = 2`。
- 玩家出生点必须在场地之内、地面之上，不能一进游戏就掉下去或卡在半空。
- 测试统一从 `game/test.sh` 进入；任何测试失败时，脚本必须返回非零退出码。
- 本次改动不涉及投掷、敌人、生命值和 HUD。
- 提交信息格式：`feat/fix/refactor/docs: <中文描述>`，结尾追加 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## Review Focus

以下五类问题最可能让这次地基白做，或者让王总的第一次画面验收体验变差：

1. **测试失败却返回成功（假绿）**：如果测试脚本在失败时仍然退出码为 0，后面所有“测试通过”都不可信。由 Task 1 故意制造一次失败并检查退出码来锁定。
2. **一进游戏就掉出地面或卡在半空**：玩家出生点、胶囊碰撞体、地面碰撞体的高度只要差一点，画面就会立刻穿帮。Task 11 的测试检查地面碰撞体存在、玩家出生高度大于 0，Task 12 由王总实际试玩确认不会掉落。
3. **鼠标转视角方向反了或太灵敏**：左右反向、上下颠倒、灵敏度太高都会让第一人称非常难受。Task 12 给王总的试玩步骤会专门检查上下左右方向。
4. **重复初始化导致一键绑两次**：玩家脚本的 `_ready()` 会调用 `InputSetup.ensure_actions()`，如果以后别的脚本也调用，重复调用会往同一个动作里追加重复按键。Task 9 的重复初始化测试锁定这一点。
5. **非 QWERTY 键盘布局下 WASD 错位**：用 `keycode` 会按字符位置绑定，用 `physical_keycode` 才按物理位置绑定。Task 5、6 的测试断言 `physical_keycode`。

---

## 文件结构

```
game/
├── test.sh                            # 一键运行全部测试（Task 2）
├── run.sh                             # 一键打开游戏窗口（Task 12）
├── project.godot                      # 已存在，主场景指向 res://scenes/main.tscn
├── scenes/
│   ├── main.tscn                      # 最小可走场地（Task 11）
│   └── player/player.tscn             # 玩家场景（Task 10）
├── scripts/
│   ├── core/
│   │   ├── game_constants.gd          # 游戏常量（Task 3、4）
│   │   └── input_setup.gd             # 输入动作注册（Task 5-9）
│   └── player/
│       └── player_controller.gd       # 第一人称移动与视角（Task 10）
└── tests/
    ├── test_runner.gd                 # 测试运行器（Task 1）
    ├── test_smoke.gd                  # 测试框架自检（Task 1）
    ├── test_game_constants.gd         # 常量测试（Task 3、4）
    ├── test_input_setup.gd            # 输入动作测试（Task 5-9）
    ├── test_player_scene.gd           # 玩家场景结构测试（Task 10）
    └── test_main_scene.gd             # 场地结构测试（Task 11）
```

---

### Task 1: 测试运行器

**Files:**
- Create: `game/tests/test_runner.gd`
- Create: `game/tests/test_smoke.gd`

**Interfaces:**
- Consumes: 无
- Produces: 测试文件约定——每个 `tests/test_*.gd` 继承 `RefCounted`，实现 `run(t) -> void`，用 `t.check(条件, 说明)` 和 `t.check_equal(实际, 期望, 说明)` 断言；运行器汇总通过/失败数量，失败时退出码为 1。

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
        if script == null or not script.can_instantiate():
            _failed += 1
            push_error("无法加载测试文件: " + path)
            continue
        var test_case = script.new()
        if test_case == null or not test_case.has_method("run"):
            _failed += 1
            push_error("测试文件缺少 run(t) 方法: " + path)
            continue
        print("== %s ==" % path)
        test_case.run(self)
    print("测试完成：通过 %d，失败 %d" % [_passed, _failed])
    quit(0 if _failed == 0 else 1)

# 收集 tests 目录下所有 test_*.gd
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

- [ ] **Step 2: 写一个自检测试**

创建 `game/tests/test_smoke.gd`：

```gdscript
extends RefCounted

# 测试框架自检：这个测试永远通过，用来确认运行器能发现并执行测试
func run(t) -> void:
    t.check(true, "测试框架可以执行测试")
```

- [ ] **Step 3: 运行测试，确认成功路径**

运行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/work/repo/nbgame/game -s tests/test_runner.gd
echo "退出码: $?"
```

预期输出包含：

```
== res://tests/test_smoke.gd ==
测试完成：通过 1，失败 0
退出码: 0
```

- [ ] **Step 4: 故意制造失败，确认退出码为 1**

把 `game/tests/test_smoke.gd` 里的 `t.check(true, ...)` 临时改成 `t.check(false, ...)`，再次运行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Volumes/work/repo/nbgame/game -s tests/test_runner.gd
echo "退出码: $?"
```

预期输出包含 `测试完成：通过 0，失败 1` 和 `退出码: 1`。

确认后把测试改回 `t.check(true, ...)`，再跑一次，确认恢复为 `通过 1，失败 0`、退出码 0。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/tests/test_runner.gd game/tests/test_smoke.gd
git commit -m "feat: 添加无界面测试运行器" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 一键测试脚本

**Files:**
- Create: `game/test.sh`

**Interfaces:**
- Consumes: `game/tests/test_runner.gd`（Task 1）
- Produces: 从任意目录执行 `/Volumes/work/repo/nbgame/game/test.sh` 都能正确运行全部测试。

- [ ] **Step 1: 创建测试脚本**

创建 `game/test.sh`：

```bash
#!/bin/bash
# 运行全部自动化测试
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PWD" -s tests/test_runner.gd
```

- [ ] **Step 2: 添加执行权限**

```bash
chmod +x /Volumes/work/repo/nbgame/game/test.sh
```

- [ ] **Step 3: 从项目外目录运行，确认路径无关**

```bash
cd /tmp
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：`测试完成：通过 1，失败 0`，退出码 0。如果这一步失败，说明 `cd "$(dirname "$0")"` 没生效，必须先修好再继续。

- [ ] **Step 4: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/test.sh
git commit -m "feat: 添加一键测试脚本" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 移动与视角常量

**Files:**
- Create: `game/scripts/core/game_constants.gd`
- Create: `game/tests/test_game_constants.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name GameConstants extends RefCounted`，常量 `GRAVITY = 24.0`、`WALK_SPEED = 6.0`、`JUMP_VELOCITY = 8.0`、`MOUSE_SENSITIVITY = 0.0025`。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_game_constants.gd`：

```gdscript
extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")

# 验证移动与视角常量的精确数值
func run(t) -> void:
    t.check_equal(GAME_CONSTANTS.GRAVITY, 24.0, "重力为 24")
    t.check_equal(GAME_CONSTANTS.WALK_SPEED, 6.0, "移动速度为 6")
    t.check_equal(GAME_CONSTANTS.JUMP_VELOCITY, 8.0, "跳跃初速度为 8")
    t.check_equal(GAME_CONSTANTS.MOUSE_SENSITIVITY, 0.0025, "鼠标灵敏度为 0.0025")
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：出现“无法加载测试文件”的报错，`通过 1，失败 1`，退出码 1（冒烟测试仍然通过）。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/core/game_constants.gd`：

```gdscript
class_name GameConstants
extends RefCounted

# 移动与视角数值，后续玩家控制器统一从这里取
const GRAVITY := 24.0
const WALK_SPEED := 6.0
const JUMP_VELOCITY := 8.0
const MOUSE_SENSITIVITY := 0.0025
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 5，失败 0`（自检 1 条 + 常量 4 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/game_constants.gd game/tests/test_game_constants.gd
git commit -m "feat: 添加移动与视角常量" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 生命与能量常量

**Files:**
- Modify: `game/scripts/core/game_constants.gd`
- Modify: `game/tests/test_game_constants.gd`

**Interfaces:**
- Consumes: `GameConstants`（Task 3）
- Produces: 新增常量 `MAX_HEALTH = 100.0`、`MAX_ENERGY = 100.0`、`ENERGY_PER_KILL = 15.0`。

- [ ] **Step 1: 扩展失败测试**

把 `game/tests/test_game_constants.gd` 改成：

```gdscript
extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")

# 验证移动、视角、生命与能量常量的精确数值
func run(t) -> void:
    # 移动与视角
    t.check_equal(GAME_CONSTANTS.GRAVITY, 24.0, "重力为 24")
    t.check_equal(GAME_CONSTANTS.WALK_SPEED, 6.0, "移动速度为 6")
    t.check_equal(GAME_CONSTANTS.JUMP_VELOCITY, 8.0, "跳跃初速度为 8")
    t.check_equal(GAME_CONSTANTS.MOUSE_SENSITIVITY, 0.0025, "鼠标灵敏度为 0.0025")
    # 生命与能量
    t.check_equal(GAME_CONSTANTS.MAX_HEALTH, 100.0, "生命上限为 100")
    t.check_equal(GAME_CONSTANTS.MAX_ENERGY, 100.0, "能量上限为 100")
    t.check_equal(GAME_CONSTANTS.ENERGY_PER_KILL, 15.0, "每次击杀回复 15 能量")
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：测试文件因引用了不存在的常量而加载失败，`通过 1，失败 1`，退出码 1。

- [ ] **Step 3: 补上常量**

把 `game/scripts/core/game_constants.gd` 改成：

```gdscript
class_name GameConstants
extends RefCounted

# 移动与视角数值，后续玩家控制器统一从这里取
const GRAVITY := 24.0
const WALK_SPEED := 6.0
const JUMP_VELOCITY := 8.0
const MOUSE_SENSITIVITY := 0.0025

# 生命与能量数值，后续玩家属性和 HUD 统一从这里取
const MAX_HEALTH := 100.0
const MAX_ENERGY := 100.0
const ENERGY_PER_KILL := 15.0
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 8，失败 0`（自检 1 条 + 常量 7 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/game_constants.gd game/tests/test_game_constants.gd
git commit -m "feat: 添加生命与能量常量" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 前进与后退输入动作

**Files:**
- Create: `game/scripts/core/input_setup.gd`
- Create: `game/tests/test_input_setup.gd`

**Interfaces:**
- Consumes: 无
- Produces: `class_name InputSetup extends RefCounted`；动作名常量 `ACTION_MOVE_FORWARD = &"move_forward"`、`ACTION_MOVE_BACK = &"move_back"`；静态方法 `ensure_actions() -> void`，注册 W 和 S（使用 `physical_keycode`）。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_input_setup.gd`：

```gdscript
extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")

# 检查一个键盘动作：存在、只有一个绑定、绑定的是指定物理键位
func _check_key_action(t, action: StringName, expected_key: Key) -> void:
    t.check(InputMap.has_action(action), "存在动作: " + String(action))
    if not InputMap.has_action(action):
        return
    var events := InputMap.action_get_events(action)
    t.check_equal(events.size(), 1, "只有一个绑定: " + String(action))
    if events.size() != 1:
        return
    var key_event := events[0] as InputEventKey
    t.check(key_event != null, "是键盘事件: " + String(action))
    if key_event != null:
        t.check_equal(key_event.physical_keycode, expected_key, "键位正确: " + String(action))

# 验证前进和后退动作
func run(t) -> void:
    INPUT_SETUP.ensure_actions()
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_FORWARD, KEY_W)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_BACK, KEY_S)
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：`input_setup.gd` 不存在导致测试文件加载失败，`通过 8，失败 1`，退出码 1。

- [ ] **Step 3: 写最小实现**

创建 `game/scripts/core/input_setup.gd`：

```gdscript
class_name InputSetup
extends RefCounted

# 动作名称统一用常量，避免各处拼写不一致
const ACTION_MOVE_FORWARD := &"move_forward"
const ACTION_MOVE_BACK := &"move_back"

# 注册本次需要的输入动作
static func ensure_actions() -> void:
    _add_key(ACTION_MOVE_FORWARD, KEY_W)
    _add_key(ACTION_MOVE_BACK, KEY_S)

# 用物理键位绑定，保证非 QWERTY 键盘布局下位置不变
static func _add_key(action: StringName, keycode: Key) -> void:
    InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 16，失败 0`（自检 1 + 常量 7 + 两个动作各 4 条检查）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/input_setup.gd game/tests/test_input_setup.gd
git commit -m "feat: 添加前进与后退输入动作" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 左右移动输入动作

**Files:**
- Modify: `game/scripts/core/input_setup.gd`
- Modify: `game/tests/test_input_setup.gd`

**Interfaces:**
- Consumes: `InputSetup`（Task 5）
- Produces: 新增动作名常量 `ACTION_MOVE_LEFT = &"move_left"`、`ACTION_MOVE_RIGHT = &"move_right"`，并在 `ensure_actions()` 中注册 A、D。

- [ ] **Step 1: 扩展失败测试**

在 `game/tests/test_input_setup.gd` 的 `run(t)` 末尾增加两行：

```gdscript
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_LEFT, KEY_A)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_RIGHT, KEY_D)
```

改完后 `run(t)` 应该是：

```gdscript
func run(t) -> void:
    INPUT_SETUP.ensure_actions()
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_FORWARD, KEY_W)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_BACK, KEY_S)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_LEFT, KEY_A)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_RIGHT, KEY_D)
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：测试文件因引用不存在的常量而加载失败，`通过 8，失败 1`，退出码 1。

- [ ] **Step 3: 补上左右动作**

把 `game/scripts/core/input_setup.gd` 改成：

```gdscript
class_name InputSetup
extends RefCounted

# 动作名称统一用常量，避免各处拼写不一致
const ACTION_MOVE_FORWARD := &"move_forward"
const ACTION_MOVE_BACK := &"move_back"
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"

# 注册本次需要的输入动作
static func ensure_actions() -> void:
    _add_key(ACTION_MOVE_FORWARD, KEY_W)
    _add_key(ACTION_MOVE_BACK, KEY_S)
    _add_key(ACTION_MOVE_LEFT, KEY_A)
    _add_key(ACTION_MOVE_RIGHT, KEY_D)

# 用物理键位绑定，保证非 QWERTY 键盘布局下位置不变
static func _add_key(action: StringName, keycode: Key) -> void:
    InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 24，失败 0`（自检 1 + 常量 7 + 四个动作各 4 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/input_setup.gd game/tests/test_input_setup.gd
git commit -m "feat: 添加左右移动输入动作" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: 跳跃输入动作

**Files:**
- Modify: `game/scripts/core/input_setup.gd`
- Modify: `game/tests/test_input_setup.gd`

**Interfaces:**
- Consumes: `InputSetup`（Task 6）
- Produces: 新增动作名常量 `ACTION_JUMP = &"jump"`，绑定空格键。

- [ ] **Step 1: 扩展失败测试**

在 `game/tests/test_input_setup.gd` 的 `run(t)` 末尾增加一行：

```gdscript
    _check_key_action(t, INPUT_SETUP.ACTION_JUMP, KEY_SPACE)
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：测试文件因引用不存在的常量而加载失败，`通过 8，失败 1`，退出码 1。

- [ ] **Step 3: 补上跳跃动作**

在 `game/scripts/core/input_setup.gd` 中做三处修改：

1. 在动作常量区增加：

```gdscript
const ACTION_JUMP := &"jump"
```

2. 在 `ensure_actions()` 中增加：

```gdscript
    _add_key(ACTION_JUMP, KEY_SPACE)
```

3. 其余代码不变。

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 28，失败 0`（自检 1 + 常量 7 + 五个键盘动作各 4 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/input_setup.gd game/tests/test_input_setup.gd
git commit -m "feat: 添加跳跃输入动作" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: 投掷输入动作（鼠标左键）

**Files:**
- Modify: `game/scripts/core/input_setup.gd`
- Modify: `game/tests/test_input_setup.gd`

**Interfaces:**
- Consumes: `InputSetup`（Task 7）
- Produces: 新增动作名常量 `ACTION_THROW = &"throw"`，绑定鼠标左键。

- [ ] **Step 1: 扩展失败测试**

在 `game/tests/test_input_setup.gd` 中增加一个鼠标动作检查函数：

```gdscript
# 检查一个鼠标动作：存在、只有一个绑定、绑定的是指定鼠标键
func _check_mouse_action(t, action: StringName, expected_button: MouseButton) -> void:
    t.check(InputMap.has_action(action), "存在动作: " + String(action))
    if not InputMap.has_action(action):
        return
    var events := InputMap.action_get_events(action)
    t.check_equal(events.size(), 1, "只有一个绑定: " + String(action))
    if events.size() != 1:
        return
    var mouse_event := events[0] as InputEventMouseButton
    t.check(mouse_event != null, "是鼠标事件: " + String(action))
    if mouse_event != null:
        t.check_equal(mouse_event.button_index, expected_button, "鼠标键正确: " + String(action))
```

并在 `run(t)` 末尾增加一行：

```gdscript
    _check_mouse_action(t, INPUT_SETUP.ACTION_THROW, MOUSE_BUTTON_LEFT)
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：测试文件因引用不存在的常量而加载失败，`通过 8，失败 1`，退出码 1。

- [ ] **Step 3: 补上投掷动作**

在 `game/scripts/core/input_setup.gd` 中做三处修改：

1. 在动作常量区增加：

```gdscript
const ACTION_THROW := &"throw"
```

2. 在 `ensure_actions()` 中增加：

```gdscript
    _add_mouse(ACTION_THROW, MOUSE_BUTTON_LEFT)
```

3. 在文件末尾增加鼠标绑定函数：

```gdscript
# 鼠标按键绑定
static func _add_mouse(action: StringName, mouse_button: MouseButton) -> void:
    InputMap.add_action(action)
    var event := InputEventMouseButton.new()
    event.button_index = mouse_button
    InputMap.action_add_event(action, event)
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 32，失败 0`（自检 1 + 常量 7 + 五个键盘动作各 4 条 + 投掷 4 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/input_setup.gd game/tests/test_input_setup.gd
git commit -m "feat: 添加投掷输入动作" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: 重复初始化保护

**Files:**
- Modify: `game/scripts/core/input_setup.gd`
- Modify: `game/tests/test_input_setup.gd`

**Interfaces:**
- Consumes: `InputSetup`（Task 8）
- Produces: `ensure_actions()` 变为幂等操作——无论调用多少次，每个动作始终只有一个按键绑定。

- [ ] **Step 1: 写失败测试**

在 `game/tests/test_input_setup.gd` 中增加一个检查函数：

```gdscript
# 检查一个动作只有一个绑定（用于重复初始化验证）
func _check_single_binding(t, action: StringName) -> void:
    t.check_equal(InputMap.action_get_events(action).size(), 1, "重复初始化不重复绑定: " + String(action))
```

并在 `run(t)` 末尾增加：

```gdscript
    # 玩家脚本的 _ready() 也会调用 ensure_actions，重复调用不能重复绑定
    INPUT_SETUP.ensure_actions()
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_FORWARD)
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_BACK)
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_LEFT)
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_RIGHT)
    _check_single_binding(t, INPUT_SETUP.ACTION_JUMP)
    _check_single_binding(t, INPUT_SETUP.ACTION_THROW)
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：`通过 32，失败 6`，退出码 1。六条失败都来自“重复初始化不重复绑定”，实际数量是 2。

- [ ] **Step 3: 加上幂等保护**

把 `game/scripts/core/input_setup.gd` 的两个绑定函数改成：

```gdscript
# 用物理键位绑定，保证非 QWERTY 键盘布局下位置不变
static func _add_key(action: StringName, keycode: Key) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)

# 鼠标按键绑定
static func _add_mouse(action: StringName, mouse_button: MouseButton) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var event := InputEventMouseButton.new()
    event.button_index = mouse_button
    InputMap.action_add_event(action, event)
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 38，失败 0`（自检 1 + 常量 7 + 六个动作各 4 条 + 幂等 6 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/core/input_setup.gd game/tests/test_input_setup.gd
git commit -m "fix: 输入动作重复初始化不再重复绑定" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: 玩家场景与第一人称控制

**Files:**
- Create: `game/scripts/player/player_controller.gd`
- Create: `game/scenes/player/player.tscn`
- Create: `game/tests/test_player_scene.gd`

**Interfaces:**
- Consumes: `GameConstants`（Task 3、4）、`InputSetup`（Task 5-9），均通过 `preload` 引用
- Produces: `class_name PlayerController extends CharacterBody3D`；节点结构 `Player/Head/Camera3D`；玩家在组 `player` 中；玩家 `collision_layer = 1`、`collision_mask = 2`。本次玩家不带武器和生命值，只负责走动、跳跃和转视角。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_player_scene.gd`：

```gdscript
extends RefCounted

# 验证玩家场景的节点结构和碰撞设置
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/player/player.tscn")
    t.check(packed != null, "玩家场景可加载")
    if packed == null:
        return
    var player = packed.instantiate()
    t.root.add_child(player)
    t.check(player is CharacterBody3D, "玩家是 CharacterBody3D")
    t.check(player.get_node_or_null("CollisionShape3D") is CollisionShape3D, "玩家有碰撞体")
    t.check(player.get_node_or_null("Head/Camera3D") is Camera3D, "有第一人称相机")
    t.check_equal(player.collision_layer, 1, "玩家在玩家层")
    t.check_equal(player.collision_mask, 2, "玩家会与场景碰撞")
    player.free()
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：玩家场景不存在，`玩家场景可加载` 一条失败，`通过 38，失败 1`，退出码 1。

- [ ] **Step 3: 写玩家脚本**

创建 `game/scripts/player/player_controller.gd`：

```gdscript
class_name PlayerController
extends CharacterBody3D

# 用 preload 引用常量和输入脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")
const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")

const PITCH_MIN := -1.45
const PITCH_MAX := 1.45

@onready var camera: Camera3D = get_node_or_null("Head/Camera3D") as Camera3D

var _pitch := 0.0

func _ready() -> void:
    INPUT_SETUP.ensure_actions()
    # 无界面测试时不捕获鼠标
    if DisplayServer.get_name() != "headless":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# 鼠标视角、点击重新捕获、Esc 释放
func _unhandled_input(event: InputEvent) -> void:
    # 鼠标释放状态下点击窗口，重新捕获鼠标，但这一下不触发游戏操作
    if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * GAME_CONSTANTS.MOUSE_SENSITIVITY)
        _pitch = clampf(
            _pitch - event.relative.y * GAME_CONSTANTS.MOUSE_SENSITIVITY,
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
        velocity.y -= GAME_CONSTANTS.GRAVITY * delta
    if Input.is_action_just_pressed(INPUT_SETUP.ACTION_JUMP) and is_on_floor():
        velocity.y = GAME_CONSTANTS.JUMP_VELOCITY

    var input_dir := Input.get_vector(
        INPUT_SETUP.ACTION_MOVE_LEFT,
        INPUT_SETUP.ACTION_MOVE_RIGHT,
        INPUT_SETUP.ACTION_MOVE_FORWARD,
        INPUT_SETUP.ACTION_MOVE_BACK
    )
    var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
    if direction.length_squared() > 0.0:
        velocity.x = direction.x * GAME_CONSTANTS.WALK_SPEED
        velocity.z = direction.z * GAME_CONSTANTS.WALK_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, GAME_CONSTANTS.WALK_SPEED * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, GAME_CONSTANTS.WALK_SPEED * 4.0 * delta)
    move_and_slide()
```

- [ ] **Step 4: 写玩家场景**

创建 `game/scenes/player/player.tscn`：

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player/player_controller.gd" id="1"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_1"]
radius = 0.4
height = 1.8

[node name="Player" type="CharacterBody3D" groups=["player"]]
collision_layer = 1
collision_mask = 2
script = ExtResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
shape = SubResource("CapsuleShape3D_1")

[node name="Head" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 0)

[node name="Camera3D" type="Camera3D" parent="Head"]
current = true
```

- [ ] **Step 5: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 44，失败 0`（之前的 38 条 + 玩家场景 6 条）。

- [ ] **Step 6: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scripts/player/player_controller.gd game/scenes/player/player.tscn game/tests/test_player_scene.gd
git commit -m "feat: 添加第一人称玩家场景" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: 最小可走场地

**Files:**
- Create: `game/scenes/main.tscn`（替换之前的试验场景）
- Create: `game/tests/test_main_scene.gd`

**Interfaces:**
- Consumes: 玩家场景（Task 10）
- Produces: 主场景根节点 `Main`，包含 `WorldEnvironment`、`DirectionalLight3D`、`Ground`、四面墙 `WallNorth` / `WallSouth` / `WallEast` / `WallWest` 和 `Player` 实例；场地 30 米见方，玩家出生点 `y = 0.1`，地面顶部在 `y = 0`。

- [ ] **Step 1: 写失败测试**

创建 `game/tests/test_main_scene.gd`：

```gdscript
extends RefCounted

# 验证最小场地结构：玩家、地面、四面墙、灯光、天空
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    t.check(packed != null, "主场景可加载")
    if packed == null:
        return
    var main = packed.instantiate()
    t.root.add_child(main)

    var player := main.get_node_or_null("Player")
    t.check(player is CharacterBody3D, "场地里有玩家")
    if player != null:
        t.check(player.position.y > 0.0, "玩家出生点在地面之上")

    t.check(main.get_node_or_null("Ground") is StaticBody3D, "场地有地面")
    t.check(main.get_node_or_null("Ground/CollisionShape3D") is CollisionShape3D, "地面有碰撞体")
    t.check(main.get_node_or_null("DirectionalLight3D") is DirectionalLight3D, "场地有灯光")
    t.check(main.get_node_or_null("WorldEnvironment") is WorldEnvironment, "场地有天空环境")

    for wall_name in ["WallNorth", "WallSouth", "WallEast", "WallWest"]:
        t.check(main.get_node_or_null(wall_name) is StaticBody3D, "有墙体: " + wall_name)
        t.check(
            main.get_node_or_null(wall_name + "/CollisionShape3D") is CollisionShape3D,
            "墙体有碰撞体: " + wall_name
        )

    main.free()
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：当前 `main.tscn` 还是之前的试验场景，会出现“场地里有玩家”“地面有碰撞体”等多项失败，退出码 1。

- [ ] **Step 3: 写主场景**

用以下内容替换 `game/scenes/main.tscn`：

```
[gd_scene load_steps=11 format=3]

[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="1"]

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

[node name="Main" type="Node3D"]

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

[node name="Player" parent="." instance=ExtResource("1")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 10)
```

- [ ] **Step 4: 运行测试，确认通过**

```bash
/Volumes/work/repo/nbgame/game/test.sh
```

预期：`测试完成：通过 59，失败 0`（之前的 44 条 + 场地结构 15 条）。

- [ ] **Step 5: 提交**

```bash
cd /Volumes/work/repo/nbgame
git add game/scenes/main.tscn game/tests/test_main_scene.gd
git commit -m "feat: 添加可走动的第一人称场地" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: 运行脚本、画面验收与进度记录

**Files:**
- Create: `game/run.sh`
- Modify: `docs/项目进度.md`

**Interfaces:**
- Consumes: 全部前置任务
- Produces: 王总可以双击/命令运行游戏，用画面验收移动、跳跃和视角；进度文档记录本次完成内容。

- [ ] **Step 1: 创建运行脚本**

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

- [ ] **Step 2: 跑完整测试套件**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：

```
测试完成：通过 59，失败 0
退出码: 0
```

确认输出里没有 `SCRIPT ERROR` 字样。如果有，先修完再继续。

- [ ] **Step 3: 运行游戏，交给王总试玩验收**

```bash
/Volumes/work/repo/nbgame/game/run.sh
```

请王总按以下步骤测试，发现问题先截图（`Cmd+Shift+4`），终端有红字就复制给我：

1. 游戏窗口打开后点击一下窗口，鼠标应该消失（被捕获）。
2. 移动鼠标：左右转视角方向要跟手的移动方向一致；上下看时，鼠标上移应该抬头、下移应该低头。
3. 按 `W` 向前走、`S` 后退、`A` 左移、`D` 右移；松开按键后应该停下。
4. 按空格跳跃，落地后不卡住；走到墙边会被挡住，不会穿墙。
5. 走进场地边缘不会掉出地面。
6. 按 `Esc` 鼠标应该重新出现；再点击窗口，鼠标重新被捕获，且这一下不会让角色乱动。
7. 整体视角不晕、移动速度不飘，记下哪里需要调（速度、跳跃高度、灵敏度都可以改）。

本次还扔不了东西，也没有敌人和屏幕 UI，属于正常现象。

- [ ] **Step 4: 检查本次没有意外改动**

```bash
cd /Volumes/work/repo/nbgame
git status --short
```

预期：只有 `docs/项目进度.md` 是未提交状态，没有其他意外文件。

- [ ] **Step 5: 更新进度文档**

在 `docs/项目进度.md` 的“功能清单”表格中，在“Unity 残留清理”行后面插入两行：

```
| ✅ | 工程地基 | 自动化测试框架、游戏常量、六个输入动作 | 2026-10-18 |
| ✅ | 可视化移动验收 | 第一人称视角 + 可走动的 30 米场地 | 2026-10-18 |
```

把“当前状态”改成：

```
- 🟢 **项目阶段**：可视化地基已完成（能看、能走、能跳），下一步做投掷武器和靶子
```

把待办清单中的“编写 Godot 版实现计划”勾上：

```
- [x] 编写 Godot 版实现计划
```

- [ ] **Step 6: 提交进度**

```bash
cd /Volumes/work/repo/nbgame
git add game/run.sh docs/项目进度.md
git commit -m "docs: 记录可视化移动验收完成" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## 自检结果

- **规格覆盖**：测试框架（Task 1、2）、移动/生命/能量常量（Task 3、4）、六个输入动作及其键位（Task 5-8）、重复调用安全（Task 9）、玩家第一人称移动（Task 10）、可走场地（Task 11）、画面验收（Task 12）。本次明确不涉及投掷、敌人、生命值显示和 HUD。
- **占位符检查**：所有代码、场景、命令、预期输出均完整写出，没有 TBD/TODO，没有“参考 Task N”的占位写法。
- **类型一致性**：`GameConstants` 的常量名、`InputSetup` 的动作名常量与 `ensure_actions()` 签名在各任务中保持一致；测试和玩家脚本统一通过 `preload` 引用，不依赖全局类名缓存。
- **Review Focus 对应测试**：假绿（Task 1 退出码验证）、玩家掉出地面（Task 11 出生点与地面碰撞体检查 + Task 12 试玩）、鼠标方向（Task 12 试玩）、重复绑定（Task 9）、物理键位（Task 5、6）。

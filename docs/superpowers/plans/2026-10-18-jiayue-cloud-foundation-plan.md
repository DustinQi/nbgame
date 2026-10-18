# 嘉悦云上 Godot 工程地基实现计划（测试框架 + 输入映射）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立自动运行的 headless 测试体系、集中管理游戏常量、注册 WASD / 跳跃 / 投掷六个输入动作，为下一步的玩家和武器开发打好地基。

**Architecture:** 本次只写纯 GDScript 逻辑，不创建任何游戏场景。一个 `SceneTree` 测试运行器自动发现 `tests/test_*.gd` 并逐个执行；测试文件通过 `preload` 引用被测脚本，避免依赖 Godot 的全局类名缓存。输入动作名称统一放在 `InputSetup` 常量里，后续玩家脚本直接复用，避免拼写不一致。

**Tech Stack:** Godot 4.7.2 stable、GDScript、headless 命令行测试。

**Spec:** `docs/superpowers/specs/2026-08-02-jiayue-cloud-design.md`（本次只落实工程约定与输入部分；玩法实现见后续计划）

## Global Constraints

- 引擎固定为 Godot 4.7.2 stable，路径 `/Applications/Godot.app/Contents/MacOS/Godot`，只使用 GDScript。
- 项目根目录是 `game/`，所有资源路径使用 `res://`；不要手动修改 `.godot/` 缓存目录。
- 命名规范：类名 PascalCase；函数和变量 snake_case；私有成员 `_` 前缀；每个方法不超过 50 行；关键逻辑写中文注释。
- 输入动作固定为六个：`move_forward`、`move_back`、`move_left`、`move_right`、`jump`、`throw`。
- WASD 使用 `physical_keycode`（物理键位），保证非 QWERTY 键盘布局下位置不变。
- 测试统一从 `game/test.sh` 进入；任何测试失败时，脚本必须返回非零退出码。
- 本次改动不涉及场景、玩家、武器或 HUD，这些留给后续计划。
- 提交信息格式：`feat/fix/refactor/docs: <中文描述>`，结尾追加 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## Review Focus

以下五类问题最可能让这次地基白做，或者让后面的任务踩坑：

1. **测试失败却返回成功（假绿）**：如果测试脚本在失败时仍然退出码为 0，后面所有“测试通过”都不可信。由 Task 1 故意制造一次失败并检查退出码来锁定。
2. **重复初始化导致一键绑两次**：玩家和武器管理器的 `_ready()` 都会调用 `InputSetup.ensure_actions()`，如果重复调用会往同一个动作里追加重复按键，按一次键可能触发两次。由 Task 9 的重复初始化测试锁定。
3. **动作名拼写不一致**：测试里写 `move_forward`、游戏代码里写 `moveForward`，运行时就会“按键没反应”。本次用 `InputSetup` 的动作名常量统一，测试也引用常量，不手写字符串。
4. **非 QWERTY 键盘布局下 WASD 错位**：用 `keycode` 会按字符位置绑定，用 `physical_keycode` 才按物理位置绑定。Task 5、6 的测试断言 `physical_keycode`。
5. **从其他目录运行测试脚本找不到项目**：`test.sh` 必须自己切换到脚本所在目录，否则 `res://` 和 `--path` 都会指错地方。Task 2 从 `/tmp` 目录运行一次来验证。

---

## 文件结构

```
game/
├── test.sh                            # 一键运行全部测试（Task 2）
├── scripts/core/
│   ├── game_constants.gd              # 游戏常量（Task 3、4）
│   └── input_setup.gd                 # 输入动作注册（Task 5-9）
└── tests/
    ├── test_runner.gd                 # 测试运行器（Task 1）
    ├── test_smoke.gd                  # 测试框架自检（Task 1）
    ├── test_game_constants.gd         # 常量测试（Task 3、4）
    └── test_input_setup.gd            # 输入动作测试（Task 5-9）
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
    # 玩家和武器管理器都会调用 ensure_actions，重复调用不能重复绑定
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

### Task 10: 整体验收与进度记录

**Files:**
- Modify: `docs/项目进度.md`

**Interfaces:**
- Consumes: 全部前置任务
- Produces: 进度文档记录本次完成的地基工作，并明确下一步是玩家与武器。

- [ ] **Step 1: 跑完整测试套件**

```bash
/Volumes/work/repo/nbgame/game/test.sh
echo "退出码: $?"
```

预期：

```
测试完成：通过 38，失败 0
退出码: 0
```

同时确认输出里没有 `SCRIPT ERROR` 字样。如果有，先修完再继续。

- [ ] **Step 2: 检查本次没有意外改动**

```bash
cd /Volumes/work/repo/nbgame
git status --short
```

预期：只有 `docs/项目进度.md` 是未提交状态，没有其他意外文件。

- [ ] **Step 3: 更新进度文档**

在 `docs/项目进度.md` 的“功能清单”表格中，在“Unity 残留清理”行后面插入一行：

```
| ✅ | 工程地基 | 自动化测试框架、游戏常量、六个输入动作 | 2026-10-18 |
```

把“当前状态”改成：

```
- 🟢 **项目阶段**：工程地基已完成（测试框架、常量、输入），准备开始玩家与武器开发
```

把待办清单中的“编写 Godot 版实现计划”勾上：

```
- [x] 编写 Godot 版实现计划
```

- [ ] **Step 4: 提交进度**

```bash
cd /Volumes/work/repo/nbgame
git add docs/项目进度.md
git commit -m "docs: 更新工程地基完成进度" -m "Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## 自检结果

- **规格覆盖**：测试框架（Task 1、2）、移动/生命/能量常量（Task 3、4）、六个输入动作及其键位（Task 5-8）、重复调用安全（Task 9）、进度记录（Task 10）。本次明确不涉及场景、玩家、武器和 HUD。
- **占位符检查**：所有代码、命令、预期输出均完整写出，没有 TBD/TODO，没有“参考 Task N”的占位写法。
- **类型一致性**：`GameConstants` 的常量名、`InputSetup` 的动作名常量与 `ensure_actions()` 签名在各任务中保持一致；测试统一通过 `preload` 引用，不依赖全局类名缓存。
- **Review Focus 对应测试**：假绿（Task 1 退出码验证）、重复绑定（Task 9）、动作名统一（动作名常量）、物理键位（Task 5、6）、任意目录运行（Task 2）。

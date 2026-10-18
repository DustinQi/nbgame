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

# 检查一个动作只有一个绑定（用于重复初始化验证）
func _check_single_binding(t, action: StringName) -> void:
    t.check_equal(InputMap.action_get_events(action).size(), 1, "重复初始化不重复绑定: " + String(action))

# 已有自定义绑定时，重复初始化不能追加或覆盖它
func _check_preserves_existing_binding(t, action: StringName, custom_button: MouseButton) -> void:
    InputMap.action_erase_events(action)
    var custom := InputEventMouseButton.new()
    custom.button_index = custom_button
    InputMap.action_add_event(action, custom)
    INPUT_SETUP.ensure_actions()
    var events := InputMap.action_get_events(action)
    t.check_equal(events.size(), 1, "已有动作不会被追加绑定: " + String(action))
    if events.size() == 1:
        var mouse_event := events[0] as InputEventMouseButton
        t.check(
            mouse_event != null and mouse_event.button_index == custom_button,
            "已有绑定不会被覆盖: " + String(action)
        )
    # 恢复默认绑定，避免影响其他测试
    InputMap.erase_action(action)
    INPUT_SETUP.ensure_actions()

# 验证前进和后退动作
func run(t) -> void:
    INPUT_SETUP.ensure_actions()
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_FORWARD, KEY_W)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_BACK, KEY_S)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_LEFT, KEY_A)
    _check_key_action(t, INPUT_SETUP.ACTION_MOVE_RIGHT, KEY_D)
    _check_key_action(t, INPUT_SETUP.ACTION_JUMP, KEY_SPACE)
    _check_mouse_action(t, INPUT_SETUP.ACTION_THROW, MOUSE_BUTTON_LEFT)
    # 玩家脚本的 _ready() 也会调用 ensure_actions，重复调用不能重复绑定
    INPUT_SETUP.ensure_actions()
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_FORWARD)
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_BACK)
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_LEFT)
    _check_single_binding(t, INPUT_SETUP.ACTION_MOVE_RIGHT)
    _check_single_binding(t, INPUT_SETUP.ACTION_JUMP)
    _check_single_binding(t, INPUT_SETUP.ACTION_THROW)
    _check_preserves_existing_binding(t, INPUT_SETUP.ACTION_THROW, MOUSE_BUTTON_RIGHT)

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

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

class_name InputSetup
extends RefCounted

# 动作名称统一用常量，避免各处拼写不一致
const ACTION_MOVE_FORWARD := &"move_forward"
const ACTION_MOVE_BACK := &"move_back"
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_JUMP := &"jump"
const ACTION_THROW := &"throw"

# 注册本次需要的输入动作
static func ensure_actions() -> void:
    _add_key(ACTION_MOVE_FORWARD, KEY_W)
    _add_key(ACTION_MOVE_BACK, KEY_S)
    _add_key(ACTION_MOVE_LEFT, KEY_A)
    _add_key(ACTION_MOVE_RIGHT, KEY_D)
    _add_key(ACTION_JUMP, KEY_SPACE)
    _add_mouse(ACTION_THROW, MOUSE_BUTTON_LEFT)

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

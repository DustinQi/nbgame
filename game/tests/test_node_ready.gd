extends RefCounted

# 验证测试环境下 add_child 能正常触发节点 _ready（曾发现 _initialize 阶段树未 ready、_ready 被推迟且帧循环不运行）

class ReadyProbe extends Node:
    var ready_called := false

    func _ready() -> void:
        ready_called = true

func run(t) -> void:
    var probe := ReadyProbe.new()
    t.root.add_child(probe)
    t.check(probe.ready_called, "add_child 后 _ready 已触发")
    probe.free()

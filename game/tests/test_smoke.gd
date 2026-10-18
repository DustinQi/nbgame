extends RefCounted

# 测试框架自检：这个测试永远通过，用来确认运行器能发现并执行测试
func run(t) -> void:
    t.check(true, "测试框架可以执行测试")

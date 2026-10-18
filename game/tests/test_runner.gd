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
        # 跳过运行器自身，它不是测试用例
        if file_name == "test_runner.gd":
            continue
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

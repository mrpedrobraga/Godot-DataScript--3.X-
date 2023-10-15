extends DataScriptRuntime

func _ready():
	var routine = load_routine_from_json("res://test/tester_routine.json")

	meta_functions = ["if", "else"]

	var result = yield(execute(routine), "completed")
	print("Finished, with result: ", result)

func write(what):
	print(what)
	return what

func if(_context: ExecutionContext, condition, block):
	if execute(condition):
		_context.last_condition_check_was_successful = true
		return execute(block)
	return null

func else(_context: ExecutionContext, block):
	if not _context.last_condition_check_was_successful:
		return execute(block)
	return _context.last_result

func add(a, b):
	return a + b

func sub(a, b):
	return a - b

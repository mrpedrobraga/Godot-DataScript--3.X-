extends Node
class_name DataScriptRuntime

## Class that executes a routine from a JSON file.
##
## Call execute_routine to execute a routine from a data file,
## by implementing the keywords in GDScript.
## [br][br]
## Usage:[br]
## - Extend this script and add your own functions.[br]
## - Call them from the script file.[br]
## [br]
## Example:[br]
## [code]
## func log(what: String):
##     print(what)
## \[
##     \["log", \["Hello World!"\]\]
## \] 
## [/code]

## Loads a routine from file
func load_routine_from_json(path: String):
	var f = File.new()
	f.open(path, File.READ)
	var raw = f.get_as_text()
	f.close()
	var j: JSONParseResult = JSON.parse(raw)
	if j.error != OK:
		push_error("JSON at {path} was invalid".format({path: path}))
	return j.result

export var meta_functions = ["if", "else"]

class ExecutionContext:
	var last_condition_check_was_successful = false
	var last_result = null
	var last_keyword = ""

## Executes a block of instructions.
func execute(block, _context: ExecutionContext = null):
	yield(get_tree(), "idle_frame")

	# If trying to "execute" a string, number or boolean,
	# just return it unchanged.
	if not block is Array:
		return block
	
	# Initialize context if missing
	if not _context:
		_context = ExecutionContext.new()

	# You can detect that this routine is a 'block'
	# by checking if the first element is an array
	# or is the string ()
	if not (block[0] is Array or (block[0] is String and block[0] == "()")):
		return _execute_instruction(block, _context)

	# From here on, `routine` is treated as an expression block,
	# that is, an Array of instructions.

	var instruction_index = 0
	var instruction_count = block.size()
	var result

	while true:
		# Break if overflow the instruction buffer
		if instruction_index >= instruction_count:
			break
		
		var instruction = block[instruction_index]
		result = _execute_instruction(instruction, _context)

		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		
		_context.last_result = result
		instruction_index += 1
	
	# Return the result of the last evaluated expression.
	return result

## Executes a single instruction.
func _execute_instruction(instruction, _context: ExecutionContext):
	if (not instruction is Array) or (not instruction[0] is String):
		# If the instruction doesn't follow the correct form
		# ["<i_name>", ...params]
		return instruction
	else:
		var i_keyword = instruction[0]
		var i_params = instruction.slice(1, instruction.size())
		
		# Evaluate the parameters in case they're
		# function calls!
		var i_evaluated_params = []

		# Evaluating the parameters of the function cals.
		# This allows you to use the result of a function call
		# as the parameter to another function call.
		if not i_keyword in meta_functions:
			for param in i_params:
				var param_eval_result = execute(param)
				if param_eval_result is GDScriptFunctionState:
					param_eval_result = yield(param_eval_result, "completed")
					i_evaluated_params.push_back(param_eval_result)
		# Meta functions won't pre-evaluate their parameters,
		# so you'll need to call "execute" from inside them.
		else:
			i_evaluated_params = i_params

		if not has_method(i_keyword):
			push_error("No method found with the name '{name}'.".replace("{name}", i_keyword))
			return null

		var call_params = []
		if i_keyword in meta_functions:
			call_params.append(_context)
		call_params.append_array(i_evaluated_params)
		
		var result = callv(i_keyword, call_params)
		
		# If the called method was asynchronous, wait for its completion.
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		
		# Update context
		_context.last_keyword = i_keyword
		if not i_keyword in meta_functions:
			_context.last_condition_check_was_successful = false

		# Return the result	
		return result 


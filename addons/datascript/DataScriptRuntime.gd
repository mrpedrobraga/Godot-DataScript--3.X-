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

## Executes a routine.
func execute(routine, _context: ExecutionContext = null):
	if not routine is Array:
		return routine
	
	if not _context:
		_context = ExecutionContext.new()

	var instruction_index = 0
	var instruction_count = routine.size()
	var result
	yield(get_tree(), "idle_frame")

	while true:
		# Break if overflow the instruction buffer
		if instruction_index >= instruction_count:
			break
		
		var instruction = routine[instruction_index]

		if not instruction is Array:
			# Allow booleans and numbers to be instructions
			# which just return their value
			result = instruction
		else:
			var i_keyword = instruction[0]
			var i_params = instruction.slice(1, instruction.size())
			
			# Evaluate the parameters in case they're
			# function calls!
			var i_evaluated_params = []

			# Meta functions won't pre-evaluate their parameters,
			# so you'll need to call "execute" from inside them.
			if not i_keyword in meta_functions:
				for param in i_params:
					var param_eval_result
					if param is Array:
						if param[0] is Array:
							param_eval_result = execute(param.slice(1, param.size()), _context)
						elif param[0] is String:
							# Otherwise, it'll be a single instruction.
							param_eval_result = execute([param], _context)
						else:
							param_eval_result = param
						if param_eval_result is GDScriptFunctionState:
							param_eval_result = yield(param_eval_result, "completed")
					else:
						# If a parameter is a literal, leave it be.
						param_eval_result = param
					i_evaluated_params.push_back(param_eval_result)
			else:
				i_evaluated_params = i_params

			if not has_method(i_keyword):
				push_error("No method found with the name '{name}'.".replace("{name}", i_keyword))
			else:
				var call_params = []
				if i_keyword in meta_functions:
					call_params.append(_context)
				call_params.append_array(i_evaluated_params)
				result = callv(i_keyword, call_params)

				# If the called method was asynchronous, wait for its completion.
				if result is GDScriptFunctionState:
					result = yield(result, "completed")
			
			if not i_keyword in meta_functions:
				_context.last_condition_check_was_successful = false
		
			_context.last_keyword = i_keyword
		_context.last_result = result
		instruction_index += 1
	
	# Return the result of the last evaluated expression.
	return result
		


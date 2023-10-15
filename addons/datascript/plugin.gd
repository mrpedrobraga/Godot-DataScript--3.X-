tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("DataScriptRuntime", "Node", preload("DataScriptRuntime.gd"), null)

func _exit_tree():
	remove_custom_type("DataScriptRuntime")

@tool
extends EditorPlugin

var script_editor: CodeEdit
var cursor_line = -1

var audio_player

func _ready():
	EditorInterface.get_script_editor().editor_script_changed.connect(_on_editor_script_changed)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.stream = load("res://addons/insta_complete/insta_complete.wav")

func _on_editor_script_changed(_script):
	if is_instance_valid(script_editor):
		script_editor.caret_changed.disconnect(_on_caret_changed)
	script_editor = EditorInterface.get_script_editor().get_current_editor().get_base_editor()
	script_editor.caret_changed.connect(_on_caret_changed)


func _on_caret_changed():
	if not is_instance_valid(script_editor):
		return
	
	cursor_line = script_editor.get_caret_line()
	if not Input.is_key_pressed(KEY_BACKSPACE):
		for caret_index in script_editor.get_caret_count():
			try_complete(caret_index)


func try_complete(caret_index) -> void:
	var line_num = script_editor.get_caret_line(caret_index)
	var line := script_editor.get_line(line_num)
	
	if line.strip_edges().begins_with("var"):
		if line.ends_with(" :"):
			complete_end_replace(caret_index, " :", " := ")
		if line.ends_with(":") and not line.ends_with(" :"):
			complete_end_replace(caret_index, ":", ": ")
		elif line.ends_with(": f"):
			complete_end_replace(caret_index, ": f", ": float")
		elif line.ends_with(": i"):
			complete_end_replace(caret_index, ": i", ": int")
		elif line.count("=") == 1 and line.ends_with("="):
			if line.ends_with(" ="):
				complete_end_replace(caret_index, "=", "= ")
			else:
				complete_end_replace(caret_index, "=", " = ")
		elif line.ends_with("  "):
			complete_end_replace(caret_index, "  ", " ")
		return
	
	
	if line.begins_with("\t"):
		if line.ends_with("  "):
			complete_end_replace(caret_index, "  ", " ")
	else:
		match line:
			"f":
				for i in 2:
					if not is_line_empty(line_num + i + 1):
						script_editor.insert_line_at(line_num + 1, "")
				complete(caret_index, "func |():\n\t")
				for i in 2:
					if not is_line_empty(line_num - 1):
						script_editor.insert_line_at(line_num, "")
			"v":
				complete(caret_index, "var |")
			"ex":
				complete(caret_index, "extends |")
			"en":
				complete(caret_index, "enum | {}")
			"@o":
				complete(caret_index, "@onready var |")
			"@e":
				complete(caret_index, "@export|")
			"@export ":
				complete(caret_index, "@export var |")
		
		if line.ends_with(":():"):
			complete_end_replace(caret_index, ":():", ":")
			script_editor.set_caret_line(line_num + 1, caret_index == 0, true, 0, caret_index)
		elif line.ends_with(")-:"):
			complete_end_replace(caret_index, ")-:", ") -> |:")
		elif line.ends_with(") -:"):
			complete_end_replace(caret_index, ") -:", ") -> |:")


func complete(caret_index: int, line: String, replace := true):
	var caret_column = line.find("|")
	if replace:
		script_editor.set_line(script_editor.get_caret_line(caret_index), line.replace("|", ""))
		script_editor.set_caret_column(caret_column, true, caret_index)
	else:
		script_editor.set_line(script_editor.get_caret_line(caret_index), line.replace("|", ""))
		script_editor.set_caret_column(script_editor.get_caret_column() + 1, true, caret_index)
	play_complete()


func complete_end_add(caret_index: int, replace: String, with: String):
	var line_num = script_editor.get_caret_line(caret_index)
	var new_line: String = script_editor.get_line(line_num).replace(replace, with)
	script_editor.set_line(line_num, new_line)
	script_editor.set_caret_column(new_line.length(), true, caret_index)
	play_complete()


func complete_end_replace(caret_index: int, replace: String, with: String):
	var line_num = script_editor.get_caret_line(caret_index)
	var new_line: String = script_editor.get_line(line_num).trim_suffix(replace) + with.replace("|", "")
	script_editor.set_line(line_num, new_line)
	var caret_column = with.find("|")
	if caret_column != -1:
		script_editor.set_caret_column(new_line.length() - with.length() + caret_column + 1, true, caret_index)
	else:
		script_editor.set_caret_column(new_line.length(), true, caret_index)
	play_complete()


func get_indentation(string: String) -> String:
	var indentation := ""
	for i in string:
		if i == '\t' or i == ' ':
			indentation += i
		else:
			break
	return indentation


func is_line_empty(line_num):
	var line = script_editor.get_line(line_num).strip_edges()
	return line == "" or line.begins_with("#")

func play_complete():
	audio_player.play()

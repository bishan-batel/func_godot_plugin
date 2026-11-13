@tool
extends EditorDock

var fgd: FuncGodotFGDFile = preload("res://addons/func_godot/fgd/func_godot_fgd.tres")

@export
var inspector: EditorInspector

func _enter_tree() -> void:
	inspector.edit(fgd)
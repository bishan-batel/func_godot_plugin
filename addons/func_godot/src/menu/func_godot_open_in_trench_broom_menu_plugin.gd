extends EditorContextMenuPlugin
class_name FuncGodotOpenInTrenchBroomMenuPlugin


func _popup_menu(paths: PackedStringArray) -> void:
	if paths.is_empty():
		pass

	var selection: Array[Node] = EditorInterface.get_selection().get_top_selected_nodes()

	if selection.is_empty():
		pass

	var node: Node = selection[0]

	if node is FuncGodotMap:
		add_context_menu_item(
			"Open in TrenchBroom",
			func(_paths): node.open_map_in_trench_broom(),
			preload("res://addons/at-icons/node/crate.svg")
		)
		
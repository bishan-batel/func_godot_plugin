@tool
class_name FuncGodotFGDExportCaution extends ConfirmationDialog

@export var label: RichTextLabel

var error_color:
	get: return EditorInterface.get_editor_theme().get_color("error_color", "Editor")

var warn_color:
	get: return EditorInterface.get_editor_theme().get_color("warning_color", "Editor")

func _format_message(msg: FuncGodotFGDCompiler.Message) -> String:

	var name: String = FuncGodotFGDCompiler.MESSAGE_TYPE_TO_STRING[msg.type]

	var color := Color.WHITE

	match msg.type:
		FuncGodotFGDCompiler.MessageType.WARN:
			color = warn_color
		FuncGodotFGDCompiler.MessageType.FATAL:
			color = error_color
		FuncGodotFGDCompiler.MessageType.SEVERE:
			color = error_color
		FuncGodotFGDCompiler.MessageType.INFO:
			pass

	return "[color=#%s][b]%s[/b][/color]: %s" % [color.to_html(), name, msg.contents]

func setup(compiler: FuncGodotFGDCompiler, on_confirmed: Callable):
	assert(Engine.is_editor_hint())

	var info_label := $VBoxContainer/Label
	info_label.text = info_label.text.replace("[color=warn]", "[color=#" + warn_color.to_html() + "]")

	label.text = "[ul]" + "\n".join(
		compiler
			.get_errors_and_warnings()
			.map(_format_message)
			.filter(func(s: String): return s and not s.is_empty())
	) + "[/ul]"

	label.meta_clicked.connect(
		func(meta: String): EditorInterface.edit_script(ResourceLoader.load(meta, "Script"))
	)

	confirmed.connect(on_confirmed)

	confirmed.connect(queue_free)
	canceled.connect(queue_free)

	# var editor_window_size: Vector2i = EditorInterface.get_base_control().get_window().size
	# 
	# var target_width: int = int(editor_window_size.x * 0.60)
	# size = Vector2i(target_width, size.y)

	popup_centered_clamped()

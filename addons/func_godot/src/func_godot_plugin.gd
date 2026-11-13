@tool
@icon("res://addons/func_godot/icons/icon_godot_ranger.svg")
class_name FuncGodotPlugin extends EditorPlugin

## Name of the autoload for supporting running from trenchbroom / loading a map from the CLI
const RUN_FROM_TRENCHBROOM_NAME: String = "FuncGodotRunFromTrenchBroom"

const ICON: Texture2D = preload("res://addons/func_godot/icons/icon_godot_ranger.svg");

var map_import_plugin: QuakeMapImportPlugin = null
var palette_import_plugin: QuakePaletteImportPlugin = null
var wad_import_plugin: QuakeWadImportPlugin = null
var map_scene_format_importer: QuakeMapSceneFormatImporter = null

## menu plugin for ease of entity FGD creations
var context_menu_plugin: FuncGodotCreateFGDContextMenuPlugin = null

var open_in_trench_broom_menu_plugin: FuncGodotOpenInTrenchBroomMenuPlugin = null

var toolbar: Control = null

## Editor dock
var dock: EditorDock

#var func_godot_map_progress_bar: Control = null
var edited_object_ref: WeakRef = weakref(null)

func _get_plugin_name() -> String:
	return "FuncGodot"

func _handles(object: Object) -> bool:
	return object is FuncGodotMap

func _edit(object: Object) -> void:
	edited_object_ref = weakref(object)


func _get_plugin_icon() -> Texture2D:
	return ICON

func _enter_tree() -> void:
	add_custom_type("FuncGodotMap", "Node3D", preload("res://addons/func_godot/src/map/func_godot_map.gd"), null)
	add_custom_type("FuncGodotScene", "Node3D", preload("res://addons/func_godot/src/map/func_godot_scene.gd"), null)
	add_custom_type(
		"FuncGodotFGDEntityClass",
		"Resource",
		preload("res://addons/func_godot/src/fgd/func_godot_fgd_entity_class.gd"),
		null
	)

	add_custom_type(
		"FuncGodotFGDBaseClass",
		"Resource",
		preload("res://addons/func_godot/src/fgd/func_godot_fgd_base_class.gd"),
		null
	)

	scene_changed.connect(_scene_changed)

	# Import plugins
	map_import_plugin = QuakeMapImportPlugin.new()
	add_import_plugin(map_import_plugin)

	palette_import_plugin = QuakePaletteImportPlugin.new()
	add_import_plugin(palette_import_plugin)

	wad_import_plugin = QuakeWadImportPlugin.new()
	add_import_plugin(wad_import_plugin)

	map_scene_format_importer = QuakeMapSceneFormatImporter.new()
	add_scene_format_importer_plugin(map_scene_format_importer)

	dock = preload("res://addons/func_godot/ui/fdg_config_panel.tscn").instantiate()
	add_dock(dock)

	context_menu_plugin = FuncGodotCreateFGDContextMenuPlugin.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, context_menu_plugin)

	open_in_trench_broom_menu_plugin = FuncGodotOpenInTrenchBroomMenuPlugin.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, open_in_trench_broom_menu_plugin)

	add_tool_menu_item("Regenerate TrenchBroom Config", _regenerate_fgd)

	add_autoload_singleton(
		RUN_FROM_TRENCHBROOM_NAME,
		"res://addons/func_godot/src/trenchbroom/func_godot_run_from_trenchbroom.gd"
	)

	toolbar = _make_toolbar()

	add_control_to_container(CONTAINER_TOOLBAR, toolbar)

	# Default Map Settings
	#	if not ProjectSettings.has_setting("func_godot/default_map_settings"):
	#		ProjectSettings.set_setting("func_godot/default_map_settings", "res://addons/func_godot/func_godot_default_map_settings.tres")
	#		var property_info := {
	#			"name": "func_godot/default_map_settings",
	#			"type": TYPE_STRING,
	#			"hint": PROPERTY_HINT_FILE,
	#			"hint_string": "*.tres"
	#		}
	#		ProjectSettings.add_property_info(property_info)
	#		ProjectSettings.set_as_basic("func_godot/default_map_settings", true)
	#		ProjectSettings.set_initial_value("func_godot/default_map_settings", "res://addons/func_godot/func_godot_default_map_settings.tres")

	# Default Inverse Scale Factor
	if not ProjectSettings.has_setting("func_godot/default_inverse_scale_factor"):
		ProjectSettings.set_setting("func_godot/default_inverse_scale_factor", 32.0)
		var property_info := {
			"name": "func_godot/default_inverse_scale_factor",
			"type": TYPE_FLOAT
		}
		ProjectSettings.add_property_info(property_info)
		ProjectSettings.set_as_basic("func_godot/default_inverse_scale_factor", true)
		ProjectSettings.set_initial_value("func_godot/default_inverse_scale_factor", 32.0)

	# Model Point Class Default Path
	if not ProjectSettings.has_setting("func_godot/model_point_class_save_path"):
		ProjectSettings.set_setting("func_godot/model_point_class_save_path", "")
		var property_info := {
			"name": "func_godot/model_point_class_save_path",
			"type": TYPE_STRING
		}
		ProjectSettings.add_property_info(property_info)
		ProjectSettings.set_as_basic("func_godot/model_point_class_save_path", true)
		ProjectSettings.set_initial_value("func_godot/model_point_class_save_path", "")

	FuncGodotUserConfig._init_settings()

func _exit_tree() -> void:

	remove_control_from_container(CONTAINER_TOOLBAR, toolbar)
	toolbar.queue_free()
	toolbar = null

	remove_autoload_singleton(RUN_FROM_TRENCHBROOM_NAME)

	remove_scene_format_importer_plugin(map_scene_format_importer)

	remove_import_plugin(map_import_plugin)
	map_import_plugin = null

	remove_import_plugin(palette_import_plugin)
	palette_import_plugin = null

	if wad_import_plugin:
		remove_import_plugin(wad_import_plugin)
		wad_import_plugin = null

	remove_context_menu_plugin(context_menu_plugin)
	context_menu_plugin = null

	remove_context_menu_plugin(open_in_trench_broom_menu_plugin)
	open_in_trench_broom_menu_plugin = null

	remove_dock(dock)
	dock.queue_free()
	dock = null

	scene_changed.disconnect(_scene_changed)

	remove_custom_type("FuncGodotFGDBaseClass")
	remove_custom_type("FuncGodotFGDEntityClass")
	remove_custom_type("FuncGodotScene")
	remove_custom_type("FuncGodotMap")

	FuncGodotUserConfig._deinit_settings()

func _regenerate_fgd():
	var trench_config := preload("res://addons/func_godot/game_config/trenchbroom/func_godot_tb_game_config.tres")
	trench_config.export_file()

func _reimport_all_maps() -> void:
	var files_to_reimport: PackedStringArray = []
	var filesystem := EditorInterface.get_resource_filesystem()

	find_files_by_type(
		filesystem.get_filesystem_path("res://content/level"),
		["PackedScene"],
		["map", "vmf"],
		files_to_reimport
	)

	if files_to_reimport.is_empty():
		print("No map files found")
		return

	var base_control := EditorInterface.get_base_control()

	await get_tree().process_frame

	print("Reimporting all .map and .vmf files, this may take a while.")
	filesystem.reimport_files(files_to_reimport)


func _reimport_all_maps_dialogue():
	var dialogue := ConfirmationDialog.new()
	dialogue.title = "Reimport all func maps"
	dialogue.dialog_text = "Are you sure you want to reimport all func godot map files? This may take a while."
	dialogue.confirmed.connect(_reimport_all_maps)
	dialogue.confirmed.connect(dialogue.queue_free)
	dialogue.canceled.connect(dialogue.queue_free)
	EditorInterface.get_base_control().add_child(dialogue)
	dialogue.popup_centered()

## finds all files that were imported as the given type
static func find_files_by_type(
	dir: EditorFileSystemDirectory,
	filetypes: Array[String],
	extensions: Array[String],
	out_paths: PackedStringArray
) -> void:
	if not dir:
		return

	for i in range(dir.get_file_count()):
		var ext := dir.get_file_path(i).get_extension()

		if dir.get_file_type(i) in filetypes and ext in extensions:
			out_paths.append(dir.get_file_path(i))

	for i in range(dir.get_subdir_count()):
		find_files_by_type(dir.get_subdir(i), filetypes, extensions, out_paths)


func _make_toolbar() -> Control:
	var panel := HBoxContainer.new()

	# panel.themeOverride

	for button in _make_tool_buttons():
		panel.add_child(button)

	return panel


var _last_level_scene: String = ""

signal last_open_level_changed()

func _scene_changed(root: Node):
	if not root:
		return
	
	var level_script: Script = load("res://content/level/loader/Level.cs")
	var path: String = root.scene_file_path

	if path.is_empty():
		return

	if root.get_script() == level_script:
		print("Switched to ", path)
		_last_level_scene = path
		last_open_level_changed.emit()


func _play_last_level():
	# hail mary
	print("Attempting to run last level scene ", _last_level_scene)

	if _last_level_scene.is_empty():
		_scene_changed(EditorInterface.get_edited_scene_root())

	if _last_level_scene.is_empty():
		simple_popup(
			AcceptDialog.new(), "Failed to run last level",
			"Could not find the last level that was open in the editor, try reselecting the tab?"
		)
		return

	EditorInterface.play_custom_scene(_last_level_scene)

func _make_tool_buttons() -> Array[Node]:
	var export_fgd_files := Button.new()
	export_fgd_files.icon = preload("res://addons/at-icons/node2d/gobot.svg")
	export_fgd_files.flat = true
	export_fgd_files.tooltip_text = "Export FGD Files + TrenchBroom Config"
	export_fgd_files.pressed.connect(_regenerate_fgd)

	var play_last_level := Button.new()
	play_last_level.icon = preload("res://addons/at-icons/mesh/clapperboard.svg")
	play_last_level.flat = true
	play_last_level.tooltip_text = "Play the last level scene that was tabbed into"
	play_last_level.pressed.connect(_play_last_level)
	last_open_level_changed.connect(
		func():
			play_last_level.tooltip_text = "Play the last level scene opened (%s)" % (_last_level_scene.get_file().get_basename())
	)
	var play_last_level_ev := InputEventKey.new()
	play_last_level_ev.keycode = Key.KEY_R
	play_last_level_ev.alt_pressed = true
	play_last_level.shortcut = Shortcut.new()
	play_last_level.shortcut.events = [play_last_level_ev]

	var reimport_button := Button.new()
	reimport_button.icon = preload("res://addons/at-icons/node2d/arrows_counterclockwise.svg")
	reimport_button.flat = true
	reimport_button.tooltip_text = "Reimport all FuncGodot maps in the project"
	reimport_button.pressed.connect(_reimport_all_maps_dialogue)

	var reimport_in_scene := Button.new()
	reimport_in_scene.icon = preload("res://addons/at-icons/node2d/mountains.svg")

	reimport_in_scene.flat = true
	reimport_in_scene.tooltip_text = "Reimport all FuncGodot maps only in the edited scene"
	reimport_in_scene.pressed.connect(_reimport_all_maps_in_scene)

	var reimport_in_scene_ev := InputEventKey.new()
	reimport_in_scene_ev.keycode = Key.KEY_I
	reimport_in_scene_ev.command_or_control_autoremap = true
	reimport_in_scene.shortcut = Shortcut.new()
	reimport_in_scene.shortcut.events = [reimport_in_scene_ev]

	return [play_last_level, reimport_in_scene, reimport_button, export_fgd_files]

static func simple_popup(
	dialogue: AcceptDialog,
	title: String,
	text: String,
	configure: Callable=func(dialogue: AcceptDialog): pass
) -> void:
	dialogue.title = title
	dialogue.dialog_text = text
	dialogue.confirmed.connect(dialogue.queue_free)
	dialogue.canceled.connect(dialogue.queue_free)
	configure.call(dialogue)

	EditorInterface.get_base_control().add_child(dialogue)
	dialogue.popup_centered()


func _reimport_all_maps_in_scene() -> void:
	for node in get_tree().edited_scene_root.find_children("*", "Node3D"):
		if node is FuncGodotScene:
			node._reimport_map()
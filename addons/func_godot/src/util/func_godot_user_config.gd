## Replacement for the FuncGodotLocalConfig which assumes where the trench broom directories are,
## maybe later we will have a need to make this actual settings but honestly I don't see a use case for *anyone*
## to have a separate use case
class_name FuncGodotUserConfig

## Gets the system path to a folder that TrenchBroom loads game configs from
static func get_trench_broom_game_config_folder() -> String:
	var home_path := ""
	if OS.has_feature("windows"):
		home_path = OS.get_environment("USERPROFILE")
	else:
		home_path = OS.get_environment("HOME")

	if OS.has_feature("windows"):
		return home_path.path_join("AppData/Roaming/TrenchBroom/games")
	elif OS.has_feature("linux"):
		return home_path.path_join(".TrenchBroom/games/")
	else:
		return home_path.path_join("Library/Application Support/TrenchBroom/games")

## Gets the system dir for what TrenchBroom has the game directory set to
static func get_editor_game_dir() -> String:
	# NOTE: specific to our project
	return ProjectSettings.globalize_path("res://content/level")

const TRENCHBROOM_PATH_EDITOR_SETTING: Dictionary = {
	name = "func_godot/trenchbroom_executable",
	type = TYPE_STRING,
	hint = PROPERTY_HINT_GLOBAL_FILE,
	hint_string = ""
}

static func get_trench_broom_executable_path() -> String:
	var settings := EditorInterface.get_editor_settings()

	if settings.has_setting(TRENCHBROOM_PATH_EDITOR_SETTING["name"]):
		return settings.get(TRENCHBROOM_PATH_EDITOR_SETTING["name"])

	return ""

## Attempts to open the given map file in trench broom, them map file should be in res://
static func open_trench_broom(map_path: String):
	var exe_path: String = get_trench_broom_executable_path()

	if exe_path.is_empty():
		FuncGodotPlugin.simple_popup(
			AcceptDialog.new(),
			"Failed to open TrenchBroom",
			"Unable to open trench broom, make sure to configure your editor path in Editor Settings."
		)
		return

	map_path = ProjectSettings.globalize_path(map_path)

	var cmd := exe_path
	var cmd_args: Array[String] = []

	# if exe_path.get_extension() == "app":
	# 	# apple .app files are launched with the open command followed by the .app path, and a "--args" delimiter
	# 	# before the program arguments
	# 	cmd = "open"
	# 	cmd_args.append_array([exe_path, "--args"])

	cmd_args.append(map_path)

	print("Opening Map in TrenchBroom: ", cmd, " ", " ".join(cmd_args))

	var pid := OS.create_process(cmd, cmd_args)

	if pid == -1:
		push_error("Failed to open TrenchBroom")
		FuncGodotPlugin.simple_popup(
			AcceptDialog.new(),
			"Failed to open TrenchBroom",
			"Unable to open trench broom, make sure to the editor path is configured correctly: %s" % [exe_path]
		)

static func _init_settings() -> void:
	var settings := EditorInterface.get_editor_settings()

	if not settings.has_setting(TRENCHBROOM_PATH_EDITOR_SETTING["name"]):
		settings.set(TRENCHBROOM_PATH_EDITOR_SETTING["name"], "")

	settings.add_property_info(TRENCHBROOM_PATH_EDITOR_SETTING)
# settings.

static func _deinit_settings() -> void:
	pass

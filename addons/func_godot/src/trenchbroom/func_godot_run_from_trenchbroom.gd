extends Node

## This script is used for an autoload that runs when the game is being played, it parses
## the godot user command line inputs for a map file name and searches for the correct scene to load.
## This means you can run our project with [code]godot --path path/to/project -- --func_godot_map brutalist_test[/code],
## and it will launch the project directly into `res://content/level/brutalist_test.tscn`
## 
## This script assumes the map name had no spaces and that each `path/to/file.map` has a corresponding `path/to/file.tscn`.

const FuncGodotUserConfig := preload("res://addons/func_godot/src/util/func_godot_user_config.gd")

func _ready() -> void:
	# do not run in standalone builds
	if OS.has_feature("standalone"):
		return

	var args := OS.get_cmdline_user_args()

	var i := args.find("--func_godot_map")

	if i == -1:
		return

	if i + 1 == len(args):
		push_error("Invalid command line arg, --func_godot_map ${MAP_BASE_NAME}")
		return

	_try_load_map(args[i + 1])

# var map := ProjectSettings.localize_path(map_path)


## searches for a map of a given name for loading
func _try_load_map(map_name: String):
	print("Running ", map_name)
	
	var directories: Array[String] = [
		ProjectSettings.localize_path(FuncGodotUserConfig.get_editor_game_dir())
	]

	while not directories.is_empty():
		var dir: String = directories.pop_front()

		for file in DirAccess.get_files_at(dir):
			file = dir.path_join(file)
			var extension: String = file.get_extension()

			if extension not in ["map", "vmf"]:
				continue

			var name: String = file.get_file().trim_suffix("." + extension)

			if map_name != name:
				continue

			var scene_file := file.get_base_dir().path_join(name + ".tscn")

			if not ResourceLoader.exists(scene_file, &"PackedScene"):
				continue

			get_tree().change_scene_to_file(scene_file)

		directories.append_array(
			Array(DirAccess.get_directories_at(dir)).map(func(f): dir.path_join(f))
		)

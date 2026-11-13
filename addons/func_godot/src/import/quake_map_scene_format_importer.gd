@tool
extends EditorSceneFormatImporter
class_name QuakeMapSceneFormatImporter

func _get_extensions() -> PackedStringArray:
	return PackedStringArray(['map', 'vmf'])

func _get_save_extension() -> String:
	return 'scn'


func _find_map_settings(default_path: String="") -> FuncGodotMapSettings:
	var paths: Array[String] = [
		ProjectSettings.get_setting("func_godot/default_map_settings", FuncGodotMapSettings.DEFAULT_PATH),
		FuncGodotMapSettings.DEFAULT_PATH
	]

	while not paths.is_empty():
		var path: String = paths.pop_front()

		if not ResourceLoader.exists(path, "FucnGodotMapSettings"):
			continue

		return ResourceLoader.load(path, "FuncGodotMapSettings")

	return null


func _get_import_options(path: String):

	add_import_option_advanced(
			TYPE_OBJECT,
			"func_godot/map_settings",
			_find_map_settings(""),
			PROPERTY_HINT_RESOURCE_TYPE,
			"FuncGodotMapSettings"
	)
	add_import_option("func_godot/unwrap_uv2", true)
	add_import_option("func_godot/show_profile_info", false)
	add_import_option("func_godot/disable_smoothing", false)

func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	var name := path.get_file().get_basename().to_pascal_case()

	if name.is_empty():
		name = "FuncGodotScene";

	var fgd := FuncGodotScene.new()
	fgd.name = name
	fgd.map_settings = options.get_or_add("func_godot/map_settings", "")
	fgd.global_map_file = ProjectSettings.globalize_path(path);
	fgd.build_flags = 0;

	if options.get_or_add("func_godot/unwrap_uv2", true):
		fgd.build_flags |= FuncGodotMap.BuildFlags.UNWRAP_UV2;

	if options.get_or_add("func_godot/show_profile_info", false):
		fgd.build_flags |= FuncGodotMap.BuildFlags.SHOW_PROFILE_INFO;

	if options.get_or_add("func_godot/disable_smoothing", false):
		fgd.build_flags |= FuncGodotMap.BuildFlags.DISABLE_SMOOTHING;

	var failed := false

	var basename: String = path.get_basename()

	if basename.ends_with("-crash"):
		push_warning(
				"Explicitly skipping import of %s, crash files are always ignored, they should not be commited to VCS either."
						% path
		)
	elif basename.get_extension().is_valid_int():
		push_warning(
				"Explicitly skipping import of %s, auto save files are always ignored, they should not be commited to VCS either."
						% path
		)
	else:
		print("[FuncGodotScene] Reimporting ", path.get_file())

		var failed_flag := func(): failed = true
		fgd.build_failed.connect(failed_flag)
		fgd.build()
		fgd.build_failed.disconnect(failed_flag)

	if failed:
		push_error("Failed to import / build quake scene %s" % [path])

	return fgd

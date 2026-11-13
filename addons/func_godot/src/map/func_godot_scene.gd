## FuncGodotMap inherited script that hides properties from FuncGodotMap.
## Intended only to be used by the QuakeMapScene importer to attach to the 
## root node of the imported map/scene 
@icon("res://addons/at-icons/node3d/mountains.svg")
@tool
extends FuncGodotMap
class_name FuncGodotScene


@export_tool_button("Manually reimport Map", "BuildCSharp")
var _reimport_map_button:
	get:
		return _reimport_map

func _reimport_map():
	if not Engine.is_editor_hint():
		return

	if scene_file_path.is_empty():
		return

	assert(not _is_scene_root(), "Cannot manually reimport a map when its being opened directly")

	var filesystem := EditorInterface.get_resource_filesystem()

	# wait one frame, call_deferred breaks because of issues w/ printing during before flushing 
	await EditorInterface.get_base_control().get_tree().process_frame

	if filesystem.is_importing():
		await filesystem.resources_reimported

	filesystem.reimport_files([scene_file_path])

const HIDDEN_PROPERTIES := [
	"_build_func",
	"_clear_func",
	"local_map_file",
	"global_map_file",
	"map_settings",
	"build_flags",
	"hyperplane_size"
]

## Whether or not this is being edited
func _is_scene_root() -> bool:
	if not is_inside_tree():
		return false

	var root: Node = get_tree().edited_scene_root

	return scene_file_path == root.scene_file_path if root else false

# hide the normal func godot map settings & disable storing callables
func _validate_property(property: Dictionary) -> void:
	var name = property["name"]

	if name == "_reimport_map_button" and _is_scene_root():
		property["usage"] |= PROPERTY_USAGE_READ_ONLY
		pass

	if name in HIDDEN_PROPERTIES:
		property["usage"] |= PROPERTY_USAGE_READ_ONLY
		property["usage"] |= PROPERTY_USAGE_NO_EDITOR
		property["usage"] &= ~ PROPERTY_USAGE_EDITOR

	if property["type"] == TYPE_CALLABLE:
		property["usage"] &= ~ PROPERTY_USAGE_STORAGE

	return;

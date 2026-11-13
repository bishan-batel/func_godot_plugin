## Menu context action for right clicking a scene file or a C# script and generating
## a base FGDEntityClass definiton file (either a solid entity or a point class).
@tool
class_name FuncGodotCreateFGDContextMenuPlugin
extends EditorContextMenuPlugin

const POINT_ENTITY_ICON := preload("res://addons/func_godot/icons/icon_godambler3d.svg");
const SOLID_ENTITY_ICON := preload("res://addons/func_godot/icons/icon_slipgate3d.svg");
const MODEL_POINT_ENTITY_ICON := preload("res://addons/func_godot/icons/icon_godambler3d.svg");

## Extension for saved FGD entity files
const FGD_EXTENSION := "tres"

# Specific extensions to not allow this context action to show up on
const DISALLOWED_EXTENSIONS := ["res", "tres"]

## Prefix for generated FGD files
const FGD_PREFIX: String = "fgd_"

var fgd: FuncGodotFGDFile = preload("res://addons/func_godot/fgd/func_godot_fgd.tres")

## parses a filepath to get its name without extension
static func _filename_without_extension(path: String) -> String:
	return path.get_file().trim_suffix(path.get_extension()).trim_suffix('.')

## converts a source filepath into a path to generate its fgd definition file to
static func _source_to_fgd_path(filepath: String, iter: int=0) -> String:
	var dir := filepath.get_base_dir()
	var name := _filename_without_extension(filepath).to_snake_case()

	if iter > 0:
		name = "%s_%s" % [name, iter];
	var fgd_path := "%s%s.%s" % [FGD_PREFIX, name, FGD_EXTENSION];

	return dir.path_join(fgd_path)

## converts a source fielpath into a path to generate its fgd defintion file to,
## takes care of making sure this is unique so you can be sure you aren't overwriting 
## existing data
static func _find_unique_fgd_path(path: String) -> String:
	var generated_path := _source_to_fgd_path(path)

	var tries := 1
	while ResourceLoader.exists(generated_path):
		generated_path = _source_to_fgd_path(path, tries)
		tries += 1
	return generated_path

## shows the popup menu when the given paths were selected
func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() != 1:
		return

	var path := paths[0]

	var scene_extensions := ResourceLoader.get_recognized_extensions_for_type("PackedScene")
	var script_extensions := ResourceLoader.get_recognized_extensions_for_type("CSharpScript")

	var ext := path.get_extension()

	# specifically disallow these two
	if ext in DISALLOWED_EXTENSIONS:
		return

	if ext in scene_extensions or ext in script_extensions:
		add_context_menu_item(
			"Create FGD Point Entity",
			func(paths: PackedStringArray): _fgd_entity(paths, _create_point_class),
			POINT_ENTITY_ICON
		)
		add_context_menu_item(
			"Create FGD Model Point Entity (auto generate a preview model in TrenchBroom)",
			func(paths: PackedStringArray): _fgd_entity(paths, _create_model_point_class),
			MODEL_POINT_ENTITY_ICON
		)

	if ext in script_extensions:
		add_context_menu_item(
			"Create FGD Solid (Brush) Entity",
			func(paths: PackedStringArray): _fgd_entity(paths, _create_solid_class),
			SOLID_ENTITY_ICON
		)

## Creates a FGD definition file for the given path(s), the specific type of
## FGD is determined by "create_entity" which is a callable that takes in
## a loaded 'Resource' (C# script or PackedScene) and the path
func _fgd_entity(paths: PackedStringArray, create_entity: Callable):
	if paths.size() != 1:
		return

	var path := paths[0]

	var resource := load(path)

	if resource == null:
		push_error("Failed to create FGD definition file, could not load resource from ", path)
		return

	var entity := create_entity.call(resource) as FuncGodotFGDEntityClass;

	if entity == null or entity is not FuncGodotFGDEntityClass:
		return;

	var fgd_path := _find_unique_fgd_path(path)
	entity.resource_path = fgd_path
	entity.classname = _filename_without_extension(fgd_path).trim_prefix(FGD_PREFIX)
	entity.resource_name = entity.classname

	if ResourceSaver.save(entity) != Error.OK:
		push_error("Failed to save FGD entity ", entity)
		return


	# add it to the list of all entities
	fgd.entity_definitions.push_back(entity)
	fgd.emit_changed()
	ResourceSaver.save(fgd)

	EditorInterface.edit_resource(entity)

## Converts a C# script or PackedScene into into a PointClass definition file
static func _create_point_class(resource: Resource) -> FuncGodotFGDEntityClass:
	var point_entity := FuncGodotFGDPointClass.new()

	if resource is CSharpScript:
		if not FuncGodotFGDEntityClass.is_valid_csharp_script(resource):
			push_error(resource.resource_path, " is not a C# script inheriting from Node")
			return null
		point_entity.script_class = resource
		point_entity.node_class = resource.get_instance_base_type()
	elif resource is PackedScene:
		point_entity.scene_file = resource
	else:
		push_error(
			resource.resource_path,
			" is not a C# script or scene file, failed to create a FuncGodotFGDPointClass"
		)
		return null

	return point_entity

## Converts a C# script or PackedScene into into a PointClass defintion file
static func _create_model_point_class(resource: Resource) -> FuncGodotFGDEntityClass:
	var point_entity := FuncGodotFGDModelPointClass.new()

	if resource is CSharpScript:
		if not FuncGodotFGDEntityClass.is_valid_csharp_script(resource):
			push_error(resource.resource_path, " is not a C# script inheriting from Node")
			return null
		point_entity.script_class = resource
		point_entity.node_class = resource.get_instance_base_type()
	elif resource is PackedScene:
		point_entity.scene_file = resource
	else:
		push_error(
			resource.resource_path,
			" is not a C# script or scene file, failed to create a FuncGodotFGDPointClass"
		)
		return null

	return point_entity

## Converts a C# script into into a SolidClass defintion file
static func _create_solid_class(resource: Resource) -> FuncGodotFGDEntityClass:
	var point_entity := FuncGodotFGDSolidClass.new()

	if resource is CSharpScript:
		if not FuncGodotFGDEntityClass.is_valid_csharp_script(resource):
			push_error(resource.resource_path, " is not a C# script inheriting from Node")
			return null
		point_entity.script_class = resource
		point_entity.node_class = resource.get_instance_base_type()
	else:
		push_error(resource.resource_path, " is not a C# script, failed to create a FuncGodotFGDSolidClass")
		return null

	return point_entity
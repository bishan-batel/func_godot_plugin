@tool
@icon("res://addons/func_godot/icons/icon_godot_ranger.svg")
class_name FuncGodotFGDFile extends Resource

## [Resource] file used to express a set of [FuncGodotFGDEntity] definitions. 
## 
## Can be exported as an FGD file for use with a Quake or Hammer-based map editor. Used in conjunction with [FuncGodotMapSetting] to generate nodes in a [FuncGodotMap] node.
##
## @tutorial(Level Design Book FGD Chapter): https://book.leveldesignbook.com/appendix/resources/formats/fgd
## @tutorial(Valve Developer Wiki FGD Article): https://developer.valvesoftware.com/wiki/FGD

## Supported map editors enum, used in conjunction with [member target_map_editor].
enum FuncGodotTargetMapEditors {
	OTHER,
	TRENCHBROOM,
	JACK,
	NET_RADIANT_CUSTOM,
}

## Builds and exports the FGD file.
@export_tool_button("Export FGD") var export_file := _export_button

func _export_button() -> void:
	load("uid://b44ah5b2000wa").export_file()

## Toggles whether [FuncGodotFGDModelPointClass] resources will generate models from their [PackedScene] files.
@export var generate_model_point_class_models: bool = true

## When exporting this FGD should verbose messages be printed to console
@export var verbose_export: bool = false

# @export_group("Map Editor")
## Some map editors do not support the features found in others 
## (ex: TrenchBroom supports the "model" key word while others require "studio", 
## J.A.C.K. uses the "shader" key word while others use "material", etc...). 
## If you get errors in your map editor, try changing this setting and re-exporting. 
## This setting is overridden when the FGD is built via the Game Config resource.
## [Gross Incandescence] - We are only supporting TrenchBroom, removed the @export declarator
const target_map_editor: FuncGodotTargetMapEditors = FuncGodotTargetMapEditors.TRENCHBROOM

@export_group("FGD")
## FGD output filename without the extension.
@export var fgd_name: String = "FuncGodot"

## Array of [FuncGodotFGDFile] resources to include in FGD file output. All of the entities included with these FuncGodotFGDFile resources will be prepended to the outputted FGD file.
@export var base_fgd_files: Array[FuncGodotFGDFile] = []

## Array of resources that inherit from [FuncGodotFGDEntityClass]. This array defines the entities that will be added to the exported FGD file and the nodes that will be generated in a [FuncGodotMap].
# @export var entity_definitions: Array[FuncGodotFGDEntityClass] = []
@export var entity_definitions: Array[Resource] = []


## builds the class texts
## returns a FGDCompiler containing the built class text, along with
## any errors accrued
func compile_entity_classes(options: FuncGodotFGDCompiler.Options) -> FuncGodotFGDCompiler:
	var compiler := FuncGodotFGDCompiler.new_from_resource(self, options)
	compiler.info("Compiling entity classes")

	for i in range(len(base_fgd_files)):
		var base_fgd := base_fgd_files[i] as FuncGodotFGDFile

		if base_fgd == null:
			compiler.warn("Base FGD ", i, " is null or invalid type.")
			continue

		# compile the base FGD and compose it into ourself
		compiler.compose(base_fgd.compile_entity_classes(options))

		# short circuit if any fatal errors occured
		if compiler.has_fatal_errors():
			return compiler

	# get a collection of all entity definitions with each fully instantiated /
	# they all have their inherited properties baked
	var all_definitions: Dictionary[String, FuncGodotFGDEntityClass] = {}

	compiler.compose(
		recursively_find_all_entity_definitions(options, all_definitions)
	)

	if compiler.has_fatal_errors():
		return compiler

	compiler.info("Finding all entity definitions")

	for classname in all_definitions.keys():
		compiler.compose(all_definitions[classname].compile(options))

		if compiler.has_fatal_errors():
			return compiler

	return compiler

## attempts to expand / insert the entity into the definitions dictionary
func _insert_entity_to_definitions(
	compiler: FuncGodotFGDCompiler,
	entity: FuncGodotFGDEntityClass,
	definitions: Dictionary[String, FuncGodotFGDEntityClass]
):
	if not entity.has_valid_classname():
		compiler.severe("Skipping " + entity.resource_path + ", invalid class name")

	var classname := entity.classname

	if definitions.has(classname):
		# duplicate classnames are more likely to be fatal / produce malformed results
		compiler.severe(
			"Duplicate entity definition '%s' (same classname) found, overwrote with newer definition."
				% [classname]
		)

	definitions[classname] = entity.bake_inherited_properties()


## gets all definitions for exporting, key is the classname of the entity
## the compiler is not written to must may accrue warnings & errors
## all_definitions is an out parameter and
func recursively_find_all_entity_definitions(
	options: FuncGodotFGDCompiler.Options,
	all_definitions: Dictionary[String, FuncGodotFGDEntityClass],
) -> FuncGodotFGDCompiler:
	var compiler := FuncGodotFGDCompiler.new_from_resource(self, options)
	compiler.info("Finding all entity definitions")

	for i in range(len(base_fgd_files)):
		var base_fgd: FuncGodotFGDFile = base_fgd_files[i]

		if base_fgd == null:
			compiler.warn("Base FGD at index ", i, " is null or an incorrect type.")
			continue

		compiler.compose(
			base_fgd.recursively_find_all_entity_definitions(options, all_definitions)
		)

		# early return if the base FGD had fatal errors 
		if compiler.has_fatal_errors():
			return compiler

	for i in range(len(entity_definitions)):
		var entity := entity_definitions[i] as FuncGodotFGDEntityClass

		if entity == null:
			compiler.warn("Entity definition at index ", i, " is null or an incorrect type.")
			continue

		_insert_entity_to_definitions(compiler, entity, all_definitions)

		if compiler.has_fatal_errors():
			return compiler

	return compiler

## Exports the FGD file
func do_export_file(
	target_editor: FuncGodotTargetMapEditors,
	fgd_output_folder: String
) -> void:
	assert(Engine.is_editor_hint(), "Can only export the file in-editor")
	assert(target_editor == FuncGodotTargetMapEditors.TRENCHBROOM, "FuncGodot[Gross] only supports trench broom")

	var compiler := compile_entity_classes(create_compiler_options())

	if compiler.has_fatal_errors():
		printerr("Aborting FGD export, fatal error(s)")
		var dialogue := AcceptDialog.new()
		dialogue.title = "FGD File Export"
		dialogue.dialog_text = "Encountered fatal errors trying to export the FGD file."
		dialogue.dialog_text += "\n- ".join(compiler.get_errors_and_warnings().map(func(msg): return msg.contents))
		dialogue.confirmed.connect(func(): dialogue.queue_free())
		EditorInterface.get_base_control().add_child(dialogue)
		dialogue.popup_centered()
		return

	if compiler.has_warnings() or compiler.has_severe_errors():
		var dialogue: FuncGodotFGDExportCaution = preload("uid://cqdsyu3fec1vv").instantiate()
		dialogue.visible = false
		EditorInterface.get_base_control().add_child(dialogue)
		dialogue.setup(compiler, func(): _export_compiled(fgd_output_folder, compiler))
		return

	_export_compiled(fgd_output_folder, compiler)

func _export_compiled(fgd_output_folder: String, compiler: FuncGodotFGDCompiler):
	if not DirAccess.dir_exists_absolute(fgd_output_folder):
		var err: Error = DirAccess.make_dir_recursive_absolute(fgd_output_folder)
		if err != OK:
			printerr("Failed Export: Failed to create directory", error_string(err))
			return

	var fgd_file: String = fgd_output_folder.path_join(fgd_name + ".fgd")

	var file_obj: FileAccess = FileAccess.open(fgd_file, FileAccess.WRITE)

	if not file_obj:
		printerr(
			"Failed to open file for writing: ",
			fgd_file,
			" Reason: ",
			error_string(FileAccess.get_open_error())
		)
		return

	print_rich("Finished compiling FGD, Exporting FGD to ", fgd_file)
	compiler.save_to_file(file_obj)

	file_obj.close()

func create_compiler_options() -> FuncGodotFGDCompiler.Options:
	var options := FuncGodotFGDCompiler.Options.new()
	options.generate_models = true
	options.verbose = verbose_export
	return options

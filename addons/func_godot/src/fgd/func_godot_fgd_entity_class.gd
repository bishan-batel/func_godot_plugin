@icon("res://addons/func_godot/icons/icon_godot_ranger.svg")
@tool
@abstract
class_name FuncGodotFGDEntityClass extends Resource

## Entity definition template. WARNING! Not to be used directly! Use [FuncGodotFGDBaseClass], [FuncGodotFGDSolidClass], or [FuncGodotFGDPointClass] instead.
##
## Entity definition template. It holds all of the common entity class properties shared between [FuncGodotFGDBaseClass], [FuncGodotFGDSolidClass], or [FuncGodotFGDPointClass]. 
## Not to be used directly, use one of the aforementioned FGD class types instead.
##
## @tutorial(Quake Wiki Entity Article): https://quakewiki.org/wiki/Entity
## @tutorial(Level Design Book: Entity Types and Settings): https://book.leveldesignbook.com/appendix/resources/formats/fgd#entity-types-and-settings-basic
## @tutorial(Valve Developer Wiki FGD Article): https://developer.valvesoftware.com/wiki/FGD#Class_Types_and_Properties
## @tutorial(Valve Developer Wiki Entity Descriptions): https://developer.valvesoftware.com/wiki/FGD#Entity_Description

var prefix: String = ""

@export_group("Entity Definition")
## Entity classname. [b][i]This is a required field in all entity types[/i][/b] as it is parsed by both the map editor and by FuncGodot on map build.
@export var classname: String:
	set(value):
		classname = sanitize_classname(value)
	get:
		return classname

## Entity description that appears in the map editor. Not required.
@export_multiline var description: String = ""

## Entity does not get written to the exported FGD. Entity is only used for [FuncGodotMap] build process.
@export var func_godot_internal: bool = false

## Omits the 'angles' property to the FGD. The angles property will only function as intended
## when using [FuncGodotModelPointClass.generate_size_property] or working with a FuncGodotPointClass.
@export var omit_angles_property := false

## [FuncGodotFGDBaseClass] resources to inherit [member class_properties] and [member class_descriptions] from.
## TODO: When using C# based bridge generations, I cannot guarantee inheriting FGD properites will work, 
## so for the time being I would discourage the use of heavy inheritance when making gameplay nodes
## @experimental 
@export var base_classes: Array[FuncGodotFGDBaseClass] = []

## Key value pair properties that will appear in the map editor. After building the [FuncGodotMap] in Godot, these properties will be added to a [Dictionary] 
## that gets applied to the generated node, as long as that node is a tool script with an exported `func_godot_properties` Dictionary.
@export var class_properties: Dictionary[String, Variant] = {}

## Map editor descriptions for previously defined key value pair properties. Optional but recommended.
@export var class_property_descriptions: Dictionary[String, Variant] = {}

## Automatically applies entity class properties to matching properties in the generated node. 
## When using this feature, class properties need to be the correct type or you may run into errors on map build.
@export var auto_apply_to_matching_node_properties: bool = false

## Appearance properties for the map editor. See the Valve Developer Wiki and TrenchBroom documentation for more information.
@export var meta_properties: Dictionary[String, Variant] = {
	"size": AABB(Vector3(-8, -8, -8), Vector3(8, 8, 8)),
	"color": Color(0.8, 0.8, 0.8)
}

@export_group("Node Generation")
## Node to generate on map build. This can be a built-in Godot class, a Script class, or a GDExtension class. 
## For Point Class entities that use Scene File instantiation leave this blank.
@export var node_class := ""

## Optional class property to use in naming the generated node. Overrides [member FuncGodotMapSettings.name_property].
## Naming occurs before adding to the [SceneTree] and applying properties.
## Nodes will be named `"entity_" + name_property`. An entity's name should be unique, otherwise you may run into unexpected behavior.
## @deprecated: [GrossIncandescence] We are not doing anything that requires custom name properties like this, so
## this is disabled from the editor - it is still stored in the resource storage for backwards compatibility
@export_storage var name_property := ""

## Optional array of node groups to add the generated node to.
@export var node_groups: Array[StringName] = []

## C# Bridge Script
func _get_csharp_wrapper() -> Object:
	return load("uid://v1n1gxh0og3m").new()

## TargetId C# script, if this is crashing then you likely haven't built the C# project
## before entering the editor.
const TargetId: CSharpScript = preload("res://addons/func_godot/csharp/TargetId.cs")

## List of all characters allowed in an entity classname (case insensitive)
static var ALLOWED_CLASS_NAME_CHARS: RegEx = RegEx.create_from_string("[A-Za-z0-9_]")

## Sanitizes a quake map entity classname
static func sanitize_classname(name: String) -> String:
	# sanitize all whitespace
	name = name.replace_chars(" \n\t", "_".unicode_at(0))

	var new_name: String = ""

	for char in name:
		if ALLOWED_CLASS_NAME_CHARS.search(char):
			new_name += char

	return new_name

## Does this entity have a properly configured class name
func has_valid_classname() -> bool:
	return not sanitize_classname(classname).is_empty()


## Compiles the beginning list of bases and metaproperties, does not include the '=classname'
func _compile_bases_and_meta(options: FuncGodotFGDCompiler.Options) -> FuncGodotFGDCompiler:
	var compiler := FuncGodotFGDCompiler.new_from_resource(self, options)

	# Meta properties
	var meta_props := meta_properties.duplicate()

	var base_classnames: PackedStringArray = (base_classes
		.filter(func(base: FuncGodotFGDBaseClass): return base != null)
		.map(func(base: FuncGodotFGDBaseClass): return base.classname))

	if not base_classnames.is_empty():
		meta_props['base'] = base_classnames

	compiler.write_word(prefix)

	for prop in meta_props:
		if prefix == '@SolidClass':
			if prop == "size" or prop == "model":
				continue

		# TODO: validation that metaproperty names are valid
		var value = meta_props[prop]
		compiler.write_word(prop)
		compiler.write_paren_open()

		if value is AABB:
			compiler.write_vector3(value.position)
			compiler.write_comma()
			compiler.write_vector3(value.size)
		elif value is Color:
			compiler.write_color(value)
		elif value is String:
			# TODO: validation that metaproperty is a valid string
			compiler.write_string(value)
		elif value is Dictionary:
			compiler.write_json(value)
		elif value is PackedStringArray:
			if not value.is_empty():
				compiler.write_word(value[0])

				for i in range(1, len(value)):
					compiler.write_comma()
					compiler.write_word(value[i])

		# compiler.write_string(JSON.stringify(value))
		else:
			# TODO: Validation on what meta properties are valid
			pass

		compiler.write_paren_close()

	return compiler

## Map from variant types to their property typenames in FGD. Note that 'object' is special
## And requires more work
const VARIANT_TO_FGD_TYPENAME: Dictionary = {
	TYPE_INT: "integer",
	TYPE_FLOAT: "float",
	TYPE_STRING: "string",
	TYPE_BOOL: "choices",
	TYPE_VECTOR2: "string",
	TYPE_VECTOR2I: "string",
	TYPE_VECTOR3I: "string",
	TYPE_VECTOR4: "string",
	TYPE_VECTOR4I: "string",
	TYPE_DICTIONARY: "choices",
	TYPE_COLOR: "color255",
	TYPE_ARRAY: "flags",
	TYPE_OBJECT: "object"
}

func fgd_typename_of(prop: String, value: Variant) -> String:
	# builtin type
	if prop == "targetname":
		return "target_source"

	var type := typeof(value)

	if not VARIANT_TO_FGD_TYPENAME.has(type):
		return ""

	if value is Object:
		return object_fgd_typename(value)

	return VARIANT_TO_FGD_TYPENAME[type]


func object_fgd_typename(value: Object) -> String:
	# target_source
	if value is Material:
		return "material"
	elif value is Texture2D:
		return "decal"
	elif value is AudioStream:
		return "sound"
	elif _is_obj_target_id(value):
		return "target_destination"

	return "target_source"

func _is_obj_target_id(obj: Object) -> bool:
	var script: CSharpScript = obj.get_script()

	if not script or script is not CSharpScript:
		return true

	TargetId.instance_has(obj) ;
	return script.get_global_name() == "TargetId"


## Helper for [compile] for compiling a property's value
func _compile_property_value(
	compiler: FuncGodotFGDCompiler,
	name: String,
	value: Variant
):
	if value is bool:
		compiler.write_colon()
		compiler.write_integer(1 if value else 0)
		compiler.write_equals()
	elif value is not Dictionary and value is not Array:
		compiler.write_colon()

	match typeof(value):
		TYPE_INT: compiler.write_integer(value)
		TYPE_FLOAT: compiler.write_float(value)
		TYPE_STRING, TYPE_STRING_NAME: compiler.write_string(value)
		TYPE_OBJECT when _is_obj_target_id(value):
			compiler.write_string(value.get("Name"))
		TYPE_VECTOR2: compiler.write_vector2(value, true)
		TYPE_VECTOR2I: compiler.write_vector2i(value, true)
		TYPE_VECTOR3: compiler.write_vector3(value, true)
		TYPE_VECTOR3I: compiler.write_vector3i(value, true)
		TYPE_VECTOR4: compiler.write_vector4(value, true)
		TYPE_VECTOR4I: compiler.write_vector4i(value, true)
		TYPE_COLOR: compiler.write_color(value, true)

		# Booleans are encoded as a 'Yes/No' choice
		TYPE_BOOL:
			compiler.write_bracket_open()

			compiler.write_integer(0)
			compiler.write_colon()
			compiler.write_string("No")

			compiler.write_integer(1)
			compiler.write_colon()
			compiler.write_string("Yes")

			compiler.write_bracket_close()

		# Dictionaries denote a 'choice' / combobox type proprty
		TYPE_DICTIONARY:
			compiler.write_equals()
			compiler.write_bracket_open()

			for choice: String in value:
				var choice_val = value[choice]

				if choice_val is not int:
					compiler.warn("Choice value for ", choice, " is not an integer: ", choice_val)
					continue

				compiler.write_integer(choice_val)
				compiler.write_colon()
				compiler.write_string(choice)

			compiler.write_bracket_close()
		TYPE_ARRAY:
			compiler.write_equals()
			compiler.write_bracket_open()
			for flag in value:
				if flag is not Array or len(flag) != 3:
					compiler.warn(
						"Invalid bitflag option '", str(flag), "', incorrect format - should be [String,String,int]"
					)
					continue
				var flag_name = flag[0]
				var flag_bit = flag[1]
				var flag_default_value = flag[2]

				if flag_default_value is not bool or flag_name is not String or flag_bit is not int:
					compiler.warn(
						"Bitflag options are not of valid form, they should be [String,int,bool], received",
						flag
					)
					continue

				compiler.write_integer(1 << flag_bit)
				compiler.write_colon()
				compiler.write_string(flag_name)
				compiler.write_colon()
				compiler.write_integer(1 if flag_default_value else 0)
				compiler.write_new_line()
			compiler.write_bracket_close()
		_:
			compiler.severe(
				"Property '",
				name,
				"' is of type ",
				type_string(typeof(value)),
				", which is not a supported property type. This may cause undesirable results."
			)

			if value is Object:
				compiler.warn(
					"Property ",
					name,
					" is a GodotObject but not a Resource, this property will be non-functional."
				)
			# by default it will just be a string
			compiler.write_string("")
			pass


func compile(options: FuncGodotFGDCompiler.Options) -> FuncGodotFGDCompiler:
	var compiler := FuncGodotFGDCompiler.new_from_resource(self, options)
	if func_godot_internal: return compiler

	compiler.info("Compiling Entity")

	# ensure all of our properties are set properly
	_bridge_csharp_properties(compiler)

	if self is FuncGodotFGDModelPointClass and not omit_angles_property:
		class_properties["angles"] = "0.0 0.0 0.0"
		class_property_descriptions["angles"] = "Euler angles for this entity"

	# Class prefix
	# var res: String = prefix
	compiler.write_comment("FGD Entity '%s'  '%s'" % [classname, resource_path])

	compiler.compose(_compile_bases_and_meta(options))

	if compiler.has_fatal_errors(): return compiler

	compiler.write_equals()
	compiler.write_word(classname)

	if prefix != "@BaseClass":  # having a description in BaseClasses crashes some editors
		compiler.write_colon()
		compiler.write_string(description)

	compiler.write_bracket_open()
	
	if "targetname" not in class_properties:
		class_properties.set("targetname", TargetId.new())

	# Class properties
	for prop in class_properties:
		var value: Variant = class_properties[prop]

		var prop_type := fgd_typename_of(prop, value)

		if prop_type.is_empty():
			continue

		compiler.write_word(prop)
		compiler.write_paren_open()
		compiler.write_word(prop_type)
		compiler.write_paren_close()

		# flag types do not support descriptions
		if prop_type != "flags":
			compiler.write_colon()
			if prop in class_property_descriptions and class_property_descriptions[prop]:
				# Optional default value for Choices can be set up as [String, int]
				if value is Dictionary and class_property_descriptions[prop] is Array:
					var prop_arr: Array = class_property_descriptions[prop]
					if prop_arr.size() == 2 and (prop_arr[1] is int or prop_arr[1] is String) and prop_arr[0] is String:
						compiler.write_string(prop_arr[0])
						compiler.write_colon()
						compiler.write_string(str(prop_arr[1]))
					else:
						compiler.severe(
							prop,
							" has incorrect description format. Should be [String description, int / String default value], received: ",
							prop_arr
						)
						compiler.write_string("(invalid description)")
				else:
					compiler.write_string(class_property_descriptions[prop])
			else:
				compiler.write_string("")

		_compile_property_value(compiler, prop, value)
		compiler.write_new_line()

	compiler.write_bracket_close()
	compiler.write_new_line()

	return compiler

func retrieve_all_class_properties(properties: Dictionary[String, Variant]={}) -> Dictionary[String, Variant]:
	for key in class_properties.keys():
		properties[key] = class_properties[key]
	for b in base_classes:
		properties = b.retrieve_all_class_properties(properties)
	return properties

func retrieve_all_class_property_descriptions(
	descriptions: Dictionary[String, Variant]={}
) -> Dictionary[String, Variant]:
	for key in class_property_descriptions.keys():
		descriptions[key] = class_property_descriptions[key]
	for b in base_classes:
		descriptions = b.retrieve_all_class_property_descriptions(descriptions)
	return descriptions


## Attempts to find a C# script to use for bindings, this is meant to be overloaded by
## Implementors of FuncGodotFGDEntityClass
func find_csharp_bindings() -> CSharpScript:
	return null

## Regenerates `class_properties` and `class_property_descriptions` from the 
## attached C# script if it exists, else this will do nothing.
func _bridge_csharp_properties(compiler: FuncGodotFGDCompiler) -> void:
	var csharp_bridge_script := find_csharp_bindings()

	if not is_valid_csharp_script(csharp_bridge_script):
		return

	var bridge: Object = _get_csharp_wrapper()

	var script_instance: Object = csharp_bridge_script.new()

	if script_instance == null:
		if compiler:
			compiler.fatal(
				"[FuncGodotFGDEntityClass] Failed to instantiate c# script ",
				csharp_bridge_script.resource_path
			)
		return

	bridge.FgdCompiler = compiler
	bridge.ScriptInstance = script_instance

	var info = bridge.CompileFgdProperties();

	class_properties = info.ClassProperties as Dictionary[String, Variant]
	class_property_descriptions = info.ClassPropertiesDescriptions as Dictionary[String, Variant]

	if info.Description != null:
		description = info.Description
	else:
		description = "No Description"

func _validate_property(property: Dictionary) -> void:
	var name: String = property.name

	# hide the tool button if there isn't a bridge script attached
	if not is_valid_csharp_script(self.find_csharp_bindings()):
		if name.begins_with("csharp_"):
			property.usage = PROPERTY_USAGE_NO_EDITOR
		return

	# if class_properties and descriptions are being generated via a script then lock them
	# in the editor so user can't edit it just for it to be deleted when it refreshes the bindings
	if name in [&"class_properties", &"class_property_descriptions", &"auto_apply_to_matching_node_properties"]:
		property.usage |= PROPERTY_USAGE_READ_ONLY

	if name == &"description":
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _property_can_revert(property: StringName) -> bool:
	if self.find_csharp_bindings() == null:
		return false

	return property in [
		&"class_properties",
		&"class_property_descriptions",
		&"description",
		&"auto_apply_to_matching_node_properties"
	]

## predicate for if a given script is valid to use for the automatic C# property generation
static func is_valid_csharp_script(script: Script) -> bool:
	if script == null or script is not CSharpScript:
		return false

	return ClassDB.is_parent_class(script.get_instance_base_type(), &"Node")


## Constructs a new FuncGodotFGDEntityClass (with Resource.duplicate) that has all 
## of its inherited class properties, class descriptions, and meta properties baked into its own 
## definitions for properties, descriptions, & meta properties.
##
## The compiler is used for error handling
func bake_inherited_properties() -> FuncGodotFGDEntityClass:
	var entity: FuncGodotFGDEntityClass = self.duplicate()

	for base_class in _generate_base_class_list():
		base_class._bake_properties_to(entity)

	# overwrite because the origianal set values
	# take precedent over inherited ones
	_bake_properties_to(entity)

	return entity

## merges this entity's meta properties, class properties, and class property descriptions into the respective
## values in given 'target' 
## The compiler is used for error handling
func _bake_properties_to(target: FuncGodotFGDEntityClass):
	target.meta_properties.merge(self.meta_properties)
	target.class_properties.merge(self.class_properties)
	target.class_property_descriptions.merge(self.class_property_descriptions)


## Gets a list of all base classes of this node recursively
func _generate_base_class_list(visited_base_classes: Array[String]=[]) -> Array[FuncGodotFGDEntityClass]:
	var base_classes: Array[FuncGodotFGDEntityClass] = []

	visited_base_classes.append(classname)

	# End recursive search if no more base_classes
	if base_classes.is_empty():
		return base_classes

	# Traverse up to the next level of hierarchy, if not already visited
	for base_class in self.base_classes:
		if not base_class.classname in visited_base_classes:
			base_classes.append(base_class)
			base_classes += base_class._generate_base_class_list(visited_base_classes)
		else:
			push_error("Entity '%s' contains cycle/duplicate to Entity '%s'", classname, base_class.classname)

	return base_classes


func _apply_csharp_properties(node: Node, properties: Dictionary[String, Variant]):
	var script := node.get_script() as CSharpScript

	if not is_valid_csharp_script(script):
		return

	# script used for the type reflection
	var reflected := node if script.is_tool() else script.new()

	var bridge: Object = _get_csharp_wrapper()
	bridge.ScriptInstance = reflected
	# this also mutates 'properties' to remove the values it used
	bridge.ApplyFgdProperties(node, properties)

func _build_and_apply_property(node: Node, property: String, value: Variant):

	if property not in node:
		return

	if typeof(node.get(property)) == typeof(value):
		node.set(property, value)
	else:
		push_error(
			"Entity %s property \'%s\' type mismatch with matching generated node property."
				% [node.name, property]
		)

func build_and_apply_properties(node: Node, properties: Dictionary[String, Variant]):
	_bridge_csharp_properties(null)

	_apply_csharp_properties(node, properties)

	if auto_apply_to_matching_node_properties:
		if "func_godot_properties" in node:
			node.func_godot_properties = properties

		if "FuncGodotProperties" in node:
			node.FuncGodotProperties = properties

	if node.has_method("_func_godot_apply_properties"):
		node.call("_func_godot_apply_properties", properties)
	elif node.has_method("FuncGodotApplyProperties"):
		node.call("FuncGodotApplyProperties", properties)

	if auto_apply_to_matching_node_properties:
		for property in properties:
			_build_and_apply_property(node, property, properties[property])

	if node.has_method("_func_godot_build_complete"):
		node.call_deferred("_func_godot_build_complete")

	if node.has_method("FuncGodotBuildComplete"):
		node.call_deferred("FuncGodotBuildComplete")
		

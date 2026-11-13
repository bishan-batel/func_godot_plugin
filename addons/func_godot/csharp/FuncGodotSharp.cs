using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Godot;
using Godot.Collections;
using project.addons.func_godot.csharp.reflection;
using project.addons.func_godot.csharp.reflection.serializer;
using Array = Godot.Collections.Array;
using GDDictionary = Godot.Collections.Dictionary<string, Godot.Variant>;
using BitFlagGroups = System.Collections.Generic.Dictionary<string, System.Collections.Generic.List<(System.Reflection.PropertyInfo property, byte bit)>>;

namespace project.addons.func_godot.csharp;

/// <summary>
/// Script for use with generating an FgdFile's `class_properties` and `class_property_descriptions` via reflection.
/// </summary>
/// <example>
/// <code>
/// public partial class StreetLamp : Node {
///   [Export, FgdProperty]
///   public float Brightness { set; get; }
/// }
/// </code>
///
/// Then create a new resource file of type `FuncGodotPointEntityClass` (or just require click the script/scene file in-editor) and select its source script to `StreetLamp.cs`.
///
/// Now the resource file you have will have automatically generated values for `class_properties and `class_property_descriptions`.
/// Give this a name like `street_lamp_base`.
///
/// After, create a FuncGodotFGDSolidClass or FuncGodotFGDPointClass for your scene (class name `street_lamp`),
/// and attach the resource file (`street_lamp_base`) you made as a base.
///
/// In the world defaults, add both `street_lamp` and `street_lamp_base`, and you are done.
/// </example>
[Tool]
public partial class FuncGodotSharp : GodotObject {
  /// <summary>
  /// Name of the spawn flags property, this constant is defined via the Quake FGD Format itsefl
  /// </summary>
  public const string SpawnFlagsName = "spawnflags";

  /// <summary>
  /// Serializers for simple integral / floating point types / any type
  /// that can be supported with just <see cref="FgdSimpleVariantSerializer{T}"/>
  /// </summary>
  public static readonly IFgdSerializer[] SimpleSerializers = [
    new FgdSimpleVariantSerializer<bool>(),
    new FgdSimpleVariantSerializer<byte>(),
    new FgdSimpleVariantSerializer<short>(),
    new FgdSimpleVariantSerializer<int>(),
    new FgdSimpleVariantSerializer<long>(),
    new FgdSimpleVariantSerializer<ushort>(),
    new FgdSimpleVariantSerializer<uint>(),
    new FgdSimpleVariantSerializer<ulong>(),
    new FgdSimpleVariantSerializer<float>(),
    new FgdSimpleVariantSerializer<double>(),
  ];

  /// <summary>
  /// Serializers for any type that is an <see cref="Godot.Collections.Array{T}"/>, ie supported by <see cref="FgdArraySerializer{TElement}"/>.
  /// 
  /// Note this list intentionally omits supporting arrays of strings, as there is no clear way to delimit those and for cases like that
  /// it makes more sense to pass the parsing of <c>string></c> -> <c>string[]</c> to the callsite.
  /// </summary>
  public static readonly IFgdSerializer[] PackedArraySerializers = [
    new FgdArraySerializer<byte>(),
    new FgdArraySerializer<short>(),
    new FgdArraySerializer<int>(),
    new FgdArraySerializer<long>(),
    new FgdArraySerializer<ushort>(),
    new FgdArraySerializer<uint>(),
    new FgdArraySerializer<ulong>(),
    new FgdArraySerializer<float>(),
    new FgdArraySerializer<double>(),
  ];

  public static readonly IFgdSerializer[] CompositeSerializers = [
    new FgdColorSerializer(),
    new FgdVector2Serializer(),
    new FgdVector2ISerializer(),
    new FgdVector3Serializer(),
    new FgdVector3ISerializer(),
    new FgdVector4Serializer(),
    new FgdVector4ISerializer(),
  ];

  /// <summary>
  /// All usable serializers for different types of FgdProperties
  /// </summary>
  public static readonly IFgdSerializer[] Serializers = [
    new EnumSerializer(),
    .. SimpleSerializers,
    new FgdStringSerializer(),
    new FgdStringNameSerializer(),
    new FgdTargetIdSerializer(),
    .. CompositeSerializers,
    .. PackedArraySerializers,
    new FgdResourceSerializer(),
  ];


  /// <summary>
  /// Instance of the script being reflected on, this is distinct from when using this class
  /// to decode a FGD entity, as in the editor a given Node may have a C# script attached - however
  /// if that C# script isn't a tool script, then the node reference will not be bound to an actual C# instance,
  /// therefore calling <c>node.GetType()</c> will always return
  /// </summary>
  public required GodotObject ScriptInstance { get; set; }

  /// <summary>
  /// Type of the script instance, shorthand for <c>ScriptInstance.GetType()</c>
  /// </summary>
  public Type ScriptType => ScriptInstance.GetType();

  /// <summary>
  /// Compiler reference for additional logging. This must be of type FGDCompiler, which is a GDScript defined type.
  /// </summary>
  GodotObject? FgdCompiler { get; set; }

  /// <summary>
  /// Invokes a given method on <see cref="FgdCompiler"/>, this does nothing if no <see cref="FgdCompiler"/> has been
  /// set.
  /// </summary>
  /// <param name="method"></param>
  /// <param name="values"></param>
  void _invokeFgdCompilerMethod(string method, string[] values) => FgdCompiler?.Call(method, [.. values]);

  /// <summary>
  /// Omits a info message to the FGD compiler
  /// </summary>
  /// <param name="values">Values to stringify for the message</param>
  public void Info(params string[] values) => _invokeFgdCompilerMethod("info", values);

  /// <summary>
  /// Omits a warning message to the FGD compiler
  /// </summary>
  /// <param name="values">Values to stringify for the message</param>
  public void Warn(params string[] values) => _invokeFgdCompilerMethod("warn", values);

  /// <summary>
  /// Omits a severe message to the FGD compiler
  /// </summary>
  /// <param name="values">Values to stringify for the message</param>
  public void Severe(params string[] values) => _invokeFgdCompilerMethod("severe", values);

  /// <summary>
  /// Omits a fatal message to the FGD compiler, this means that after this method is called
  /// the export process is considered unusable and will not let the user confirm the export.
  /// </summary>
  /// <param name="values">Values to stringify for the message</param>
  public void Fatal(params string[] values) => _invokeFgdCompilerMethod("fatal", values);


  /// <summary>
  /// String for bbcode that encodes this scripts name with a URL to its path
  /// </summary>
  public string ScriptNameBbCode =>
    ScriptInstance.GetScript().Obj is CSharpScript script
      ? $"[url=\"{script.ResourcePath.JSONEscape()}\"]{ScriptType.Name}[/url]"
      : ScriptType.Name;

  /// <summary>
  /// Checks whether the given property info is both writable and readable, which is a requirement for FGD.
  /// If this is not, then this will omit a warning.
  /// </summary>
  public bool CheckIsPropertyReadWrite(PropertyInfo property) {
    if (property is { CanWrite: true, CanRead: true }) return true;

    Warn($"C# property {ScriptNameBbCode}.{property.Name} must have both a setter and getter to be valid for FGD Reflection.");
    return false;
  }

  bool _isPropertyValid(PropertyInfo property, bool requireExport = true, bool requirePascal = true) {
    if (property.Name.ToPascalCase() != property.Name) {
      Warn(
        "FGD Property: ",
        ScriptNameBbCode,
        ".",
        property.Name,
        " has incorrect naming, C# properties *must* be in [code]PascalCase[/code] in order to support name translation to FuncGodot conventions."
      );
      return false;
    }

    if (!CheckIsPropertyReadWrite(property)) return false;

    if (requireExport && property.GetCustomAttribute<ExportAttribute>() is null) {
      Warn("FGD property: ", ScriptNameBbCode, ".", property.Name, " must have both a FgdProperty attribute as well as be Exported.");
      return false;
    }

    if (FindSerializerForProperty(property) is not null) return true;
    Severe("Unsupported FGD property type: ", ScriptNameBbCode, ".", property.Name, " : ", property.PropertyType.Name);
    return false;
  }

  FgdPropertyInfo _propertyToFgd(PropertyInfo info, bool builtinGodot = false) {
    // C# based properties need to be in snake case
    string propertyName = info.Name.ToSnakeCase();

    Variant defaultValue = FindSerializerForProperty(info)!.Serialize(
      ScriptInstance.Get(builtinGodot ? propertyName : info.Name),
      info
    );

    string description =
      info.GetCustomAttribute<FgdPropertyAttribute>()?.Description
      ?? Documentation.GetFgdOrSummary(info)
      ?? string.Empty;

    if (!info.PropertyType.IsEnum) {
      return new FgdPropertyInfo {
        Name = propertyName,
        DefaultValue = defaultValue,
        Description = description,
        RequiresSnakeCase = builtinGodot,
        ReflectInfo = info,
      };
    }

    string[] names = info.PropertyType.GetEnumNames();
    IEnumerable<int> values = info.PropertyType.GetEnumValues().Cast<int>();

    var choices = new GDDictionary();

    foreach ((string name, int value) in names.Zip(values)) {
      choices.Add(name, value);
    }

    // https://func-godot.github.io/func_godot_docs/FuncGodot%20Manual/FuncGodot%20Manual.html
    // weird hack FuncGodot does to support default values for enums
    return new FgdPropertyInfo {
      Name = propertyName,
      DefaultValue = choices,
      Description = new Array { description, defaultValue },
      ReflectInfo = info
    };
  }

  public partial class FgdBridgedEntity : GodotObject {
    public string? Description;
    public required GDDictionary ClassProperties;
    public required GDDictionary ClassPropertiesDescriptions;
  }

  /// <summary>
  /// Gets the ClassProperties and ClassPropertiesDescriptions dictionaries for FGD generation in the
  /// jank format thet FuncGodot wants.
  /// </summary>
  public FgdBridgedEntity CompileFgdProperties() {
    IEnumerable<FgdPropertyInfo> properties = [
      .. _getBitFlagProperties(),
      .. _getPlainProperties(),
      .. _getCustomProperties(),
      .. _getTargetProperties()
    ];

    if (_getSpawnFlagsProperty() is { } spawnFlags) {
      properties = properties.Append(spawnFlags);
    }


    GDDictionary classProperties = new(), classDescriptions = new();

    foreach (FgdPropertyInfo property in properties) {
      if (classProperties.ContainsKey(property.Name)) {
        GD.PushWarning();
      }

      classProperties.Add(property.Name, property.DefaultValue);
      classDescriptions.Add(property.Name, property.Description);
    }

    return new FgdBridgedEntity {
      ClassProperties = classProperties,
      ClassPropertiesDescriptions = classDescriptions,
      Description = Documentation.GetFgdOrSummary(ScriptType.GetTypeInfo())
    };
  }

  IEnumerable<FgdPropertyInfo> _getTargetProperties() {
    IEnumerable<FgdPropertyInfo> properties = [];

    Type[] interfaces = [
      .. ScriptType
        .GetInterfaces()
        .Where(type => type.IsGenericType)
        .Select(type => type.GetGenericTypeDefinition())
    ];

    if (ScriptInstance is IFuncTargeter || interfaces.Contains(typeof(IFuncTargeter<>))) {
      properties = [
        .. properties,
        new FgdPropertyInfo {
          Name = "target",
          DefaultValue = new TargetId(),
          Description = "Target",
          ReflectInfo = null
        },
      ];
    }

    if (ScriptInstance is IFuncTargetable || interfaces.Contains(typeof(IFuncTargetable<>))) {
      properties = [
        .. properties,
        new FgdPropertyInfo {
          Name = "targetname",
          DefaultValue = new TargetId(),
          Description = "Name of this target",
          ReflectInfo = null
        },
      ];
    }

    return properties;
  }

  IEnumerable<FgdPropertyInfo> _getCustomProperties() {
    if (ScriptInstance is not IFuncEntity entity) {
      return [];
    }

    return [
      .. entity.BuiltinGodotTypeFgdProperties
        .Select(name => ScriptType.GetProperty(name.ToString().ToPascalCase()))
        .OfType<PropertyInfo>()
        .Where(info => _isPropertyValid(info, requireExport: false, requirePascal: false))
        .Select(info => _propertyToFgd(info, true)),
      .. entity.GetCustomFgdProperties(),
    ];
  }

  IEnumerable<FgdPropertyInfo> _getPlainProperties() =>
    GetAllProperties()
      .Where(member => member.GetCustomAttribute<FgdPropertyAttribute>() is not null)
      .Where(info => _isPropertyValid(info))
      .Select(info => _propertyToFgd(info));


  /// <summary>
  /// Gets all properties that may be elligible for reflection
  /// </summary>
  /// <returns></returns>
  public IEnumerable<PropertyInfo> GetAllProperties() => ScriptType.GetProperties(
    BindingFlags.Public |
    BindingFlags.NonPublic |
    BindingFlags.Instance
  );

  FgdPropertyInfo _getSpawnFlagsProperty() {
    List<(PropertyInfo property, byte bit)> flags = _getSpawnFlags();

    return new FgdPropertyInfo {
      Name = SpawnFlagsName, // we use the group name as the name of the whole property
      Description = default, // bitflags do not support descriptions
      // the default value controls is what gives func godot the information
      // for what flags are in a bitflag, the format is an Array[Array[string flagName, int bit, bool defaultValue]]
      DefaultValue = new Array<Array>(
        flags.Select(pair => new Array([
          pair.property.Name,
          pair.bit,
          (bool)ScriptInstance.Get(pair.property.Name)
        ]))
      ),
      ReflectInfo = null
    };
  }

  List<(PropertyInfo property, byte bit)> _getSpawnFlags() {
    List<(PropertyInfo property, byte bit)> flags = [
      .. GetAllProperties()
        .Where(property => property.GetCustomAttribute<FgdSpawnFlagAttribute>() is not null)
        .Where(property => {
          if (property.PropertyType == typeof(bool)) return true;
          Warn($"Improper use of [FgdSpawnFlag] of property {ScriptNameBbCode}.{property.Name}, [FgdSpawnFlag] only works on bool properties.");
          return false;
        })
        .Where(CheckIsPropertyReadWrite)
        .Select(property => (property, property.GetCustomAttribute<FgdSpawnFlagAttribute>()!.Bit))
    ];

    flags.Sort((a, b) => a.bit - b.bit);

    return flags;
  }

  IEnumerable<FgdPropertyInfo> _getBitFlagProperties() =>
    _getBitFlags()
      // for each bitflag group convert it to a property ingo
      .Select(bitflag => new FgdPropertyInfo {
        Name = bitflag.Key, // we use the group name as the name of the whole property
        Description = default, // bitflags do not support descriptions
        // the default value controls is what gives func godot the information
        // for what flags are in a bitflag, the format is an Array[Array[string flagName, int bit, bool defaultValue]]
        DefaultValue = new Array<Array>(
          bitflag
            .Value
            .Select(pair => new Array([
              pair.property.Name.TrimPrefix(bitflag.Key),
              pair.bit,
              (bool)ScriptInstance.Get(pair.property.Name)
            ]))
        ),
        ReflectInfo = null
      });

  /// <summary>
  /// Gets a dictionary where the keys are the flag group and the values are a list of all properties
  /// </summary>
  BitFlagGroups _getBitFlags() {
    return GetAllProperties()

      // Filter for all properties with the FgdFlag attribute
      .Where(property => property.GetCustomAttribute<FgdFlagAttribute>() is not null)
      .Where(property => {
        bool hasPropertyAttribute = property.GetCustomAttribute<FgdPropertyAttribute>() is not null;
        bool hasSpawnAttribute = property.GetCustomAttribute<FgdSpawnFlagAttribute>() is not null;

        if (hasPropertyAttribute) {
          Warn(
            $"Property {ScriptNameBbCode}.{property.Name} is incorrectly configured. ",
            "[FgdProperty] and [FgdFlag] are mutually exclusive to prevent conflicts."
          );
          return false;
        }

        if (hasSpawnAttribute) {
          Warn(
            $"Property {ScriptNameBbCode}.{property.Name} is incorrectly configured. ",
            "[FgdSpawnFlag] and [FgdFlag] are mutually exclusive to prevent conflicts."
          );
          return false;
        }

        return true;
      })

      // filter for boolean properties
      .Where(property => {
        if (property.PropertyType == typeof(bool)) return true;
        Warn($"Improper use of [FgdFlag] of property {ScriptNameBbCode}.{property.Name}, [FgdFlag] only works on bool properties.");
        return false;
      })
      .Where(CheckIsPropertyReadWrite)
      .Select(property => (property, attribute: property.GetCustomAttribute<FgdFlagAttribute>()!))
      // .OfType<(PropertyInfo property, FgdFlagAttribute attribute)>()

      // Group all properties together that share the same group name so we have
      // a pairing from group name to list of all properties in that group
      .GroupBy(pair => pair.attribute.Group.ToSnakeCase())
      .ToDictionary(
        group => group.Key,
        group => group.Select(x => (x.property, bit: x.attribute.Bit)).ToList()
      );
  }

  /// <summary>
  /// Applies any C# specific properties that are more complex than just setting a property with a given name.
  ///
  /// Currently, all this does is take care of bit flags.
  /// </summary>
  public void ApplyFgdProperties(Node node, GDDictionary properties) {
    _applyBitflags(node, properties);
    _applyProperties(node, properties);
  }

  void _applyProperties(Node node, GDDictionary properties) {
    IEnumerable<FgdPropertyInfo> fgdProperties = [
      .. _getPlainProperties(),
      .. _getCustomProperties()
    ];

    foreach (FgdPropertyInfo property in fgdProperties) {
      if (property.DeserializeWithGdScript) continue;

      if (!properties.Remove(property.Name, out Variant value)) continue;

      string name = property.RequiresSnakeCase ? property.Name : property.Name.ToPascalCase();

      node.Set(name, _convertValue(property, value));
    }
  }

  void _applyBitflags(Node node, GDDictionary properties) {
    BitFlagGroups allFlags = _getBitFlags();
    allFlags[SpawnFlagsName] = _getSpawnFlags();

    foreach ((string name, List<(PropertyInfo property, byte bit)> flags) in allFlags) {
      if (!properties.Remove(name, out Variant flagVariant)) continue;
      int flagBits = flagVariant.AsInt32();

      foreach ((PropertyInfo property, byte bit) in flags) {
        node.Set(property.Name, (flagBits & (1 << bit)) != 0);
      }
    }
  }


  static Variant _convertValue(FgdPropertyInfo info, Variant value) {
    PropertyInfo? reflection = info.ReflectInfo;

    if (reflection is null) return value;

    return FindSerializerForProperty(reflection)?.DeserializeToVariant(value, reflection) ?? value;
  }

  /// <summary>
  /// Attempts to find a supported <see cref="IFgdSerializer"/> that should be used with a
  /// given FGDProperty <paramref name="info"/> 
  /// </summary>
  /// <param name="info"></param>
  /// <returns></returns>
  public static IFgdSerializer? FindSerializerForProperty(PropertyInfo info) =>
    Serializers.FirstOrDefault(serializer => serializer.CanEncode(info));
}
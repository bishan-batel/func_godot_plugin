using System.Reflection;
using Godot;

namespace project.addons.func_godot.csharp.reflection;

/// <summary>
/// Custom property to generate into a FGDFile
/// </summary>
public partial class FgdPropertyInfo : GodotObject {
  /// <summary>
  /// Property name, used as the key for both `class_properties` and `class_properties_description`
  /// </summary>
  public required string Name;

  /// <summary>
  /// Controls whether when calling 'set' and 'get' should it use snake_case
  /// </summary>
  public bool RequiresSnakeCase = false;

  /// <summary>
  /// Default value used in `class_properties`.
  /// </summary>
  public required Variant DefaultValue;

  /// <summary>
  /// Description string or a dictionary if implementing a choice
  /// </summary>
  public required Variant Description;

  /// <summary>
  /// Optional reflection info of this property, may be absent if this is a procedural
  /// </summary>
  public required PropertyInfo? ReflectInfo;

  public bool DeserializeWithGdScript = false;
}
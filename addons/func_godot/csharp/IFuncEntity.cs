using System.Collections.Generic;
using Godot;

// ReSharper disable ValueParameterNotUsed

namespace project.addons.func_godot.csharp;

/// <summary>
/// Interface for doing more complex things with TrenchBroom integration with your class.
/// </summary>
public interface IFuncEntity : IFuncNodeLike {
  public static readonly StringName MeshDataMetaPath = "func_godot_mesh_data";

  /// <summary>
  /// List of property names that are from a <b>built-in</b> godot inherited type.
  /// </summary>
  ///
  /// <example>
  /// For example, if your class extends from
  /// <see cref="Node2D"/> and you wish to expose "GlobalRotation", to do so you can implement IFuncEntity and overload this
  /// property to:
  /// <code>
  /// public IEnumerable&lt;StringName&gt; BuiltinGodotTypeFgdProperties => [
  ///   Node.PropertyName.GlobalRotation
  /// ];
  /// </code>
  ///
  /// Alternatively for more control, you can do:
  ///
  /// <code>
  /// [FgdProperty]
  /// public new float GlobalRotation {
  ///   set => base.GlobalRotation = value;
  ///   get => base.GlobalRotation;
  /// }
  /// </code>
  /// </example>
  ///
  /// <example>
  /// Explicitly creating a new property that just uses/shadows the base is more verbose but may
  /// be clearer for what you are trying to write. The only time this should be required though is
  /// when you are trying to expose a 'bool' property as a spawnflag.
  ///
  /// <code>
  /// [FgdSpawnFlag(0)]
  /// public new bool OneShot {
  ///   get => base.OneShot;
  ///   set => base.OneShot = value;
  /// }
  /// </code>
  /// </example>
  public IEnumerable<StringName> BuiltinGodotTypeFgdProperties => [];

  /// <summary>
  /// Gets a custom list of FGD properties to generate into the definition file. Only use if you know what you are doing.
  /// </summary>
  /// <returns></returns>
  public List<reflection.FgdPropertyInfo> GetCustomFgdProperties() {
    return [];
  }


  /// <summary>
  /// Callback for applying properties from the map file
  /// </summary>
  /// <param name="properties"></param>
  public void FuncGodotApplyProperties(Godot.Collections.Dictionary<string, Variant> properties) {
    _ = properties;
  }


  /// <summary>
  /// Callback for when a func godot map finishes building this entity
  /// </summary>
  public void FuncGodotBuildComplete() {
  }
}
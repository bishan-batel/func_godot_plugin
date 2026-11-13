using System.Collections.Generic;
using Godot;

namespace project.addons.func_godot.csharp;

/// <summary>
/// Extension functions to support manipulating values loaded from the FGD build process
/// </summary>
public static class FgdEntityExtensions {
  /// <summary>
  /// Metadata key that the FuncGodotProperties are stored in
  /// </summary>
  public const string FgdMeta = "func_godot_properties";

  /// <summary>
  /// Gets the 'target' group for this node.
  /// </summary>
  public static TargetId GetTarget<T>(this T activator) where T : IFuncNodeLike => new(
    activator.GetFgdProperty<StringName>("target", TargetId.EmptyGroup)
  );

  /// <summary>
  /// Builtin target name
  /// </summary>
  public static TargetId GetTargetName<T>(this T node) where T : IFuncNodeLike => new(
    node.GetFgdProperty<StringName>("targetname", TargetId.EmptyGroup)
  );

  /// <summary>
  /// Builtin 'killtarget' property
  /// </summary>
  public static TargetId GetKillTarget<T>(this T node) where T : IFuncNodeLike => new(
    node.GetFgdProperty<StringName>("killtarget", TargetId.EmptyGroup)
  );

  /// <summary>
  /// Returns the FGD properties loaded from the map file during the last build/import process.
  /// </summary>
  public static Godot.Collections.Dictionary<string, Variant> GetFgdMeta(this IFuncNodeLike node) {
    return node.HasMeta(FgdMeta)
      ? node.GetMeta(FgdMeta).AsGodotDictionary<string, Variant>()
      : [];
  }

  /// <summary>
  /// Finds the property of the given name that was loaded from the .map file
  /// </summary>
  public static Variant GetFgdProperty(this IFuncNodeLike entity, string key, Variant @default = default)
    => entity.GetFgdMeta().GetValueOrDefault(key, @default);

  /// <summary>
  /// Finds the property of the given name and type that was loaded from the .map file
  /// </summary>
  public static T GetFgdProperty<[MustBeVariant] T>(this IFuncNodeLike entity,
    string key,
    Variant @default = default
  ) => entity.GetFgdMeta().GetValueOrDefault(key, @default).As<T>();
}
using System;
using Godot;

namespace project.addons.func_godot.csharp;

/// <summary>
/// Wrapper for both kill targets, target names and targets themselves.
///
/// Targets are typically handled as groups in FuncGodot, but this wrapper exists to serve as a type-level
/// delineation from just a StringName. 
/// </summary>
[GlobalClass, Tool]
public sealed partial class TargetId(StringName name) : Resource {
  public const string Prefix = "fgd_target_";

  /// <summary>
  /// Group for the 'empty' group / what happens if you leave targetname="", etc.
  /// </summary>
  public static readonly StringName EmptyGroup = "";

  /// <summary>
  /// Empty TargetId
  /// </summary>
  public static TargetId Empty => new(EmptyGroup);

  [Export] public StringName Name { get; private set; } = name;

  /// <summary>
  /// Gets this target as its corresponding godot group
  /// </summary>
  public StringName Group => Prefix + Name;

  /// <summary>
  /// Whether this is a 'null' group / the default
  /// </summary>
  public bool IsEmpty => Name.IsEmpty;

  public TargetId() : this(EmptyGroup) {
  }

  public override string ToString() => Group;

  public bool Equals(TargetId? other) => Name == other?.Name;
}
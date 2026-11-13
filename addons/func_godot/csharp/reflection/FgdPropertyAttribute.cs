using System;

namespace project.addons.func_godot.csharp.reflection;

/// <summary>
/// Attribute meant to attach to `[Export]` fields to signify that this property
/// should be configurable within TrenchBroom
/// </summary>
[AttributeUsage(AttributeTargets.Property)]
public class FgdPropertyAttribute(string? description = null) : Attribute {
  /// <summary>
  /// Custom description for this property
  /// </summary>
  public string? Description { get; } = description;
}
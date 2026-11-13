// Copyright Digipen 2026
// Created 10/16/2026 by Kishan S Patel
// Team Gross Incandescence

using System;

namespace project.addons.func_godot.csharp.reflection;

/// <summary>
/// An exported <b>boolean</b> property that will be part of a bit flag option in trench broom.
/// If you have many bool properties all with [FgdFlag("GroupName")], then in Trench Broom it will show up as a
/// single property 'GroupName' with bitflags for each respective option.
///
/// If you do not have a specific group name / there is only one group for your whole class, consider <see cref="FgdSpawnFlagAttribute"/>.
/// </summary>
/// <param name="group">
/// Name of the bit flags property this flag belongs to.
/// </param>
/// <param name="bit">
/// The bit position, this correlates to a value of <code>1 &lt;&lt; bit</code>.
/// This should be unique (when compared to all other properties in the same class with this attribute)
/// </param>
[AttributeUsage(AttributeTargets.Property)]
public class FgdFlagAttribute(string group, byte bit) : Attribute {
  /// <summary>
  /// Name of the bitflags group this flag is attached to
  /// </summary>
  public string Group { get; } = group;

  /// <summary>
  /// The bit position of this flag, this should be unique from all other flags in the same group
  /// </summary>
  public byte Bit { get; } = bit;
}
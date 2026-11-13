// Copyright Digipen 2026
// Created 10/17/2026 by Kishan S Patel
// Team Gross Incandescence

using System;

namespace project.addons.func_godot.csharp.reflection;

/// <summary>
/// Special instance of <see cref="FgdFlagAttribute"/> for the "spawnflags" field.
/// </summary>
/// <param name="bit">
/// The bit position, this correlates to a value of 2^bit.
/// This should be unique (when compared to all other properties in the same class with this attribute)
/// </param>
[AttributeUsage(AttributeTargets.Property)]
public class FgdSpawnFlagAttribute(byte bit) : Attribute {
  /// <summary>
  /// The bit position of this flag, this should be unique from all other spawn flags
  /// </summary>
  public byte Bit { get; } = bit;
}
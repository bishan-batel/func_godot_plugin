// Copyright Digipen 2026
// Created 11/01/2026 by Kishan S Patel
// Team Gross Incandescence

using System.Reflection;
using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// Serializer for any C# enum.
/// </summary>
public class EnumSerializer : IFgdSerializer {
  public bool CanEncode(PropertyInfo info) => info.PropertyType.IsEnum;

  public Variant Serialize(Variant value, PropertyInfo info) => value.AsInt64();

  public Variant DeserializeToVariant(Variant value, PropertyInfo info) => value;
}
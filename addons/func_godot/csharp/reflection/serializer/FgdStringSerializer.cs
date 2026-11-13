// Copyright Digipen 2026
// Created 10/22/2026 by Kishan S Patel
// Team Gross Incandescence

using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// <see cref="IFgdSerializer"/> implementation for a string.
/// </summary>
public class FgdStringSerializer : IFgdSerializer<string> {
  public Variant Serialize(string? value) => value ?? string.Empty;

  public string Deserialize(Variant value) => value.AsString();
}

/// <summary>
/// <see cref="IFgdSerializer"/> implementation for a <see cref="StringName"/>, which is treated identical to <see cref="string"/>.
/// </summary>
public class FgdStringNameSerializer : IFgdSerializer<StringName> {
  public Variant Serialize(StringName? value) => value ?? string.Empty;

  public StringName Deserialize(Variant value) => value.AsStringName();
}
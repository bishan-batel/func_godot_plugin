// Copyright Digipen 2026
// Created 10/23/2026 by Kishan S Patel
// Team Gross Incandescence

using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// <see cref="IFgdSerializer"/> implementation for <see cref="TargetId"/>. This type is treated differently than other <see cref="Resource"/>
/// FGD properties, because it really is just a typed wrapper over <see cref="StringName"/>.
/// </summary>
public class FgdTargetIdSerializer : IFgdSerializer<TargetId> {
  public Variant Serialize(TargetId? value) => value ?? TargetId.Empty;

  public TargetId Deserialize(Variant value) => new(value.AsStringName());
}
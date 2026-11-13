// Copyright Digipen 2026
// Created 10/23/2026 by Kishan S Patel
// Team Gross Incandescence

using System.Reflection;
using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// <see cref="IFgdSerializer"/> implementation for any tpe deriving from <see cref="Resource"/>.
/// This will encode / decode resources by the path to a resource file.
///
/// TODO: add additional specialized support for TrenchBroom supported resources like <see cref="AudioStreamWav"/>, <see cref="Texture"/>, etc
///</summary>
public class FgdResourceSerializer : IFgdSerializer<Resource?> {
  public bool CanEncode(PropertyInfo info) =>
    info.PropertyType.IsSubclassOf(typeof(Resource));


  public Variant Serialize(Resource? value) {
    return value?.ResourcePath ?? string.Empty;
  }

  public Resource? Deserialize(Variant value) {
    Resource? resource = ResourceLoader.Load(value.AsString());

    if (resource is null) {
      GD.PushWarning("[FuncGodoBuild] Failed to load resource from path ", value);
    }

    return resource;
  }
}
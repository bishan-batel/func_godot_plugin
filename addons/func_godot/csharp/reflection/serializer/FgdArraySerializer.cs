// Copyright Digipen 2026
// Created 10/22/2026 by Kishan S Patel
// Team Gross Incandescence

using System;
using System.Linq;
using Godot;
using Godot.Collections;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// Implementation fo a <see cref="IFgdSerializer"/> for the type of <see cref="Godot.Collections.Array{T}"/>,
/// ie a godot array of <typeparamref name="TElement"/>.
/// </summary>
/// <typeparam name="TElement">Element type of the array being serialized / deserialized</typeparam>
public class FgdArraySerializer<[MustBeVariant] TElement> : IFgdSerializer<Array<TElement>>
  where TElement : IParsable<TElement> {
  public Variant Serialize(Array<TElement>? value) => (value ?? [])
    .Select(element => $"{element}")
    .ToArray();

  public Array<TElement> Deserialize(Variant value) => [
    .. value
      .AsString()
      .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
      .Select(element => TElement.TryParse(element, null, out TElement? result) ? result : default)
      .OfType<TElement>()
  ];
}
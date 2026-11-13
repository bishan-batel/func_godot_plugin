// Copyright Digipen 2026
// Created 10/22/2026 by Kishan S Patel
// Team Gross Incandescence

using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// Simple generic <see cref="IFgdSerializer"/> for any simple type <typeparamref name="T"/>
/// that supports <see cref="MustBeVariantAttribute"/>, ie <see cref="Variant.From"/> and can
/// be the /// target type for <see cref="Variant.As"/>
/// </summary>
/// <typeparam name="T"></typeparam>
/// <fgd>Custom FGD Description</fgd>
public sealed class FgdSimpleVariantSerializer<[MustBeVariant] T> : IFgdSerializer<T> where T : struct {
  public Variant Serialize(T value) => Variant.From(value);

  public T Deserialize(Variant value) => value.As<T>();
}
// Copyright Digipen 2026
// Created 10/21/2026 by Kishan S Patel
// Team Gross Incandescence

using System.Reflection;
using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// A serializer type specifically for the process of encoding / decoding FGD Entity Classes.
/// </summary>
public interface IFgdSerializer {
  /// <summary>
  /// 
  /// </summary>
  /// <param name="info">Reflection for the property being serialized</param>
  /// <returns></returns>
  public bool CanEncode(PropertyInfo info);

  /// <summary>
  /// Serializes the given <paramref name="value"/> from the property <paramref name="info"/>
  /// into a Variant suitable for writing to a FGD class definition. Note that the list of
  /// possible Variant types is a superset to the supported types for a <see cref="FuncGodotSharp.FgdBridgedEntity"/>.
  /// </summary>
  /// <param name="value">Value of the property</param>
  /// <param name="info">Reflection for the property this value was loaded from</param>
  public Variant Serialize(Variant value, PropertyInfo info);

  /// <summary>
  /// Deserializes the given <paramref name="value"/> in order to assign to the property
  /// <paramref name="info"/> into a Variant suitable for writing to a FGD class definition.
  /// Note that the list of possible Variant types is a superset to the supported types for
  /// a <see cref="FuncGodotSharp.FgdBridgedEntity"/>, so there are limited options to what
  /// the input of <paramref name="value"/> could be.
  /// </summary>
  /// <param name="value">Value of the property</param>
  /// <param name="info">Reflection for the property this value was loaded from</param>
  public Variant DeserializeToVariant(Variant value, PropertyInfo info);
}

/// <summary>
/// Typed specific serializer for <see cref="IFgdSerializer"/>, this adds stricter
/// type specifications and is used to implement a FGDSerializer for any variant compatability type (satisfying <see cref="MustBeVariantAttribute"/>).
/// </summary>
/// <typeparam name="T">Variant compatible type this serializer is in charge of encoding</typeparam>
public interface IFgdSerializer<[MustBeVariant] T> : IFgdSerializer {
  /// <inheritdoc/>>
  bool IFgdSerializer.CanEncode(PropertyInfo info) => typeof(T) == info.PropertyType;

  /// <inheritdoc/>>
  Variant IFgdSerializer.Serialize(Variant value, PropertyInfo info) => Serialize(value.As<T>());

  /// <inheritdoc/>
  Variant IFgdSerializer.DeserializeToVariant(Variant value, PropertyInfo info) => Variant.From(Deserialize(value));

  /// <summary>
  /// Serializes the given <typeparamref name="T"/> into a <see cref="Variant"/>, note that the returned
  /// variant should only be of a type supported via <see cref="FuncGodotSharp.FgdBridgedEntity"/>.
  /// </summary>
  public Variant Serialize(T? value);

  /// <summary>
  /// Deserializes the given <paramref name="value"/> into a <typeparamref name="T"/>.
  /// </summary>
  /// <param name="value">Value of the property</param>
  public T Deserialize(Variant value);
}
// Copyright Digipen 2026
// Created 10/22/2026 by Kishan S Patel
// Team Gross Incandescence

using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

namespace project.addons.func_godot.csharp.reflection.serializer;

/// <summary>
/// Helper serializer type for any serializer that is encoded as a string of space delimited variants.
/// </summary>
public abstract class FgdParsableArraySerializer<[MustBeVariant] T, TElement> : IFgdSerializer<T>
  where TElement : struct, IParsable<TElement>
  where T : struct {
  /// <summary>
  /// Minimum length the array of numbers needs to be for deserialization, ie. <see cref="Vector3"/> would be 3.
  /// </summary>
  protected abstract int MinArrayLength { get; }

  /// <summary>
  /// Default element used to pad the parsed array to make sure there is at least <see cref="MinArrayLength"/>.
  /// </summary>
  protected virtual TElement Default => default;


  /// <summary>
  /// Decomposes a given element <paramref name="value"/> into an array of values.
  /// </summary>
  protected abstract IEnumerable<TElement> Decompose(T value);

  /// <summary>
  /// Constructs a <typeparamref name="T"/> from the given array of elements <paramref name="values"/>
  /// </summary>
  /// <param name="values">Array of <typeparamref name="TElement"/> values.
  /// This array will always be of size of at least <see cref="MinArrayLength"/> element
  /// s</param>
  protected abstract T FromArray(TElement[] values);

  public Variant Serialize(T value) => string.Join(' ', Decompose(value));

  public T Deserialize(Variant value) => FromArray([
    .. value
      .AsString()
      .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
      .Select(element =>
        TElement.TryParse(element, null, out TElement result) ? result : Default
      ),
    .. Enumerable.Repeat(Default, MinArrayLength)
  ]);
}

/// <summary>
/// Serializer for <see cref="Color"/>
/// </summary>
public class FgdColorSerializer : FgdParsableArraySerializer<Color, byte> {
  protected override int MinArrayLength => 4;


  protected override byte Default => 255;

  protected override IEnumerable<byte> Decompose(Color value) => [
    (byte)value.R8,
    (byte)value.G8,
    (byte)value.B8,
    (byte)value.A8
  ];

  protected override Color FromArray(byte[] values) => Color.Color8(
    values[0],
    values[1],
    values[2],
    values[3]
  );
}

/// <summary>
/// Serializer for <see cref="Vector2"/>
/// </summary>
public class FgdVector2Serializer : FgdParsableArraySerializer<Vector2, float> {
  protected override int MinArrayLength => 2;

  protected override IEnumerable<float> Decompose(Vector2 value) => [value.X, value.Y];

  protected override Vector2 FromArray(float[] values) => new(values[0], values[1]);
}

/// <summary>
/// Serializer for <see cref="Vector2I"/>
/// </summary>
public class FgdVector2ISerializer : FgdParsableArraySerializer<Vector2I, int> {
  protected override int MinArrayLength => 2;

  protected override IEnumerable<int> Decompose(Vector2I value) => [value.X, value.Y];

  protected override Vector2I FromArray(int[] values) => new(values[0], values[1]);
}

/// <summary>
/// Serializer for <see cref="Vector3"/>
/// </summary>
public class FgdVector3Serializer : FgdParsableArraySerializer<Vector3, float> {
  protected override int MinArrayLength => 3;

  protected override IEnumerable<float> Decompose(Vector3 value) => [value.X, value.Y, value.Z];

  protected override Vector3 FromArray(float[] values) => new(values[0], values[1], values[2]);
}

/// <summary>
/// Serializer for <see cref="Vector3I"/>
/// </summary>
public class FgdVector3ISerializer : FgdParsableArraySerializer<Vector3I, int> {
  protected override int MinArrayLength => 3;

  protected override IEnumerable<int> Decompose(Vector3I value) => [value.X, value.Y, value.Z];

  protected override Vector3I FromArray(int[] values) => new(values[0], values[1], values[2]);
}

/// <summary>
/// Serializer for <see cref="Vector4"/>
/// </summary>
public class FgdVector4Serializer : FgdParsableArraySerializer<Vector4, float> {
  protected override int MinArrayLength => 4;

  protected override IEnumerable<float> Decompose(Vector4 value) => [value.X, value.Y, value.Z];

  protected override Vector4 FromArray(float[] values) => new(values[0], values[1], values[2], values[4]);
}

/// <summary>
/// Serializer for <see cref="Vector4I"/>
/// </summary>
public class FgdVector4ISerializer : FgdParsableArraySerializer<Vector4I, int> {
  protected override int MinArrayLength => 4;

  protected override IEnumerable<int> Decompose(Vector4I value) => [value.X, value.Y, value.Z, value.W];

  protected override Vector4I FromArray(int[] values) => new(values[0], values[1], values[2], values[4]);
}
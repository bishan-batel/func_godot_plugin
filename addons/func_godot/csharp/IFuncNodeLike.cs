// Copyright Digipen 2026
// Created 10/22/2026 by Kishan S Patel
// Team Gross Incandescence

using Godot;

namespace project.addons.func_godot.csharp;

/// <summary>
/// This interface contains methods that aren't meant for users to
/// implement themselves, this namely serves as an abstraction of <see cref="Node"/>.
///
/// C# does not support native intersection types (ie. <code>SomeFunc(A|B value)</code>), so this
/// serves as a work around that contains every function related to 'Node'.
///
/// If the implementor of the type is a subclass of <see cref="Node"/>, no manual implementation is required.
/// </summary>
public interface IFuncNodeLike {
  /// <inheritdoc cref="Godot.Node.Name"/>
  public StringName Name { get; set; }

  /// <inheritdoc cref="Godot.Node.IsInsideTree"/>
  public bool IsInsideTree();

  /// <inheritdoc cref="Godot.Node.GetTree"/>
  public SceneTree GetTree();

  /// <inheritdoc cref="GodotObject.HasMeta(StringName)" />
  public bool HasMeta(StringName name);

  /// <inheritdoc cref="GodotObject.GetMeta(StringName, Variant)" />
  public Variant GetMeta(StringName name, Variant @default = default);

  /// <inheritdoc cref="GodotObject.Get(StringName)" />
  public Variant Get(StringName name);

  /// <inheritdoc cref="GodotObject.Set(StringName, Variant)"/>
  public void Set(StringName name, Variant value);

  /// <inheritdoc cref="Node.QueueFree"/>
  public void QueueFree();
}
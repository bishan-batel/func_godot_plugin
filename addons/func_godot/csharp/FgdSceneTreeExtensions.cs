using System.Collections.Generic;
using System.Linq;
using Godot;

namespace project.addons.func_godot.csharp;

public static class FgdSceneTreeExtensions {
  /// <summary>
  /// Enumerates all targets in the scene with the given target id. Note that this is an unfiltered collection
  /// of all nodes with a matching id.
  /// </summary>
  public static IEnumerable<Node> EnumerateTargetNodes(
    this SceneTree tree,
    TargetId targets
  ) => tree.GetNodesInGroup(targets.Group);

  /// <summary>
  /// Enumerates all targets with the given target id. This collection is filtered
  /// to only nodes with matching
  /// </summary>
  public static IEnumerable<T> EnumerateTargets<T>(
    this SceneTree tree,
    TargetId targets
  ) where T : IFuncTargetable
    => tree
      .EnumerateTargetNodes(targets)
      .OfType<T>();


  public static IEnumerable<Node> EnumerateTargetNodes(
    this IFuncTargeter activator,
    TargetId id
  ) => activator.IsInsideTree() && !id.IsEmpty
    ? activator
      .GetTree()
      .EnumerateTargetNodes(id)
      .Where(activator.CanTarget)
    : [];


  public static IEnumerable<T> EnumerateTargets<T>(
    this IFuncTargeter<T> activator,
    TargetId id
  ) => activator
    .EnumerateTargetNodes(id)
    .OfType<T>();

  /// <summary>
  /// Enumerate all nodes who have a target name matching this targeter's 'target' id. Note that 
  /// </summary>
  /// <param name="activator">Targeter</param>
  public static IEnumerable<Node> EnumerateTargetNodes(this IFuncTargeter activator)
    => activator.EnumerateTargetNodes(activator.GetTarget());

  public static IEnumerable<Node> EnumerateKillTargetNodes(this IFuncTargeter activator)
    => activator.EnumerateTargetNodes(activator.GetKillTarget());

  public static IEnumerable<T> EnumerateTargets<T>(this IFuncTargeter<T> activator)
    => activator.EnumerateTargets(activator.GetTarget());

  public static IEnumerable<T> EnumerateKillTargets<T>(this IFuncTargeter<T> activator)
    => activator
      .EnumerateTargets(activator.GetKillTarget());

  /// <summary>
  /// Invokes / uses all the nodes being targeted by this node.
  /// </summary>
  /// <param name="activator">The targeter / node to pull the 'target' property from.</param>
  /// <typeparam name="T">Type of the targeter</typeparam>
  public static void InvokeTargets<T>(this IFuncTargeter<T> activator) where T : IFuncTargetable {
    foreach (T target in activator.EnumerateTargets()) {
      target.Use(activator.AsNode);
    }
  }

  /// <summary>
  /// Invokes / uses all the nodes being targeted by this node.
  /// </summary>
  /// <param name="activator">The targeter / node to pull the 'target' property from.</param>
  public static void InvokeTargets(this IFuncTargeter activator) {
    foreach (Node node in activator.EnumerateTargetNodes()) {
      if (node is IFuncTargetable target) {
        target.Use(activator.AsNode);
      }
    }
  }

  public static void InvokeTargets(this IFuncTargeter activator, TargetId id) {
    foreach (Node node in activator.EnumerateTargetNodes(id)) {
      if (node is IFuncTargetable target) {
        target.Use(activator.AsNode);
      }
    }
  }
}
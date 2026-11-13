using Godot;

namespace project.addons.func_godot.csharp;

/// <summary>
/// Interface for FGD nodes meant to target other nodes for some functionality. This is a
/// default version that is allowed to target *any* node
/// </summary>
public interface IFuncTargeter : IFuncNodeLike {
  public bool CanTarget(object obj) => true;

  /// <summary>
  /// This interface as a node, meant to bypass C#'s lack of intersection types
  /// </summary>
  public Node AsNode => (Node)this;
}

/// <summary>
/// Interface for FGD nodes meant to target other nodes. This generic is used to filter what type of nodes this is able to target / invoke.
/// </summary>
public interface IFuncTargeter<out T> : IFuncTargeter {
  bool IFuncTargeter.CanTarget(object obj) =>
    obj is Node and (IFuncTargetable or IFuncTargetable<T>) ||
    obj.GetType().IsAssignableTo(typeof(IFuncTargetable<T>));
}
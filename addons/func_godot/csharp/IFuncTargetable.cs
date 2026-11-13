using Godot;

namespace project.addons.func_godot.csharp;

/// <summary>
/// Interface for nodes able to be targeted via FGD. Note that this property will only function
/// properly when being implemented on a Node, all uses of IFunCTargetable will assume that it is a node
/// </summary>
///
/// <example>
/// For example, if you set up a 'door' entity and set it up in trench broom with
/// a target name 'some_door', and you have a lever with target 'some_door', the Level C# script can do the following:
///
/// <code>
/// this.InvokeTargets();
/// </code>
///
/// and all the invoked targets
/// </example>
public interface IFuncTargetable<in T> : IFuncNodeLike {
  /// <summary>
  /// Called when this targetable is being activated
  /// </summary>
  /// <param name="activator"></param>
  public void Use(T activator);

  /// <summary>
  /// This interface as a node, meant to bypass C#'s lack of intersection types
  /// </summary>
  public Node AsNode => (Node)this;
}

/// <summary>
/// Interface for nodes able to be targeted / 'invoked' by other nodes.
/// </summary>
public interface IFuncTargetable : IFuncTargetable<Node> {
}
using Godot;
using project.addons.func_godot.csharp;
using project.addons.func_godot.csharp.reflection;

namespace project.addons.func_godot.fgd.test;

/// <summary>
/// This is a empty test class for showcasing FuncGodot features, this does nothing when instantiated.
/// </summary>
public partial class TestPointEntity : Marker3D, IFuncEntity, IFuncTargetable {
  public enum SomeEnum {
    Option1,
    Option2,
    Option3,
  }

  /// <summary>
  /// example property for an enum, will show up as a choices prompt in-editor
  /// </summary>
  [Export, FgdProperty]
  public SomeEnum EnumProperty { get; set; }

  [Export, FgdSpawnFlag(0)] public bool ExampleFlag1 { get; set; }
  [Export, FgdSpawnFlag(1)] public bool ExampleFlag2 { get; set; } = true;
  [Export, FgdSpawnFlag(2)] public bool ExampleFlag3 { get; set; }

  [Export, FgdFlag("CustomFlag", 0)] public bool ExampleCustomFlag1 { get; set; }

  [Export, FgdFlag("CustomFlag", 1)] public bool ExampleCustomFlag2 { get; set; }

  /// <summary>
  /// Resource file property, will show up as a path to input. Note that this path is relative to the root of the project, so you must omit "res://"
  ///
  /// Note that this has limited support right now and does not work for user-defined types unless they were registered via an Editor Plugin, and even
  /// that I have not verified.
  /// </summary>
  [Export, FgdProperty]
  PackedScene? ResourceProperty { get; set; }

  /// <summary>
  /// string property example
  /// </summary>
  [Export, FgdProperty]
  public string StringProperty { get; set; } = string.Empty;

  /// <summary>
  /// StringName property example
  /// </summary>
  [Export, FgdProperty]
  public StringName StringNameProperty { get; set; } = string.Empty;

  /// <summary>
  /// bool property example
  /// </summary>
  [Export, FgdProperty]
  public bool BoolProperty { get; set; }

  /// <summary>
  /// byte property example
  /// </summary>
  [Export, FgdProperty]
  public byte ByteProperty { get; set; }

  /// <summary>
  /// short property example
  /// </summary>
  [Export, FgdProperty]
  public short ShortProperty { get; set; }

  /// <summary>
  /// ushort property example
  /// </summary>
  [Export, FgdProperty]
  public ushort UshortProperty { get; set; }

  /// <summary>
  /// int property example
  /// </summary>
  [Export, FgdProperty]
  public int IntProperty { get; set; }

  /// <summary>
  /// uint property example
  /// </summary>
  [Export, FgdProperty]
  public uint UintProperty { get; set; }

  /// <summary>
  /// long property example
  /// </summary>
  [Export, FgdProperty]
  public long LongProperty { get; set; }

  /// <summary>
  /// ulong property example
  /// </summary>
  [Export, FgdProperty]
  public ulong UlongProperty { get; set; }

  /// <summary>
  /// float property example
  /// </summary>
  [Export, FgdProperty]
  public float FloatProperty { get; set; }

  /// <summary>
  /// double property example
  /// </summary>
  [Export, FgdProperty]
  public double DoubleProperty { get; set; }

  /// <summary>
  /// Color property example
  /// </summary>
  [Export, FgdProperty]
  public Color ColorProperty { get; set; }

  public override void _Ready() {
    GD.Print(this.GetTargetName());
  }

  public void Use(Node activator) {
    GD.Print(Name, " used by ", activator.Name);
  }
}
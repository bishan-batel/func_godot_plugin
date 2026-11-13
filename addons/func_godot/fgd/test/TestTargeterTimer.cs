using System.Collections.Generic;
using Godot;
using project.addons.func_godot.csharp;
using project.addons.func_godot.csharp.reflection;

namespace project.addons.func_godot.fgd.test;

[GlobalClass, Icon("res://addons/at-icons/node/sword.svg")]
public partial class TestTargeterTimer : Timer, IFuncTargeter, IFuncEntity {
  public IEnumerable<StringName> BuiltinGodotTypeFgdProperties => [
    Timer.PropertyName.WaitTime,
  ];

  public override void _Ready() {
    Timeout += () => {
      // invoke all the normal targets
      this.InvokeTargets();
      GD.Print("Target: ", CustomTarget.Name);
      this.InvokeTargets(CustomTarget);
    };
    Start();
  }

  [FgdSpawnFlag(0)]
  public new bool OneShot {
    get => base.OneShot;
    set => base.OneShot = value;
  }

  [FgdSpawnFlag(1)]
  public new bool Autostart {
    get => base.Autostart;
    set => base.Autostart = value;
  }

  public TestTargeterTimer() {
    Autostart = false;
  }

  [Export, FgdProperty] public TargetId CustomTarget { get; set; } = TargetId.Empty;
}
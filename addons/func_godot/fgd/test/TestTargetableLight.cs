using System.Collections.Generic;
using Godot;
using project.addons.func_godot.csharp;

namespace project.addons.func_godot.fgd.test;

public partial class TestTargetableLight : OmniLight3D, IFuncTargetable, IFuncEntity {
  public IEnumerable<StringName> BuiltinGodotTypeFgdProperties => [
    Light3D.PropertyName.LightColor,
    Light3D.PropertyName.LightEnergy,
    Light3D.PropertyName.LightSize,
    Light3D.PropertyName.ShadowEnabled,
  ];

  public void Use(Node activator) {
    LightEnergy = 50.0f;
  }

  public override void _Process(double delta) {
    LightEnergy = Mathf.Lerp(LightEnergy, 0.0f, (float)delta * 2.0f);
  }
}
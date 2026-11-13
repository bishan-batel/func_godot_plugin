// Copyright Digipen 2026
// Created 10/23/2026 by Kishan S Patel
// Team Gross Incandescence

using Godot;
using project.addons.func_godot.csharp;

namespace project.addons.func_godot.fgd.test;

public interface ITestMoveableTarget : IFuncTargetable<ITestMoveableTarget> {
  public enum Mode {
    Snap,
    Lerp
  }

  public Mode MoveableTargetLerpMode { get; }
}

public partial class TestMovementEntity : Node3D, IFuncTargeter<ITestMoveableTarget> {
  public override void _Ready() {
  }
}
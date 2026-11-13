// Copyright Digipen 2026
// Created 10/21/2026 by Kishan S Patel
// Team Gross Incandescence

using System;
using System.IO;
using System.Reflection;
using System.Xml;
using Godot;

namespace project.addons.func_godot.csharp.reflection;

/// <summary>
/// Static helper for resolving documentation comments for symbols within this assembly, GrossIncandescence.project
/// </summary>
public static class Documentation {
  /// <summary>
  /// Path to the emitted documentation file, right now its defaulted to fit the needs of Gross Incandescence.
  /// </summary>
  public static string DocumentationFilePath { get; set; } = "res://project.xml";

  /// <summary>
  /// Name of the XML summary tag
  /// </summary>
  const string SummaryTag = "summary";

  /// <summary>
  /// Name of the XML tag used for custom fgd descriptions
  /// </summary>
  const string CustomFgdTag = "fgd";


  /// <summary>
  /// Gets a suitable FGD summary for the given property, if there is no explicit
  /// XML tag in the doc comment matching <see cref="CustomFgdTag"/>, then this
  /// will fall back to using <see cref="SummaryTag"/>. This will return null
  /// if neither are present.
  /// </summary>
  public static string? GetFgdOrSummary(PropertyInfo info) =>
    GetDocTag(info, CustomFgdTag)
    ?? GetDocTag(info, SummaryTag);


  /// <summary>
  /// Gets a suitable FGD summary for the given type, if there is no explicit
  /// XML tag in the doc comment matching <see cref="CustomFgdTag"/>, then this
  /// will fall back to using <see cref="SummaryTag"/>. This will return null
  /// if neither are present.
  /// </summary>
  public static string? GetFgdOrSummary(TypeInfo info) =>
    GetDocTag(info, CustomFgdTag)
    ?? GetDocTag(info, SummaryTag);

  /// <summary>
  /// Gets the tag contents in the documentation for a
  /// given <see cref="PropertyInfo"/>, <paramref name="info"/>,
  /// </summary>
  public static string? GetDocTag(PropertyInfo info, string tag) =>
    info.DeclaringType is not null
      ? GetMemberDocTag($"P:{info.DeclaringType}.{info.Name}", tag)
      : null;

  /// <summary>
  /// Gets the tag contents in the documentation for a
  /// given <see cref="TypeInfo"/>, <paramref name="info"/>,
  /// </summary>
  public static string? GetDocTag(TypeInfo info, string tag) =>
    GetMemberDocTag($"T:{info.FullName}", tag);

  /// <summary>
  /// Gets <paramref name="tag"/> element contents in the documentation for the
  /// member symbol <paramref name="memberName"/>, note that this is using
  /// the DocumentationFile encoded name, see C# documentation for more details
  /// </summary>
  public static string? GetMemberDocTag(string memberName, string tag) {
    // TODO: [Kishan] this method should most definitely be using caching because
    // as it stands it loads the project XML documentation file for every look up,
    // which is not ideal but whatever computers are fast now lmao

    string xmlPath = ProjectSettings.GlobalizePath(DocumentationFilePath);

    if (!File.Exists(xmlPath)) return null;


    try {
      // Load the XML document
      var xmlDoc = new XmlDocument();
      xmlDoc.Load(xmlPath);

      // Find the specific member node
      XmlNode? selectSingleNode = xmlDoc.SelectSingleNode($"//member[@name='{memberName}']/{tag}");

      return selectSingleNode?.InnerText.Trim();
    }
    catch (Exception ex) {
      GD.PushError($"Error reading documentation: {ex.Message}");
      return null;
    }
  }
}
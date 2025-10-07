import 'dart:io';
import 'package:path/path.dart' as p;
import '../lib/src/flag.dart';

/// Cleans up unnecessary flag SVGs and regenerates `lib/src/flag.dart`.
///
/// Run:
/// ```bash
/// dart run tool/generate_flags.dart
/// ```
void main(List<String> arguments) {
  const hatscriptDirPath = 'assets/svg_hatscripts';
  const svgDirPath = 'assets/svg';
  const outputFilePath = 'lib/src/flag.dart';

  final hatscriptDir = Directory(hatscriptDirPath);
  final svgDir = Directory(svgDirPath);

  if (!hatscriptDir.existsSync()) {
    stderr.writeln('❌ Source directory "$hatscriptDirPath" not found.');
    exit(1);
  }

  svgDir.createSync(recursive: true);

  print('🧹 Removing unnecessary flags and copying valid ones...');

  // Step 1: Determine flags to keep based on phone_numbers_parser's ISO codes
  final flagsToKeep = {
    ...Flag.values.map((isoCode) => isoCode.toLowerCase()),
    'xx', // fallback "unknown" flag
  };

  // Step 2: Clear old target directory
  for (final file in svgDir.listSync()) {
    if (file is File && file.path.endsWith('.svg')) {
      file.deleteSync();
    }
  }

  // Step 3: Copy valid SVGs, resolving pseudo-links
  for (final isoCode in flagsToKeep) {
    try {
      final content = _findSvgContent(isoCode, hatscriptDirPath);
      final newFile = File(p.join(svgDirPath, '$isoCode.svg'));
      newFile.writeAsStringSync(content);
    } catch (e) {
      stderr.writeln('⚠️ Skipped $isoCode: $e');
    }
  }

  print('✅ SVG cleanup complete.');

  // Step 4: Generate Dart flag constants
  final svgFiles = svgDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (svgFiles.isEmpty) {
    stderr.writeln('⚠️ No SVG files found in $svgDirPath');
    exit(0);
  }

  print('🌀 Generating ${svgFiles.length} flag constants...');

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED FILE. DO NOT MODIFY BY HAND.');
  buffer.writeln('// Run `dart run tool/generate_flags.dart` to regenerate.\n');
  buffer.writeln('/// List of available flags (ISO codes) for [CircleFlag].');
  buffer.writeln('abstract class Flag {');

  // List of all values
  buffer.writeln('  static const values = <String>[');
  for (final svg in svgFiles) {
    final constName = p.basenameWithoutExtension(svg.path).toUpperCase();
    buffer.writeln('    $constName,');
  }
  buffer.writeln('  ];\n');

  // Constants
  for (final svg in svgFiles) {
    final baseName = p.basenameWithoutExtension(svg.path);
    final constName = baseName.toUpperCase();
    buffer.writeln("  static const String $constName = '$baseName';");
  }

  buffer.writeln('}');

  final outputFile = File(outputFilePath)
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());

  print('✅ Done! Generated ${outputFile.path}');
}

/// Reads an SVG file, following pseudo-links if needed.
String _findSvgContent(String isoCode, String hatscriptDirPath) {
  final file = File('$hatscriptDirPath/$isoCode.svg');
  if (!file.existsSync()) {
    throw 'file not found in hatscripts dir';
  }

  final content = file.readAsStringSync();
  if (content.trim().startsWith('<')) {
    return content;
  } else {
    // The file contains a reference (like "gb.svg")
    final linkedFile = File('$hatscriptDirPath/${content.trim()}');
    if (!linkedFile.existsSync()) {
      throw 'linked file ${linkedFile.path} not found';
    }
    return linkedFile.readAsStringSync();
  }
}

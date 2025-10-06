import 'dart:io';

import 'package:phone_numbers_parser/phone_numbers_parser.dart';

void main(List<String> arguments) {
  print('removing unnecessary flags');
  final flagsToKeep = [
    ...IsoCode.values.map((isoCode) => isoCode.name.toLowerCase()),
    // 'xx' is a "?" flag, useful for when a flag is not found
    'xx',
  ];
  for (final isoCode in flagsToKeep) {
    final content = findSvgContent(isoCode);
    final newFile = File('assets/svg/$isoCode.svg');
    newFile.writeAsStringSync(content);
  }
}

String findSvgContent(String isoCode) {
  final file = File('assets/svg_hatscripts/$isoCode.svg');
  // check if file is not a symbolic link else follow it.
  // the original repository puts the link name inside
  // the file content instead of a svg string when it's a link
  final fileContent = file.readAsStringSync();
  if (fileContent.startsWith('<')) {
    return fileContent;
  } else {
    final linkTo = File('assets/svg_hatscripts/$fileContent');
    if (!linkTo.existsSync()) {
      throw 'file ${linkTo.path} not found';
    }
    return linkTo.readAsStringSync();
  }
}

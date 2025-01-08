import 'dart:convert' show json;
import 'dart:io';
import 'package:archive/archive_io.dart' show ZipFileEncoder;
import 'package:path/path.dart' as path;
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval.dart' show Compiler;

Map<String, Map<String, String>>? loadPluginData(Directory dir) {
  final files = <String, String>{};

  // Now iterate over files and also replace the models import.
  for (final file in dir.listSync().whereType<File>()) {
    // We're not doing subdirectories or external packages.
    if (file.path.endsWith('.dart')) {
      String code = file.readAsStringSync();
      code = code.replaceFirst('../models.dart', 'package:plugin/_models.dart');
      final fileName = path.relative(file.path, from: dir.path);
      files[fileName] = code;
    }
  }

  // Finally compile.
  if (files.isEmpty) return null;
  return {'plugin': files};
}

void loadBindings(Compiler compiler) {
  const bindingFiles = ['flutter_eval.json', 'plugin_base.json'];
  for (final name in bindingFiles) {
    final file = File(name);
    if (!file.existsSync()) {
      throw FileSystemException('File $name is missing');
    }
    // Copied from dart_eval compiler.
    final data = file.readAsStringSync();
    final decoded = (json.decode(data) as Map).cast<String, dynamic>();
    final classList = (decoded['classes'] as List);
    for (final $class in classList.cast<Map>()) {
      compiler.defineBridgeClass(BridgeClassDef.fromJson($class.cast()));
    }
    for (final $enum in (decoded['enums'] as List).cast<Map>()) {
      compiler.defineBridgeEnum(BridgeEnumDef.fromJson($enum.cast()));
    }
    for (final $source in (decoded['sources'] as List).cast<Map>()) {
      compiler.addSource(DartSource($source['uri'], $source['source']));
    }
    for (final $function in (decoded['functions'] as List).cast<Map>()) {
      compiler.defineBridgeTopLevelFunction(
          BridgeFunctionDeclaration.fromJson($function.cast()));
    }
  }
}

void main() async {
  final compiler = Compiler();
  loadBindings(compiler);

  for (final dir in Directory(path.current).listSync().whereType<Directory>()) {
    final metadataFile = File(path.join(dir.path, 'metadata.json'));
    if (metadataFile.existsSync()) {
      // Found a plugin. Compile the code.
      final programData = loadPluginData(dir);
      if (programData == null) continue;
      final program = compiler.compile(programData);
      final programBytes = program.write();
      File(path.join(dir.path, 'plugin.evc')).writeAsBytesSync(programBytes);

      // Prepare an archive.
      final zipFile = File(path.join(path.current, '${dir.path}.zip'));
      await ZipFileEncoder().zipDirectory(dir, filename: zipFile.path);
    }
  }
}

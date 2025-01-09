import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:extension_test/bridges.dart';
import 'package:extension_test/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_eval/flutter_eval.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

class PluginContextImpl extends PluginContext {
  final Directory pluginDir;
  final Map<String, int> storage = {};

  PluginContextImpl(super.state, this.pluginDir);

  @override
  File getFile(String name) {
    return File('${pluginDir.path}/$name');
  }

  @override
  Future<int?> readPreference(String key) async {
    return storage[key];
  }

  @override
  Future<void> savePreference(String key, int value) async {
    storage[key] = value;
  }

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void repaint() {}
}

Future<PluginBase> installFromArchive(File file) async {
  throw UnsupportedError('Sorry, archives are not supported yet.');
  final tmpDir = await getTemporaryDirectory();
  // TODO: unzip
  return installFromDirectory(tmpDir);
  // TODO: clean up?
}

PluginBase installFromDirectory(Directory dir) {
  final evc = File('${dir.path}/plugin.evc');
  final data = evc.readAsBytesSync();
  final runtime = Runtime(ByteData.sublistView(data));
  runtime.addPlugin(FlutterEvalPlugin());
  runtime.addPlugin(PluginBasePlugin());
  runtime.grant(FilesystemPermission.directory(dir.path));
  final context = PluginContextImpl(AppState(), dir);
  return runtime.executeLib(
      'package:plugin/main.dart', 'setup', [$PluginContext.wrap(context)]);
}

void log(String msg) {
  print(msg);
}

void main() async {
  const path = String.fromEnvironment('PLUGIN');
  if (path.isEmpty) {
    log('Usage: flutter test test_plugin.dart --dart-define PLUGIN=<plugin file or dir>');
    return;
  }

  final fileType = FileSystemEntity.typeSync(path);
  PluginBase plugin;
  switch (fileType) {
    case FileSystemEntityType.file:
      plugin = await installFromArchive(File(path));
    case FileSystemEntityType.directory:
      plugin = installFromDirectory(Directory(path));
    default:
      log("Cannot read entity '$path'.");
      return;
  }

  log('Plugin installed from "$path"');
  final state = plugin.context.state;
  if (state.counter == 0) state.counter = plugin.initial;
  state.step = plugin.step;
  await plugin.init();

  test('fields', () {
    log(' initial = ${plugin.initial}');
    log(' step = ${plugin.step}');
    log(' buttons = ${plugin.buttons}');
  });

  test('functions', () {
    log(' state: $state');
    state.counter += plugin.step;
    log(' after increment: $state');

    for (final button in plugin.buttons) {
      plugin.onButtonTapped(button, state);
      log(' after pressing "$button": $state');
    }
  });

  testWidgets('widgets', (tester) async {
    await tester.pumpWidget(Builder(
      builder: (context) {
        log(' numberWidget is ${plugin.numberWidget(context, state)}');
        log(' settingsWidget is ${plugin.settingsWidget(context)}');
        return Placeholder();
      },
    ));
  });
}

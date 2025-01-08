import 'dart:convert' show json;
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:extension_test/bridges.dart';
import 'package:extension_test/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_eval/flutter_eval.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plugin description. Basically an id, a name, and some extra things.
class Plugin {
  final String id;
  final String name;

  Plugin(this.id, [String? name]) : name = name ?? id;
}

/// Thrown only when loading a plugin. Prints the enclosed exception as well.
class PluginLoadException implements Exception {
  final String message;
  final Exception? parent;

  PluginLoadException(this.message, [this.parent]);

  @override
  String toString() {
    return parent == null ? message : "$message: $parent";
  }
}

class PluginContextImpl extends PluginContext with ChangeNotifier {
  final Directory pluginDir;

  PluginContextImpl(super.state, this.pluginDir);

  @override
  File getFile(String name) {
    return File('${pluginDir.path}/$name');
  }

  @override
  Future<int?> readPreference(String key) async {
    final prefs = SharedPreferencesAsync();
    return await prefs.getInt('plugin/$key');
  }

  @override
  Future<void> savePreference(String key, int value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setInt('plugin/$key', value);
  }

  @override
  void repaint() {
    notifyListeners();
  }
}

/// The main class for working with plugins. A singleton, use [instance].
class PluginProvider extends ChangeNotifier {
  static const _kEnabledKey = 'plugins_enabled';
  static final instance = PluginProvider._();
  final _plugins = <Plugin>[];
  final _pluginCode = <String, PluginBase>{};
  final _enabled = <String>{};
  late final Directory _pluginsDirectory;
  bool _ready = false;

  /// App state is initialized here, but usually is supplied from outside
  /// with [setState].
  AppState state = AppState();

  PluginProvider._() {
    state.addListener(notifyCounterChanged);
    _load();
  }

  Future<bool> get ready async {
    while (!_ready) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    return true;
  }

  int get count => _plugins.length;
  List<Plugin> get all => _plugins;
  Iterable<Plugin> get active => _plugins.where((p) => _enabled.contains(p.id));
  bool isActive(String id) => _enabled.contains(id);

  Future<void> _load() async {
    final docDir = await getApplicationDocumentsDirectory();
    _pluginsDirectory = Directory("${docDir.path}/plugins");

    // Create plugins dir if not exists.
    await _pluginsDirectory.create(recursive: true);

    // Read plugins list.
    await for (final entry in _pluginsDirectory.list()) {
      if (entry is Directory) {
        final metadata = await _readPluginData(entry);
        if (metadata != null) _plugins.add(metadata);
      }
    }

    // Read enabled list.
    final prefs = SharedPreferencesAsync();
    final enabledList = await prefs.getStringList(_kEnabledKey);
    _enabled.clear();
    if (enabledList != null) _enabled.addAll(enabledList);

    // Enable plugins.
    for (final id in _enabled) {
      _enable(id);
    }

    _ready = true;

    try {
      await _installFromAssets();
    } on PluginLoadException catch (e) {
      print('Failed to install plugin from assets: $e');
    }
  }

  Future<void> _saveEnabled() async {
    final prefs = SharedPreferencesAsync();
    final enabledList = _enabled.toList();
    enabledList.sort();
    await prefs.setStringList(_kEnabledKey, enabledList);
  }

  void _enable(String id) {
    if (_enabled.contains(id)) return;
    final p = _loadCode(id);
    _pluginCode[id] = p;
    if (state.counter == 0) state.counter = p.initial;
    state.step = p.step;
    p.context.addListener(_onRepaint);
    p.init();
    _enabled.add(id);
    _onRepaint();
  }

  PluginBase _loadCode(String pluginId) {
    final dir = _getPluginDirectory(pluginId);
    final evc = File('${dir.path}/plugin.evc');
    final data = evc.readAsBytesSync();
    final runtime = Runtime(ByteData.sublistView(data));
    runtime.addPlugin(FlutterEvalPlugin());
    runtime.addPlugin(PluginBasePlugin());
    final context = PluginContextImpl(state, dir);
    return runtime.executeLib(
        'package:plugin/main.dart', 'setup', [$PluginContext.wrap(context)]);
  }

  void _disable(String id) {
    if (!_enabled.contains(id)) return;
    _enabled.remove(id);
    final p = _pluginCode[id];
    if (p != null) {
      p.context.removeListener(_onRepaint);
      _pluginCode.remove(id);
    }
    _onRepaint();
  }

  void _onRepaint() {
    notifyListeners();
  }

  void onIncrementTap() {
    int increment = 1;
    for (final p in _plugins) {
      if (isActive(p.id) && _pluginCode.containsKey(p.id)) {
        final int step = _pluginCode[p.id]!.step;
        if (step > increment) increment = step;
      }
    }
    state.counter += increment;
  }

  List<String> getButtons() {
    final result = <String>[];
    for (final p in _plugins) {
      if (isActive(p.id) && _pluginCode.containsKey(p.id)) {
        final code = _pluginCode[p.id]!;
        result.addAll(code.buttons);
      }
    }
    return result;
  }

  void onButtonTap(String button) {
    for (final p in _plugins) {
      if (isActive(p.id) && _pluginCode.containsKey(p.id)) {
        final code = _pluginCode[p.id]!;
        if (code.buttons.contains(button)) {
          _pluginCode[p.id]!.onButtonTapped(button, state);
        }
      }
    }
  }

  void notifyCounterChanged() {
    for (final p in _plugins) {
      if (isActive(p.id) && _pluginCode.containsKey(p.id)) {
        _pluginCode[p.id]!.onCounterChanged(state);
      }
    }
  }

  Widget? buildNumberWidget(BuildContext context) {
    for (final p in _plugins) {
      if (isActive(p.id) && _pluginCode.containsKey(p.id)) {
        final widget = _pluginCode[p.id]!.numberWidget(context, state);
        if (widget != null) return widget;
      }
    }
    return null;
  }

  Widget? buildSettingsWidget(BuildContext context, String pluginId) {
    if (isActive(pluginId) && _pluginCode.containsKey(pluginId)) {
      return _pluginCode[pluginId]!.settingsWidget(context);
    }
    return null;
  }

  Future<void> setStateAndSave(String id, bool active) async {
    if (isActive(id)) {
      _disable(id);
    } else {
      _enable(id);
    }
    await _saveEnabled();
  }

  Future<void> toggle(String id) async {
    await setStateAndSave(id, !isActive(id));
  }

  Future<void> deletePlugin(String id) async {
    if (isActive(id)) await setStateAndSave(id, false);
    _plugins.removeWhere((p) => p.id == id);
    final pluginDir = _getPluginDirectory(id);
    if (await pluginDir.exists()) {
      await pluginDir.delete(recursive: true);
    }
  }

  Future<void> _installFromAssets() async {
    ByteData pluginFile;
    try {
      pluginFile = await rootBundle.load('assets/plugin.zip');
    } on Exception {
      return;
    }
    final tmpDir = await getTemporaryDirectory();
    final File tmpPath = File('${tmpDir.path}/bundled_plugin.zip');
    await tmpPath.writeAsBytes(pluginFile.buffer.asUint8List(), flush: true);
    try {
      await install(tmpPath.path);
    } finally {
      try {
        await tmpPath.delete();
      } on Exception {
        // it's fine if we leave it.
      }
    }
  }

  Directory _getPluginDirectory(String id) {
    return Directory("${_pluginsDirectory.path}/$id");
  }

  Future<Plugin?> _readPluginData(Directory path) async {
    // Read the metadata.
    final metadataFile = File("${path.path}/metadata.json");
    if (!await metadataFile.exists()) {
      return null;
    }

    // Parse the metadata.json file.
    final metadataContents = await metadataFile.readAsString();
    final Map<String, dynamic> metadata = json.decode(metadataContents);

    return Plugin(metadata['id'], metadata['name']);
  }

  Future<void> install(String path) async {
    // Prepare paths.
    final file = File(path);
    if (!await file.exists()) {
      throw PluginLoadException("File is missing: $path");
    }

    // Unpack the file.
    final tmpDir = await getTemporaryDirectory();
    final tmpPluginDir = await tmpDir.createTemp("plugin");
    try {
      try {
        await ZipFile.extractToDirectory(
          zipFile: file,
          destinationDir: tmpPluginDir,
        );
      } on PlatformException catch (e) {
        throw PluginLoadException("Failed to unpack $path", e);
      }

      // Delete the temporary file if possible.
      if (await file.exists()) {
        try {
          await file.delete();
        } on FileSystemException {
          // Does not matter.
        }
      }

      // Read the metadata.
      final metadataFile = File("${tmpPluginDir.path}/metadata.json");
      if (!await metadataFile.exists()) {
        throw PluginLoadException("No ${metadataFile.path} found");
      }

      // Parse the metadata.yaml file.
      final metadataContents = await metadataFile.readAsString();
      final Map<String, dynamic> metadata = json.decode(metadataContents);

      // Check for required fields.
      const requiredFields = ['id', 'name'];
      final missingFields =
          requiredFields.where((f) => !metadata.containsKey(f));
      if (missingFields.isNotEmpty) {
        throw PluginLoadException(
            "Missing fields in metadata: ${missingFields.join(',')}");
      }

      // Extract and validate plugin id.
      final String pluginId = metadata['id']!;
      if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(pluginId)) {
        throw PluginLoadException(
            "Plugin id \"$pluginId\" has bad characters.");
      }

      // If this plugin was installed, remove it.
      bool wasActive = isActive(pluginId);
      await deletePlugin(pluginId);

      // Create the plugin directory and move files there.
      final pluginDir = _getPluginDirectory(pluginId);
      await tmpPluginDir.rename(pluginDir.path);

      // Add the plugin record to the list.
      final record = Plugin(pluginId, metadata['name']);
      _plugins.add(record);

      if (wasActive) {
        await setStateAndSave(pluginId, true);
      }
    } finally {
      // delete the directory and exit
      try {
        await tmpPluginDir.delete(recursive: true);
      } on Exception {
        // Oh well, let the trash rest there.
      }
    }
  }
}

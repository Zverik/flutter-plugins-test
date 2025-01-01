import 'dart:io';
import 'package:extension_test/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

/// from https://stackoverflow.com/a/67885082/1297601
/// because yaml module returns a weird map.
extension YamlMapConverter on YamlMap {
  dynamic _convertNode(dynamic v) {
    if (v is YamlMap) {
      return v.toMap();
    } else if (v is YamlList) {
      var list = <dynamic>[];
      for (final e in v) {
        list.add(_convertNode(e));
      }
      return list;
    } else {
      return v;
    }
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    nodes.forEach((k, v) {
      map[(k as YamlScalar).value.toString()] = _convertNode(v.value);
    });
    return map;
  }
}

/// Plugin description. Basically an id, a name, and some extra things.
class Plugin {
  final String id;
  final String name;
  final Map<String, dynamic> metadata;

  Plugin(this.id, {required this.name, required this.metadata});
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

/// The main class for working with plugins. A singleton, use [instance].
class PluginProvider {
  static const _kEnabledKey = 'plugins_enabled';
  static final instance = PluginProvider._();
  final _plugins = <Plugin>[];
  final _enabled = <String>{};
  bool _ready = false;

  /// App state is initialized here, but usually is supplied from outside
  /// with [setState].
  AppState state = AppState();

  PluginProvider._() {
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
    // Create plugins dir if not exists.
    final pluginsDir = await _getPluginsDirectory();
    await pluginsDir.create(recursive: true);

    // Read plugins list.
    await for (final entry in pluginsDir.list()) {
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
      await _enable(id);
    }

    _rebuildState();
    _ready = true;
  }

  Future<void> _saveEnabled() async {
    final prefs = SharedPreferencesAsync();
    final enabledList = _enabled.toList();
    enabledList.sort();
    await prefs.setStringList(_kEnabledKey, enabledList);
  }

  Future<void> _enable(String id) async {
    if (_enabled.contains(id)) return;
    _enabled.add(id);
  }

  Future<void> _disable(String id) async {
    if (!_enabled.contains(id)) return;
    _enabled.remove(id);
  }

  void setState(AppState newState) {
    state = newState;
    _rebuildState();
    state.reset();
  }

  void _rebuildState() {
    for (final p in _plugins) {
      if (isActive(p.id)) {
        if (p.metadata.containsKey('initial')) {
          state.initial = p.metadata['initial'] as int;
        }
        if (p.metadata.containsKey('increment')) {
          state.step = p.metadata['increment'] as int;
        }
      }
    }
  }

  Future<void> setStateAndSave(String id, bool active) async {
    if (isActive(id)) {
      await _disable(id);
    } else {
      await _enable(id);
    }
    _rebuildState();
    await _saveEnabled();
  }

  Future<void> toggle(String id) async {
    await setStateAndSave(id, !isActive(id));
  }

  Future<void> deletePlugin(String id) async {
    if (isActive(id)) await setStateAndSave(id, false);
    _plugins.removeWhere((p) => p.id == id);
    final pluginDir = await _getPluginDirectory(id);
    if (await pluginDir.exists()) {
      await pluginDir.delete(recursive: true);
    }
  }

  Future<Directory> _getPluginsDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    return Directory("${docDir.path}/plugins");
  }

  Future<Directory> _getPluginDirectory(String id) async {
    final docDir = await _getPluginsDirectory();
    return Directory("${docDir.path}/id");
  }

  Future<Plugin?> _readPluginData(Directory path) async {
    // Read the metadata.
    final metadataFile = File("${path.path}/metadata.yaml");
    if (!await metadataFile.exists()) {
      return null;
    }

    // Parse the metadata.yaml file.
    Map<String, dynamic> metadata;
    try {
      final metadataContents = await metadataFile.readAsString();
      final YamlMap yamlData = loadYaml(metadataContents);
      metadata = yamlData.toMap();
    } on Exception {
      return null;
    }

    final String pluginId = metadata['id']!;
    final record = Plugin(
      pluginId,
      name: metadata['name'],
      metadata: metadata,
    );
    return record;
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
      final metadataFile = File("${tmpPluginDir.path}/metadata.yaml");
      if (!await metadataFile.exists()) {
        throw PluginLoadException("No ${metadataFile.path} found");
      }

      // Parse the metadata.yaml file.
      Map<String, dynamic> metadata;
      try {
        final metadataContents = await metadataFile.readAsString();
        final YamlMap yamlData = loadYaml(metadataContents);
        metadata = yamlData.toMap();
      } on Exception catch (e) {
        throw PluginLoadException("Failed to read the metadata file", e);
      }

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
      final pluginDir = await _getPluginDirectory(pluginId);
      await tmpPluginDir.rename(pluginDir.path);

      // Add the plugin record to the list.
      final record = Plugin(
        pluginId,
        name: metadata['name'],
        metadata: metadata,
      );
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

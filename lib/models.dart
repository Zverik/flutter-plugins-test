import 'dart:io';

import 'package:flutter/material.dart';

/// This class has all the values for the state.
/// The main one is [counter], which replaces the old
/// state variable from the demo app.
class AppState extends ChangeNotifier {
  int initial = 0;
  int step = 1;
  int _counter = 0;

  int get counter => _counter;

  set counter(int value) {
    _counter = value;
    notifyListeners();
  }

  @override
  String toString() => 'AppState($_counter, ($initial, $step))';
}

abstract class PluginContext implements Listenable {
  final AppState state;
  PluginContext(this.state);

  Future<int?> readPreference(String key);
  Future<void> savePreference(String key, int value);
  void repaint();
  File getFile(String name);
}

class PluginBase {
  int initial;
  int step;
  final PluginContext context;
  List<String> buttons = [];

  PluginBase(this.context, {this.initial = 0, this.step = 1});

  dynamic init() {}

  void onButtonTapped(String button, AppState state) {}

  void onCounterChanged(AppState state) {}

  Widget? numberWidget(BuildContext context, AppState state) {
    return null;
  }

  Widget? settingsWidget(BuildContext context) {
    return null;
  }
}

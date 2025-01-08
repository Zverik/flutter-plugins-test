import '../models.dart';
import 'package:flutter/material.dart';

class WidgetPlugin extends PluginBase {
  bool needSave = true;

  WidgetPlugin(PluginContext context) : super(context);

  @override
  Future<void> init() async {
    final needSaveInt = await context.readPreference('widget-save');
    needSave = needSaveInt == 1;
    context.repaint();
  }

  @override
  Widget? numberWidget(BuildContext context, AppState state) {
    return Text(
      state.counter.toString(),
      style: TextStyle(
        color: Colors.red,
        fontSize: 300,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget? settingsWidget(BuildContext context) {
    return null; // TODO
  }
}

PluginBase setup(PluginContext context) => WidgetPlugin(context);

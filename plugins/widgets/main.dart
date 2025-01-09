import '../models.dart';
import 'package:flutter/material.dart';

class WidgetPlugin extends PluginBase {
  bool needSave = true;
  bool readValue = false;

  WidgetPlugin(PluginContext context) : super(context);

  @override
  Future<void> init() async {
    final needSaveInt = await context.readPreference('widget-save');
    needSave = needSaveInt == 1;
    if (needSave) {
      final int? value = await context.readPreference('widget-counter');
      if (value != null) context.state.counter = value;
    }
    readValue = true;
  }

  @override
  void onCounterChanged(AppState state) {
    if (needSave && readValue) {
      context.savePreference('widget-counter', state.counter);
    }
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
    return Column(
      children: [
        SwitchListTile(
          title: Text('Persist counter'),
          value: needSave,
          onChanged: (value) {
            needSave = value;
            this.context.savePreference('widget-save', needSave ? 1 : 0);
            if (needSave) {
              onCounterChanged(this.context.state);
            }
            this.context.repaint();
          },
        ),
      ],
    );
  }
}

PluginBase setup(PluginContext context) => WidgetPlugin(context);

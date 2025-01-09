import '../models.dart';
import 'dart:math';

class FunctionPlugin extends PluginBase {
  final String _kMinusButton = '-1';
  final String _kResetButton = 'X';
  final Random _random = Random();

  FunctionPlugin(PluginContext context) : super(context) {
    // buttons.add(_kMinusButton);
  }

  @override
  List<String> get buttons => [_kResetButton, _kMinusButton];

  @override
  int get step => _random.nextInt(5);

  @override
  void onButtonTapped(String button, AppState state) {
    if (button == _kMinusButton) {
      state.counter -= 1;
    } else if (button == _kResetButton) {
      state.counter = state.initial;
    }
  }
}

PluginBase setup(PluginContext context) => FunctionPlugin(context);

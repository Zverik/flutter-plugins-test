import '../models.dart';
import 'dart:math';

class FunctionPlugin extends PluginBase {
  final String _kMinusButton = '-1';
  final Random _random = Random();

  FunctionPlugin(PluginContext context) : super(context) {
    // buttons.add(_kMinusButton);
  }

  @override
  List<String> get buttons => [_kMinusButton];

  @override
  int get step => _random.nextInt(5);

  @override
  void onButtonTapped(String button, AppState state) {
    if (button == _kMinusButton) {
      state.counter -= 1;
    }
  }
}

PluginBase setup(PluginContext context) => FunctionPlugin(context);

import 'package:extension_test/models.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/io.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_eval/widgets.dart';

const pluginBasePlugin = PluginBasePlugin();
const _kModelsPath = 'package:plugin/_models.dart';

class PluginBasePlugin implements EvalPlugin {
  const PluginBasePlugin();

  @override
  String get identifier => _kModelsPath.substring(0, _kModelsPath.indexOf('/'));

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($AppState.$declaration);
    registry.defineBridgeClass($PluginContext.$declaration);
    registry.defineBridgeClass($PluginBase$bridge.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
      _kModelsPath,
      'PluginBase.',
      $PluginBase$bridge.$new,
      isBridge: true,
    );
  }
}

class $AppState implements $Instance {
  static const $type = BridgeTypeRef(BridgeTypeSpec(_kModelsPath, 'AppState'));

  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {},
    methods: {
      'increment': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
    },
    getters: {
      'counter': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      )),
    },
    setters: {
      'counter': BridgeMethodDef(BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
          ])),
    },
    fields: {
      'initial':
          BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
      'step':
          BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
    },
    wrap: true,
  );

  @override
  final AppState $value;

  @override
  get $reified => $value;

  $AppState.wrap(this.$value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'initial':
        return $int($value.initial);
      case 'step':
        return $int($value.step);
      case 'counter':
        return $int($value.counter);
    }
    return $Object(this).$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'initial':
        $value.initial = value.$value as int;
      case 'step':
        $value.step = value.$value as int;
      case 'counter':
        $value.counter = value.$value as int;
      default:
        $Object(this).$setProperty(runtime, identifier, value);
    }
  }
}

class $PluginContext implements $Instance {
  static const $type =
      BridgeTypeRef(BridgeTypeSpec(_kModelsPath, 'PluginContext'));

  // We cannot import the library directly.
  static const $Listenable$type = BridgeTypeRef(BridgeTypeSpec(
      'package:flutter/src/foundation/change_notifier.dart', 'Listenable'));

  static const $declaration = BridgeClassDef(
    BridgeClassType($type, $implements: [$Listenable$type], isAbstract: true),
    constructors: {},
    fields: {
      'state': BridgeFieldDef(BridgeTypeAnnotation($AppState.$type)),
    },
    methods: {
      'readPreference': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(
            // TODO: returns Future<int?>
            BridgeTypeRef(
                CoreTypes.future, [BridgeTypeRef(CoreTypes.dynamic)])),
        params: [
          BridgeParameter('key',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
        ],
      )),
      'savePreference': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(
            CoreTypes.future, [BridgeTypeRef(CoreTypes.voidType)])),
        params: [
          BridgeParameter('key',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
          BridgeParameter('value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
        ],
      )),
      'repaint': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
      'getFile': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.file)),
        params: [
          BridgeParameter('name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false),
        ],
      )),
    },
    wrap: true,
  );

  @override
  final PluginContext $value;

  @override
  get $reified => $value;

  $PluginContext.wrap(this.$value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'state':
        return $AppState.wrap($value.state);
      case 'readPreference':
        return $Function(_readPreference);
      case 'savePreference':
        return $Function(_savePreference);
      case 'repaint':
        return $Function(_repaint);
      case 'getFile':
        return $Function(_getFile);
    }
    return $Object(this).$getProperty(runtime, identifier);
  }

  static $Value? _readPreference(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final ctx = target!.$value as PluginContext;
    final key = args[0]!.$value as String;
    return $Future.wrap(ctx
        .readPreference(key)
        .then((value) => value == null ? $null() : $int(value)));
  }

  static $Value? _savePreference(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final ctx = target!.$value as PluginContext;
    final key = args[0]!.$value as String;
    final value = args[1]!.$value as int;
    return $Future.wrap(ctx.savePreference(key, value));
  }

  static $Value? _repaint(Runtime runtime, $Value? target, List<$Value?> args) {
    final ctx = target!.$value as PluginContext;
    ctx.repaint();
    return null;
  }

  static $Value? _getFile(Runtime runtime, $Value? target, List<$Value?> args) {
    final ctx = target!.$value as PluginContext;
    final name = args[0]!.$value as String;
    return $File.wrap(ctx.getFile(name));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    $Object(this).$setProperty(runtime, identifier, value);
  }
}

class $PluginBase$bridge extends PluginBase with $Bridge<PluginBase> {
  static const $type =
      BridgeTypeRef(BridgeTypeSpec(_kModelsPath, 'PluginBase'));

  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($type),
        params: [
          BridgeParameter(
              'context', BridgeTypeAnnotation($PluginContext.$type), false),
        ],
        namedParams: [
          BridgeParameter('initial',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true),
          BridgeParameter(
              'step', BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true),
        ],
      )),
    },
    methods: {
      'init': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
      )),
      'onButtonTapped': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        params: [
          BridgeParameter(
              'button', BridgeTypeAnnotation($IconData.$type), false),
          BridgeParameter(
              'state', BridgeTypeAnnotation($AppState.$type), false),
        ],
      )),
      'onCounterChanged': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        params: [
          BridgeParameter(
              'state', BridgeTypeAnnotation($AppState.$type), false),
        ],
      )),
      'numberWidget': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($Widget.$type, nullable: true),
        params: [
          BridgeParameter(
              'context', BridgeTypeAnnotation($BuildContext.$type), false),
          BridgeParameter(
              'state', BridgeTypeAnnotation($AppState.$type), false),
        ],
      )),
      'settingsWidget': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($Widget.$type, nullable: true),
        params: [
          BridgeParameter(
              'context', BridgeTypeAnnotation($BuildContext.$type), false),
        ],
      )),
    },
    fields: {
      'initial':
          BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
      'step':
          BridgeFieldDef(BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
      'context': BridgeFieldDef(BridgeTypeAnnotation($PluginContext.$type)),
      'buttons': BridgeFieldDef(BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [$IconData.$type]))),
    },
    bridge: true,
  );

  $PluginBase$bridge(super.context, {super.initial, super.step});

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    final context = args[0]! as $PluginContext;
    final int initial = args[1]?.$value ?? 0;
    final int step = args[2]?.$value ?? 1;
    return $PluginBase$bridge(context.$value, initial: initial, step: step);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'initial':
        return $int(super.initial);
      case 'step':
        return $int(super.step);
      case 'context':
        return $PluginContext.wrap(super.context);
      case 'buttons':
        return $List<$String>.wrap(
            super.buttons.map((d) => $String(d)).toList());
      case 'init':
        return $Function((runtime, target, args) {
          super.init();
          return null;
        });
      case 'onButtonTapped':
        return $Function((runtime, target, args) {
          final button = (args[1] as $String).$value;
          final state = (args[2] as $AppState).$value;
          super.onButtonTapped(button, state);
          return null;
        });
      case 'onCounterChanged':
        return $Function((runtime, target, args) {
          final state = (args[1] as $AppState).$value;
          super.onCounterChanged(state);
          return null;
        });
      case 'numberWidget':
        return $Function((runtime, target, args) {
          final context = (args[1] as $BuildContext).$value;
          final state = (args[2] as $AppState).$value;
          final widget = super.numberWidget(context, state);
          return widget == null ? $null() : $Widget.wrap(widget);
        });
      case 'settingsWidget':
        return $Function((runtime, target, args) {
          final context = (args[1] as $BuildContext).$value;
          final widget = super.settingsWidget(context);
          return widget == null ? $null() : $Widget.wrap(widget);
        });
    }
    throw UnimplementedError('Property does not exist: "$identifier"');
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
    switch (identifier) {
      case 'initial':
        super.initial = value.$value;
      case 'step':
        super.step = value.$value;
      case 'buttons':
        final src = value as $List<$String>;
        super.buttons = List<String>.of(src.$value.map((d) => d.$value));
      default:
        throw UnimplementedError('Cannot set property: "$identifier"');
    }
  }

  @override
  init() {
    $_invoke('init', []);
  }

  @override
  void onButtonTapped(String button, AppState state) {
    $_invoke('onButtonTapped', [
      $String(button),
      $AppState.wrap(state),
    ]);
  }

  @override
  void onCounterChanged(AppState state) {
    $_invoke('onCounterChanged', [$AppState.wrap(state)]);
  }

  @override
  Widget? numberWidget(BuildContext context, AppState state) {
    return $_invoke('numberWidget', [
      $BuildContext.wrap(context),
      $AppState.wrap(state),
    ]);
  }

  @override
  Widget? settingsWidget(BuildContext context) {
    return $_invoke('settingsWidget', [
      $BuildContext.wrap(context),
    ]);
  }

  @override
  int get initial => $_get('initial');

  @override
  int get step => $_get('step');

  @override
  List<String> get buttons =>
      ($_get('buttons') as List).whereType<String>().toList();

  @override
  PluginContext get context => $_get('context');
}

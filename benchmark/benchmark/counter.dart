import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

const kPackageName = 'test';
const _kModuleName = 'package:$kPackageName/counter.dart';

class Counter {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count += 1;
  }

  void reset() {
    _count = 0;
  }
}

class Incrementer {
  final Counter counter;

  Incrementer(this.counter);

  void doJobOriginal() {
    counter.increment();
  }

  void doJobSuper() {
    counter.increment();
  }

  void doJobOverride() {}
}

class CounterPlugin implements EvalPlugin {
  const CounterPlugin();

  @override
  String get identifier => _kModuleName.substring(0, _kModuleName.indexOf('/'));

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($Counter.$declaration);
    registry.defineBridgeClass($Incrementer$bridge.$declaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
      _kModuleName,
      'Incrementer.',
      $Incrementer$bridge.$new,
      isBridge: true,
    );
  }
}

class $Counter implements $Instance {
  static const $type = BridgeTypeRef(BridgeTypeSpec(_kModuleName, 'Counter'));

  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {},
    methods: {
      'increment': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
      'reset': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
    },
    getters: {
      'count': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
      )),
    },
    wrap: true,
  );

  @override
  final Counter $value;

  @override
  get $reified => $value;

  $Counter.wrap(this.$value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'increment':
        return $Function(_increment);
      case 'reset':
        return $Function(_reset);
      case 'count':
        return $int($value.count);
    }
    return $Object(this).$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    $Object(this).$setProperty(runtime, identifier, value);
  }

  static $Value? _increment(Runtime runtime, $Value? target, List<$Value?> args) {
    final ctx = target!.$value as Counter;
    ctx.increment();
    return null;
  }

  static $Value? _reset(Runtime runtime, $Value? target, List<$Value?> args) {
    final ctx = target!.$value as Counter;
    ctx.reset();
    return null;
  }
}

class $Incrementer$bridge  extends Incrementer with $Bridge<Incrementer> {
  static const $type = BridgeTypeRef(BridgeTypeSpec(_kModuleName, 'Incrementer'));

  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation($type),
        params: [
          BridgeParameter(
              'counter', BridgeTypeAnnotation($Counter.$type), false),
        ],
      )),
    },
    methods: {
      'doJobOriginal': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
      'doJobSuper': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
      'doJobOverride': BridgeMethodDef(BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
      )),
    },
    fields: {
      'counter': BridgeFieldDef(BridgeTypeAnnotation($Counter.$type)),
    },
    bridge: true,
  );

  $Incrementer$bridge(super.counter);

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    final counter = args[0]! as $Counter;
    return $Incrementer$bridge(counter.$value);
  }

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'counter':
        return $Counter.wrap(super.counter);
      case 'doJobOriginal':
        return $Function((runtime, target, args) {
          super.doJobOriginal();
          return null;
        });
      case 'doJobSuper':
        return $Function((runtime, target, args) {
          super.doJobSuper();
          return null;
        });
      case 'doJobOverride':
        return $Function((runtime, target, args) {
          super.doJobOverride();
          return null;
        });
    }
    throw UnimplementedError('Property does not exist: "$identifier"');
  }

  @override
  void $bridgeSet(String identifier, $Value value) {
      throw UnimplementedError('Cannot set property: "$identifier"');
  }

  @override
  doJobOriginal() {
    $_invoke('doJobOriginal', []);
  }

  @override
  doJobSuper() {
    $_invoke('doJobSuper', []);
  }

  @override
  doJobOverride() {
    $_invoke('doJobOverride', []);
  }
}

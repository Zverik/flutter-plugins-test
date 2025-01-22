import 'package:dart_eval/dart_eval.dart';
import 'package:benchmark/benchmark.dart';
import 'counter.dart';

class IncrementerSub extends Incrementer {
  IncrementerSub(super.c);

  @override
  doJobOverride() {
    counter.increment();
  }
}

void main() {
  final code = '''
      import 'package:test/counter.dart';

      void increment(Counter c) {
        c.increment();
      }

      class IncrementerSub extends Incrementer {
        IncrementerSub(Counter c): super(c);

        @override
        doJobSuper() {
          super.doJobSuper();
        }

        @override
        doJobOverride() {
          counter.increment();
        }
      }

      Incrementer construct(Counter c) => IncrementerSub(c);
''';
  final compiler = Compiler();
  compiler.addPlugin(CounterPlugin());
  final program = compiler.compile({
    kPackageName: {'main.dart': code},
  });
  final runtime = Runtime.ofProgram(program);
  runtime.addPlugin(CounterPlugin());

  const kIterations = 100000;
  final counter = Counter();
  final incrementer = runtime.executeLib(
    'package:$kPackageName/main.dart', 'construct', [$Counter.wrap(counter)]);
  final rawIncrementer = IncrementerSub(counter);

  group('Counter tests', () {
    setUp(() {
      counter.reset();
    });

    tearDown(() {
      assert(counter.count == kIterations);
    });

    benchmark('Raw increment', () {
      counter.increment();
    }, iterations: kIterations);

    benchmark('Raw class increment', () {
      rawIncrementer.doJobOverride();
    }, iterations: kIterations);

    benchmark('Eval function', () {
      runtime.executeLib('package:test/main.dart', 'increment', [$Counter.wrap(counter)]);
    }, iterations: kIterations);

    benchmark('Eval original', () {
      incrementer.doJobOriginal();
    }, iterations: kIterations);

    benchmark('Eval super', () {
      incrementer.doJobSuper();
    }, iterations: kIterations);

    benchmark('Eval overidden', () {
      incrementer.doJobOverride();
    }, iterations: kIterations);
  });
}

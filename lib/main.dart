import 'dart:async';

import 'package:extension_test/plugin_provider.dart';
import 'package:extension_test/plugins.dart';
import 'package:extension_test/state.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  // We should have just called [PluginProvider.load] here,
  // but this way it's... cleaner? idk.
  WidgetsFlutterBinding.ensureInitialized();
  await PluginProvider.instance.ready;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Plugins Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Plugins Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _state = AppState();
  late StreamSubscription _intentSub;

  Future<void> _gotPlugins(List<SharedMediaFile> files) async {
    for (final sharedFile in files) {
      // This is a debug print to learn file's name and mime type.
      print(sharedFile.toMap());
      try {
        await PluginProvider.instance.install(sharedFile.path);
      } on PluginLoadException catch (e) {
        print('Error: $e');
      }
    }

    // If we don't include this line, we will get the same event multiple
    // times — but the file would be absent already.
    ReceiveSharingIntent.instance.reset();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    // At this point the state is being initialized from the plugins.
    PluginProvider.instance.setState(_state);

    // Subscribing to the incoming files stream.
    _intentSub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_gotPlugins, onError: (err) {
      print('Intent data stream error: $err');
    });

    // Processing the file we've been called with.
    ReceiveSharingIntent.instance.getInitialMedia().then(_gotPlugins);
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _state.increment();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // One new button, for managing plugins.
          IconButton(
            icon: Icon(Icons.electrical_services),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PluginsPage(),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${_state.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:extension_test/plugin_provider.dart';
import 'package:flutter/material.dart';

class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  @override
  Widget build(BuildContext context) {
    final pp = PluginProvider.instance;

    return Scaffold(
      appBar: AppBar(title: Text('Plugins')),
      body: ListView.separated(
        itemCount: pp.count,
        separatorBuilder: (_, idx) => Divider(),
        itemBuilder: (_, idx) {
          final plugin = pp.all[idx];
          return Dismissible(
            key: Key(plugin.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              padding: EdgeInsets.only(right: 15.0),
              alignment: Alignment.centerRight,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) async {
              // Plugin deletion is easily reversible (by installing it anew),
              // so we don't ask the user again.
              await pp.deletePlugin(plugin.id);
              if (mounted) {
                setState(() {});
              }
            },
            child: ListTile(
              title: Text(plugin.name),
              trailing: pp.isActive(plugin.id) ? Icon(Icons.check_circle) : null,
              onTap: () async {
                // We need [setState], because enabling the plugin may
                // change something in the app state or visually.
                await pp.toggle(plugin.id);
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

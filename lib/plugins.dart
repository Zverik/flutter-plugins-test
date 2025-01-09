import 'package:extension_test/plugin_provider.dart';
import 'package:flutter/material.dart';

class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  void _repaint() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    PluginProvider.instance.addListener(_repaint);
  }

  @override
  void dispose() {
    PluginProvider.instance.removeListener(_repaint);
    super.dispose();
  }

  List<Widget> _buildPluginRow(BuildContext context, Plugin plugin) {
    final pp = PluginProvider.instance;
    final settings = pp.buildSettingsWidget(context, plugin.id);
    return [
      Dismissible(
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
      ),
      if (settings != null)
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: settings,
        ),
      Divider(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pp = PluginProvider.instance;

    return Scaffold(
      appBar: AppBar(title: Text('Plugins')),
      body: ListView(
        children: [
          for (final plugin in pp.all) ..._buildPluginRow(context, plugin),
        ],
      ),
    );
  }
}

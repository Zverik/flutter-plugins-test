import '../models.dart';
import 'package:flutter/material.dart';

class AssetPlugin extends PluginBase {
  AssetPlugin(PluginContext context) : super(context);

  @override
  Widget? numberWidget(BuildContext context, AppState state) {
    return Stack(children: [
      Image.file(
        this.context.getFile('workplace.jpg'),
        fit: BoxFit.fill,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Text(
          state.counter.toString(),
          style: TextStyle(color: Colors.blue, fontSize: 100),
        ),
      ),
    ]);
  }
}

PluginBase setup(PluginContext context) => AssetPlugin(context);

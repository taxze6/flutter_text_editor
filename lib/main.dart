import 'package:flutter/material.dart';

import 'lib/app_state.dart';
import 'lib/app_state_manager.dart';
import 'lib/basic_text_field.dart';
import 'lib/formatting_toolbar.dart';
import 'lib/replacements.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateWidget(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Rich Text Editor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Rich Text Editor'),
      ),
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
  late ReplacementTextEditingController _replacementTextEditingController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _replacementTextEditingController = ReplacementTextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _replacementTextEditingController =
        AppStateManager.of(context).appState.replacementsController;
  }

  static Route<Object?> _aboutDialogBuilder(
      BuildContext context, Object? arguments) {
    const String aboutContent = "觉得不错的话，可以给我的文章点个赞~有问题需要联系我，请微信搜索Taxze2019";
    return DialogRoute<void>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Center(child: Text('Hello')),
        content: Text(aboutContent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).restorablePush(_aboutDialogBuilder);
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: BasicTextField(
                  controller: _replacementTextEditingController,
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                  focusNode: _focusNode,
                ),
                // ),
              ),
              const FormattingToolbar(),
            ],
          ),
        ),
      ),
    );
  }
}

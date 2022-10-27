import 'package:flutter/material.dart';

import 'app_state.dart';
import 'app_state_manager.dart';
import 'basic_text_field.dart';
import 'formatting_toolbar.dart';
import 'replacements.dart';

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
        title: 'Simplistic Editor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Simplistic Editor'),
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
    const String aboutContent =
        '如果觉得对您有帮助，请给我的文章点个赞~有任何问题需要联系我，请在wx搜索Taxze2019来联系我';
    return DialogRoute<void>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Center(child: Text('Taxze')),
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
              const FormattingToolbar(),
              Expanded(
                // child: Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 35.0),
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
              // const Expanded(
              //   child: TextEditingDeltaHistoryView(),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

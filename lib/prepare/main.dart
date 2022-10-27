import 'package:flutter/material.dart';

import 'src/rich_text_editor.dart';

///错误示范 ===> 该方案实现简单，建议先理解这个。
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Rich Text Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Color cursorColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: RichTextEditor(
      //   controller: TextEditingController(),
      // ),
      body: TextField(),
    );
  }
}

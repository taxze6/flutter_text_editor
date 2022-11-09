import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_resizer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Rich Text Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
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
  File? _image;
  double width = 100.0;
  double height = 100.0;

  void getImage() async {

    var image = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _image = File(image!.path);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.photo_camera),
        onPressed: () => getImage(),
      ),
      body: Center(
        child: _widgetSpan(),
      ),
    );
  }

  Widget _widgetSpan() {
    return Text.rich(TextSpan(
      children: <InlineSpan>[
        const TextSpan(text: 'Hello '),
        WidgetSpan(
          child: _image != null
              ? GestureDetector(
                  onTap: () {
                    showCupertinoModalPopup<void>(
                        context: context,
                        builder: (context) {
                          return ImageResizer(
                              onImageResize: (w, h) {
                                setState(() {
                                  width = w;
                                  height = h;
                                });
                              },
                              imageWidth: width,
                              imageHeight: height,
                              maxWidth: MediaQuery.of(context).size.width * 0.5,
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.5);
                        });
                  },
                  child: Image.file(
                    _image!,
                    width: width,
                    height: height,
                  ),
                )
              : const SizedBox(),
        ),
        const TextSpan(text: 'Taxze!'),
      ],
    ));
  }
}

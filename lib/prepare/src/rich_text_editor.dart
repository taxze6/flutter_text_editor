import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'rich_text_editor_provider.dart';
import 'utils/rich_text_style.dart';
import 'widget/rich_text_field.dart';
import 'widget/rich_text_toolbar.dart';

class RichTextEditor extends StatefulWidget {
  final TextEditingController controller;

  const RichTextEditor({super.key, required this.controller});

  @override
  State<StatefulWidget> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RichTextEditorProvider>(
      create: (_) => RichTextEditorProvider(),
      builder: (BuildContext context, Widget? child) {
        return Stack(children: [
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            bottom: 56,
            child: Consumer<RichTextEditorProvider>(
              builder: (_, RichTextEditorProvider value, __) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (_, int index) {
                    return Focus(
                      onFocusChange: (bool hasFocus) {
                        if (hasFocus) {
                          value.setFocus(value.typeAt(index));
                        }
                      },
                      child: RichTextField(
                        inputType: value.typeAt(index),
                        controller: value.controllerAt(index),
                        focusNode: value.nodeAt(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Selector<RichTextEditorProvider, List<RichTextInputType>>(
              selector: (_, RichTextEditorProvider value) => value.inputType,
              builder:
                  (BuildContext context, List<RichTextInputType> value, _) {
                return RichTextToolbar(
                  inputType: value,
                  onInputTypeChange: Provider.of<RichTextEditorProvider>(
                    context,
                    listen: false,
                  ).setType,
                );
              },
            ),
          )
        ]);
      },
    );
  }
}

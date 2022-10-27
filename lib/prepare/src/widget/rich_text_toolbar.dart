import 'package:flutter/material.dart';
import '../utils/rich_text_style.dart';

class RichTextToolbar extends StatefulWidget {
  final List<RichTextInputType> inputType;
  final ValueChanged<RichTextInputType> onInputTypeChange;
  final Color color;
  final Color colorSelected;

  const RichTextToolbar({
    super.key,
    required this.onInputTypeChange,
    required this.inputType,
    this.color = const Color(0xFFFFFFFF),
    this.colorSelected = const Color(0xFF1F59FC),
  });

  @override
  State<StatefulWidget> createState() => _RichTextToolbarState();
}

class _RichTextToolbarState extends State<RichTextToolbar> {
  @override
  Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Material(
            elevation: 4.0,
            color: widget.color,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Card(
                    color: widget.inputType.contains(RichTextInputType.header1)
                        ? widget.colorSelected
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.font_download_sharp),
                      color:
                          widget.inputType.contains(RichTextInputType.header1)
                              ? Colors.white
                              : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.header1);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color: widget.inputType.contains(RichTextInputType.header2)
                        ? widget.colorSelected
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.font_download_sharp),
                      color:
                          widget.inputType.contains(RichTextInputType.header2)
                              ? Colors.white
                              : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.header2);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color: widget.inputType.contains(RichTextInputType.header3)
                        ? widget.colorSelected
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.font_download_sharp),
                      color:
                          widget.inputType.contains(RichTextInputType.header3)
                              ? Colors.white
                              : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.header3);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color: widget.inputType.contains(RichTextInputType.italic)
                        ? widget.colorSelected
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_italic),
                      color: widget.inputType.contains(RichTextInputType.italic)
                          ? Colors.white
                          : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.italic);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color: widget.inputType.contains(RichTextInputType.bold)
                        ? widget.colorSelected
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_bold),
                      color: widget.inputType.contains(RichTextInputType.bold)
                          ? Colors.white
                          : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.bold);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color:
                        widget.inputType.contains(RichTextInputType.leftAlign)
                            ? widget.colorSelected
                            : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_align_left_rounded),
                      color:
                          widget.inputType.contains(RichTextInputType.leftAlign)
                              ? Colors.white
                              : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.leftAlign);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color:
                        widget.inputType.contains(RichTextInputType.centerAlign)
                            ? widget.colorSelected
                            : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_align_center),
                      color: widget.inputType
                              .contains(RichTextInputType.centerAlign)
                          ? Colors.white
                          : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.centerAlign);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color:
                        widget.inputType.contains(RichTextInputType.rightAlign)
                            ? widget.colorSelected
                            : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_align_right),
                      color: widget.inputType
                              .contains(RichTextInputType.rightAlign)
                          ? Colors.white
                          : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.rightAlign);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color:
                        widget.inputType.contains(RichTextInputType.underline)
                            ? widget.colorSelected
                            : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_color_text),
                      color:
                          widget.inputType.contains(RichTextInputType.underline)
                              ? Colors.white
                              : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.underline);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color:
                        widget.inputType.contains(RichTextInputType.lineThrough)
                            ? widget.colorSelected
                            : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_clear),
                      color: widget.inputType
                              .contains(RichTextInputType.lineThrough)
                          ? Colors.white
                          : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.lineThrough);
                        setState(() {});
                      },
                    ),
                  ),
                  Card(
                    color: widget.inputType.contains(RichTextInputType.list)
                        ? widget.colorSelected
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.format_list_bulleted),
                      color: widget.inputType.contains(RichTextInputType.list)
                          ? Colors.white
                          : Colors.black,
                      onPressed: () {
                        widget.onInputTypeChange(RichTextInputType.list);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            )));
  }
}

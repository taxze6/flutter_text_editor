import 'package:flutter/material.dart';

import '../utils/rich_text_color.dart';
import '../utils/rich_text_style.dart';

class RichTextField extends StatelessWidget {
  final List<RichTextInputType> inputType;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color textColor;

  const RichTextField({
    super.key,
    required this.inputType,
    required this.controller,
    required this.focusNode,
    this.textColor = RichTextColor.defaultTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      //用于自动获取焦点
      autofocus: true,
      //multiline为多行文本，常配合maxLines使用
      keyboardType: TextInputType.multiline,
      //将maxLines设置为null，从而取消对行数的限制
      maxLines: null,
      //光标颜色
      cursorColor: RichTextColor.defaultTextColor,
      textAlign: richTextAlign(inputType),
      decoration: InputDecoration(
        border: InputBorder.none,
        //当为list type时，加入占位符
        prefixText: prefix(inputType),
        prefixStyle: richTextStyle(inputType, textColor: textColor),
        //减少垂直高度减少，设为密集模式
        isDense: true,
        contentPadding: richTextPadding(inputType),
      ),
      style: richTextStyle(inputType, textColor: textColor),
    );
  }
}

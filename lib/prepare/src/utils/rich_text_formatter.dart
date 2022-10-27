import 'package:flutter/services.dart';

class AllFormatter extends TextInputFormatter {
  final String model; //格式
  final String? separator; //识别格式后中间的分割字符

  AllFormatter({
    required this.model,
    required this.separator,
  });

  //通过TextEditingValue可以读取和写入文本
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var oldText = oldValue.text;
    var newText = newValue.text;
    //判断是否有输入文本
    if (newText.isNotEmpty) {
      if (newText.length > oldText.length) {
        if (newText.length > model.length) return oldValue;
        if (newText.length < model.length &&
            model[newText.length - 1] == separator) {
          return TextEditingValue(
              //text代表用户输入后的文本(用户自己输入的，经过程序逻辑处理后的文本)
              text:
                  "$oldText$separator${newText.substring(newText.length - 1)}",
              //通过selection你可以知道当前所选择的光标位置和选择范围
              selection:
                  TextSelection.collapsed(offset: newValue.selection.end + 1));
        }
      }
    }
    return newValue;
  }
}

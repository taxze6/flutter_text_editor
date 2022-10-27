import 'package:flutter/material.dart';
import 'rich_text_color.dart';

enum RichTextInputType {
  header1,
  header2,
  header3,
  leftAlign,
  rightAlign,
  centerAlign,
  normal,
  italic,
  bold,
  underline,
  lineThrough,
  list,
}

///定义富文本样式
TextStyle richTextStyle(List<RichTextInputType> list, {Color? textColor}) {
  //默认样式
  double fontSize = 18.0;
  FontWeight fontWeight = FontWeight.normal;
  Color richTextColor = RichTextColor.defaultTextColor;
  TextDecoration decoration = TextDecoration.none;
  FontStyle fontStyle = FontStyle.normal;
  TextAlign align = TextAlign.start;
  for (RichTextInputType i in list) {
    switch (i) {
      case RichTextInputType.header1:
        fontSize = 28.0;
        fontWeight = FontWeight.w700;
        break;
      case RichTextInputType.header2:
        fontSize = 24.0;
        fontWeight = FontWeight.w700;
        break;
      case RichTextInputType.header3:
        fontSize = 20.0;
        fontWeight = FontWeight.w700;
        break;
      case RichTextInputType.normal:
        break;
      case RichTextInputType.italic:
        fontStyle = FontStyle.italic;
        break;
      case RichTextInputType.bold:
        fontWeight = FontWeight.bold;
        break;
      case RichTextInputType.underline:
        decoration = TextDecoration.underline;
        break;
      case RichTextInputType.lineThrough:
        decoration = TextDecoration.lineThrough;
        break;
      case RichTextInputType.list:
        break;
    }
  }
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: richTextColor,
    decoration: decoration,
  );
}

///定义富文本位置
TextAlign richTextAlign(List<RichTextInputType> list) {
  TextAlign richTextAlign = TextAlign.start;
  for (RichTextInputType i in list) {
    switch (i) {
      case RichTextInputType.leftAlign:
        richTextAlign = TextAlign.left;
        break;
      case RichTextInputType.rightAlign:
        richTextAlign = TextAlign.right;
        break;
      case RichTextInputType.centerAlign:
        richTextAlign = TextAlign.center;
        break;
    }
  }
  return richTextAlign;
}

///定义富文本间距
EdgeInsets richTextPadding(List<RichTextInputType> list) {
  //默认间距
  EdgeInsets edgeInsets = const EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 4.0,
  );
  for (RichTextInputType i in list) {
    switch (i) {
      case RichTextInputType.header1:
        edgeInsets = const EdgeInsets.only(
          top: 24.0,
          right: 16.0,
          bottom: 8.0,
          left: 16.0,
        );
        break;
      case RichTextInputType.header2:
        edgeInsets = const EdgeInsets.only(
          top: 24.0,
          right: 16.0,
          bottom: 8.0,
          left: 16.0,
        );
        break;
      case RichTextInputType.header3:
        edgeInsets = const EdgeInsets.only(
          top: 24.0,
          right: 16.0,
          bottom: 8.0,
          left: 16.0,
        );
        break;
      case RichTextInputType.list:
        edgeInsets = const EdgeInsets.only(
          top: 4.0,
          right: 16.0,
          bottom: 4.0,
          left: 24.0,
        );
        break;
    }
  }
  return edgeInsets;
}

///当为list type时，加上前置占位符
/// 效果->  ·Hello Taxze
String prefix(List<RichTextInputType> list) {
  String prefixText = "";
  for (RichTextInputType i in list) {
    if (i == RichTextInputType.list) {
      prefixText = '\u2022';
    }
  }
  return prefixText;
}

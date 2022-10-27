import 'package:flutter/material.dart';

import 'utils/rich_text_style.dart';

class RichTextEditorProvider extends ChangeNotifier     {
  List<RichTextInputType> inputType = [RichTextInputType.normal];

  RichTextEditorProvider({
    RichTextInputType defaultType = RichTextInputType.normal,
  }) {
    inputType.add(defaultType);
    insert(index: 0, type: inputType);
  }

  //存放每个输入框的焦点
  final List<FocusNode> _nodes = [];

  int get focus => _nodes.indexWhere((node) => node.hasFocus);

  FocusNode nodeAt(int index) => _nodes.elementAt(index);

  final List<TextEditingController> _controllers = [];

  int get length => _controllers.length;

  TextEditingController controllerAt(int index) =>
      _controllers.elementAt(index);

  final List<List<RichTextInputType>> _types = [];

  List<RichTextInputType> typeAt(int index) => _types.elementAt(index);

  void setType(RichTextInputType type) {
    if (type == RichTextInputType.header1 ||
        type == RichTextInputType.header2 ||
        type == RichTextInputType.header3) {
      //三种标题只能同时存在一个
      bool isAdd = true;
      RichTextInputType? begin;
      for (RichTextInputType i in inputType) {
        if ((i == RichTextInputType.header1 ||
            i == RichTextInputType.header2 ||
            i == RichTextInputType.header3)) {
          begin = i;
          if (i == type) {
            isAdd = false;
          }
        }
      }
      if (isAdd) {
        inputType.remove(begin);
        inputType.add(type);
      } else {
        inputType.remove(type);
      }
    } else if (type == RichTextInputType.underline ||
        type == RichTextInputType.lineThrough) {
      //下划线和删除线只能存在一个
      bool isAdd = true;
      RichTextInputType? begin;
      for (RichTextInputType i in inputType) {
        if ((i == RichTextInputType.underline ||
            i == RichTextInputType.lineThrough)) {
          begin = i;
          if (i == type) {
            isAdd = false;
          }
        }
      }
      if (isAdd) {
        inputType.remove(begin);
        inputType.add(type);
      } else {
        inputType.remove(type);
      }
    } else if (type == RichTextInputType.italic ||
        type == RichTextInputType.bold ||
        type == RichTextInputType.list) {
      //判断是添加样式还是删除样式
      bool isAdd = true;
      for (RichTextInputType i in inputType) {
        if ((i == type)) {
          isAdd = false;
        }
      }
      if (isAdd) {
        inputType.add(type);
      } else {
        inputType.remove(type);
      }
    } else if (type == RichTextInputType.leftAlign ||
        type == RichTextInputType.centerAlign ||
        type == RichTextInputType.rightAlign) {
      //三种位置只能同时存在一个
      bool isAdd = true;
      RichTextInputType? begin;
      for (RichTextInputType i in inputType) {
        if ((i == RichTextInputType.leftAlign ||
            i == RichTextInputType.centerAlign ||
            i == RichTextInputType.rightAlign)) {
          begin = i;
          if (i == type) {
            isAdd = false;
          }
        }
      }
      if (isAdd) {
        inputType.remove(begin);
        inputType.add(type);
      } else {
        inputType.remove(type);
      }
    } else {
      //如果不是以上type，则直接添加
      inputType.add(type);
    }
    _types.removeAt(focus);
    _types.insert(focus, inputType);
    notifyListeners();
  }

  void setFocus(List<RichTextInputType> type) {
    inputType = type;
    notifyListeners();
  }

  void insert({
    int? index,
    String? text,
    required List<RichTextInputType> type,
  }) {
    final TextEditingController controller = TextEditingController(
      text: '\u200B${text ?? ''}',
    );
    controller.addListener(() {
      if (!controller.text.startsWith('\u200B')) {
        final int index = _controllers.indexOf(controller);
        if (index > 0) {
          controllerAt(index - 1).text += controller.text;
          controllerAt(index - 1).selection = TextSelection.fromPosition(
            TextPosition(
              offset: controllerAt(index - 1).text.length - controller.text.length,
            ),
          );
          //获取光标
          nodeAt(index - 1).requestFocus();
          _controllers.removeAt(index);
          _nodes.removeAt(index);
          _types.removeAt(index);
          notifyListeners();
        }
      }
      if (controller.text.contains('\n')) {
        final int index = _controllers.indexOf(controller);
        List<String> split = controller.text.split('\n');
        controller.text = split.first;
        insert(
            index: index + 1,
            text: split.last,
            type: typeAt(index).contains(RichTextInputType.list)
                ? [RichTextInputType.list]
                : [RichTextInputType.normal]);
        controllerAt(index + 1).selection = TextSelection.fromPosition(
          const TextPosition(offset: 1),
        );
        nodeAt(index + 1).requestFocus();
        notifyListeners();
      }
    });
    _controllers.insert(index!, controller);
    _types.insert(index, type);
    _nodes.insert(index, FocusNode());
  }
}

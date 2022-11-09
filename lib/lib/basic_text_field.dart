import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'basic_text_input_client.dart';
import 'replacements.dart';

/// 基本TextField
class BasicTextField extends StatefulWidget {
  const BasicTextField({
    super.key,
    required this.controller,
    required this.style,
    required this.focusNode,
  });

  final ReplacementTextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;

  @override
  State<BasicTextField> createState() => _BasicTextFieldState();
}

class _BasicTextFieldState extends State<BasicTextField> {
  final GlobalKey<BasicTextInputClientState> textInputClientKey =
      GlobalKey<BasicTextInputClientState>();

  BasicTextInputClientState? get _textInputClient =>
      textInputClientKey.currentState;

  RenderEditable get _renderEditable => _textInputClient!.renderEditable;

  // 用于文本选择手势。
  // 在最后一次拖动开始时[RenderEditable]的视口偏移像素。
  double _dragStartViewportOffset = 0.0;
  late DragStartDetails _startDetails;

  // 用于文本的选择
  TextSelectionControls? _textSelectionControls;
  bool _showSelectionHandles = false;

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    // 当文本字段被某些东西激活时，它不会触发选择覆盖，我们也不应该显示手柄。
    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.scribble) {
      return true;
    }

    if (widget.controller.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final Offset startOffset = _renderEditable.maxLines == 1
        ? Offset(_renderEditable.offset.pixels - _dragStartViewportOffset, 0.0)
        : Offset(0.0, _renderEditable.offset.pixels - _dragStartViewportOffset);

    _renderEditable.selectPositionAt(
      from: _startDetails.globalPosition - startOffset,
      to: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  void _onDragStart(DragStartDetails details) {
    _startDetails = details;
    _dragStartViewportOffset = _renderEditable.offset.pixels;
  }

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(this.context).platform) {
      case TargetPlatform.iOS:
        _textSelectionControls = cupertinoTextSelectionControls;
        break;
      case TargetPlatform.macOS:
        _textSelectionControls = cupertinoDesktopTextSelectionControls;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _textSelectionControls = materialTextSelectionControls;
        break;
      case TargetPlatform.linux:
        _textSelectionControls = desktopTextSelectionControls;
        break;
      case TargetPlatform.windows:
        _textSelectionControls = desktopTextSelectionControls;
        break;
    }

    return
      FocusTrapArea(
      focusNode: widget.focusNode,
      child:
      GestureDetector(
        //自己和child都可以接收事件
        behavior: HitTestBehavior.translucent,
        onPanStart: (dragStartDetails) => _onDragStart(dragStartDetails),
        onPanUpdate: (dragUpdateDetails) => _onDragUpdate(dragUpdateDetails),
        onTap: () {
          _textInputClient!.requestKeyboard();
        },
        onTapDown: (tapDownDetails) {
          _renderEditable.handleTapDown(tapDownDetails);
          _renderEditable.selectPosition(cause: SelectionChangedCause.tap);
        },
        onLongPressMoveUpdate: (longPressMoveUpdateDetails) {
          switch (Theme.of(this.context).platform) {
            case TargetPlatform.iOS:
            case TargetPlatform.macOS:
              _renderEditable.selectPositionAt(
                from: longPressMoveUpdateDetails.globalPosition,
                cause: SelectionChangedCause.longPress,
              );
              break;
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
            case TargetPlatform.linux:
            case TargetPlatform.windows:
              _renderEditable.selectWordsInRange(
                from: longPressMoveUpdateDetails.globalPosition -
                    longPressMoveUpdateDetails.offsetFromOrigin,
                to: longPressMoveUpdateDetails.globalPosition,
                cause: SelectionChangedCause.longPress,
              );
              break;
          }
        },
        onLongPressEnd: (longPressEndDetails) =>
            _textInputClient!.showToolbar(),
        onHorizontalDragStart: (dragStartDetails) =>
            _onDragStart(dragStartDetails),
        onHorizontalDragUpdate: (dragUpdateDetails) =>
            _onDragUpdate(dragUpdateDetails),
        child: SizedBox(
          height: double.infinity,
          width: MediaQuery.of(context).size.width,
          child: BasicTextInputClient(
              key: textInputClientKey,
              controller: widget.controller,
              style: widget.style,
              focusNode: widget.focusNode,
              selectionControls: _textSelectionControls,
              onSelectionChanged: _handleSelectionChanged,
              showSelectionHandles: _showSelectionHandles,
            ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'replacements.dart';

///用户更改选择时的返回，包含光标位置
typedef SelectionChangedCallback = void Function(
    TextSelection selection, SelectionChangedCause? cause);

/// DeltaTextInputClient的基础实现
class BasicTextInputClient extends StatefulWidget {
  final ReplacementTextEditingController controller;
  final TextStyle style;
  final FocusNode focusNode;
  final TextSelectionControls? selectionControls;
  final bool showSelectionHandles;
  final SelectionChangedCallback onSelectionChanged;

  const BasicTextInputClient(
      {super.key,
      required this.controller,
      required this.style,
      required this.focusNode,
      this.selectionControls,
      required this.showSelectionHandles,
      required this.onSelectionChanged});

  @override
  State<StatefulWidget> createState() => BasicTextInputClientState();
}

class BasicTextInputClientState extends State<BasicTextInputClient>
    with TextSelectionDelegate
    implements DeltaTextInputClient {
  final GlobalKey _textKey = GlobalKey();
  late AppStateWidgetState manager;
  final ClipboardStatusNotifier? _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();

  TextEditingValue get _value => widget.controller.value;

  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  TextInputConnection? _textInputConnection;

  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  ///跟踪引擎中最后一个已知的文本编辑值，这样我们就不会这样做了
  ///如果没必要，就发个更新信息。
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  TextDirection get _textDirection => Directionality.of(context);

  @override
  AutofillScope? get currentAutofillScope => throw UnimplementedError();

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  bool showToolbar() {
    // 在web上提供剪切板功能
    if (kIsWeb) return false;
    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }
    _selectionOverlay!.showToolbar();
    return true;
  }

  ///更新编辑的值，输入一个值就要经过该方法
  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    TextEditingValue value = _value;

    for (final TextEditingDelta delta in textEditingDeltas) {
      value = delta.apply(value);
    }

    _lastKnownRemoteTextEditingValue = value;

    if (value == _value) {
      return;
    }

    final bool selectionChanged =
        _value.selection.start != value.selection.start ||
            _value.selection.end != value.selection.end;
    manager.updateTextEditingDeltaHistory(textEditingDeltas);

    _value = value;

    if (widget.controller is ReplacementTextEditingController) {
      for (final TextEditingDelta delta in textEditingDeltas) {
        (widget.controller as ReplacementTextEditingController)
            .syncReplacementRanges(delta);
      }
    }

    if (selectionChanged) {
      manager.updateToggleButtonsStateOnSelectionChanged(value.selection,
          widget.controller as ReplacementTextEditingController);
    }
  }

  ///如果不存在输入连接，则打开输入连接并设置它的风格。如果其中一个是活跃的，就展示出来。
  void _openInputConnection() {
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      _textInputConnection = TextInput.attach(
        this,
        const TextInputConfiguration(
          enableDeltaModel: true,
          inputAction: TextInputAction.newline,
          inputType: TextInputType.multiline,
        ),
      );
      final TextStyle style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          // make this variable.
          textAlign: TextAlign.left, // make this variable.
        )
        ..setEditingState(localValue)
        ..show();

      _lastKnownRemoteTextEditingValue = localValue;
    } else {
      _textInputConnection!.show();
    }
  }

  /// 关闭输入连接，如果其中一个是活动的。
  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  ///获取焦点，键盘输入
  bool get _hasFocus => widget.focusNode.hasFocus;

  ///在获得焦点时打开输入连接。焦点丢失时关闭输入连接。
  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _handleFocusChanged() {
    // Open or close input connection depending on focus.
    _openOrCloseInputConnectionIfNeeded();
    if (_hasFocus) {
      if (!_value.selection.isValid) {
        // Place cursor at the end if the selection is invalid when we receive focus.
        final TextSelection validSelection =
            TextSelection.collapsed(offset: _value.text.length);
        _handleSelectionChanged(validSelection, null);
        manager.updateToggleButtonsStateOnSelectionChanged(validSelection,
            widget.controller as ReplacementTextEditingController);
      }
    }
  }

  ///返回TextSpan
  InlineSpan _buildTextSpan() {
    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: true,
    );
  }

  void _userUpdateTextEditingValueWithDelta(
      TextEditingDelta textEditingDelta, SelectionChangedCause cause) {
    TextEditingValue value = _value;

    value = textEditingDelta.apply(value);

    if (widget.controller is ReplacementTextEditingController) {
      (widget.controller as ReplacementTextEditingController)
          .syncReplacementRanges(textEditingDelta);
    }

    if (value != _value) {
      manager.updateTextEditingDeltaHistory([textEditingDelta]);
    }

    userUpdateTextEditingValue(value, cause);
  }

  ///键盘文本编辑
  TextSelection get _selection => _value.selection;
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(
      onInvoke: (intent) => _delete(intent.forward),
    ),
    ExtendSelectionByCharacterIntent:
        CallbackAction<ExtendSelectionByCharacterIntent>(
      onInvoke: (intent) =>
          _extendSelection(intent.forward, intent.collapseSelection),
    ),
    SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
      onInvoke: (intent) => selectAll(intent.cause),
    ),
    CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
      onInvoke: (intent) => copySelection(intent.cause),
    ),
    PasteTextIntent: CallbackAction<PasteTextIntent>(
      onInvoke: (intent) => pasteText(intent.cause),
    ),
    DoNothingAndStopPropagationTextIntent: DoNothingAction(
      consumesKey: false,
    ),
  };

  void _delete(bool forward) {
    if (_value.text.isEmpty) return;

    late final TextRange deletedRange;
    late final TextRange newComposing;
    late final String deletedText;
    final int offset = _selection.baseOffset;

    if (_selection.isCollapsed) {
      if (forward) {
        if (_selection.baseOffset == _value.text.length) return;
        deletedText = _value.text.substring(offset).characters.first;
        deletedRange = TextRange(
          start: offset,
          end: offset + deletedText.length,
        );
      } else {
        if (_selection.baseOffset == 0) return;
        deletedText = _value.text.substring(0, offset).characters.last;
        deletedRange = TextRange(
          start: offset - deletedText.length,
          end: offset,
        );
      }
    } else {
      deletedRange = _selection;
    }

    final bool isComposing =
        _selection.isCollapsed && _value.isComposingRangeValid;

    if (isComposing) {
      newComposing = TextRange.collapsed(deletedRange.start);
    } else {
      newComposing = TextRange.empty;
    }

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaDeletion(
        oldText: _value.text,
        selection: TextSelection.collapsed(offset: deletedRange.start),
        composing: newComposing,
        deletedRange: deletedRange,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _extendSelection(bool forward, bool collapseSelection) {
    late final TextSelection selection;

    if (collapseSelection) {
      if (!_selection.isCollapsed) {
        final int firstOffset =
            _selection.isNormalized ? _selection.start : _selection.end;
        final int lastOffset =
            _selection.isNormalized ? _selection.end : _selection.start;
        selection =
            TextSelection.collapsed(offset: forward ? lastOffset : firstOffset);
      } else {
        if (forward && _selection.baseOffset == _value.text.length) return;
        if (!forward && _selection.baseOffset == 0) return;
        final int adjustment = forward
            ? _value.text
                .substring(_selection.baseOffset)
                .characters
                .first
                .length
            : -_value.text
                .substring(0, _selection.baseOffset)
                .characters
                .last
                .length;
        selection = TextSelection.collapsed(
          offset: _selection.baseOffset + adjustment,
        );
      }
    } else {
      if (forward && _selection.extentOffset == _value.text.length) return;
      if (!forward && _selection.extentOffset == 0) return;
      final int adjustment = forward
          ? _value.text.substring(_selection.baseOffset).characters.first.length
          : -_value.text
              .substring(0, _selection.baseOffset)
              .characters
              .last
              .length;
      selection = TextSelection(
        baseOffset: _selection.baseOffset,
        extentOffset: _selection.extentOffset + adjustment,
      );
    }

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaNonTextUpdate(
        oldText: _value.text,
        selection: selection,
        composing: _value.composing,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  ///用于更新文本编辑值
  void _didChangeTextEditingValue() {
    _updateRemoteTextEditingValueIfNeeded();
    _updateOrDisposeOfSelectionOverlayIfNeeded();
    setState(() {});
  }

  void _toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay!.toolbarIsVisible) {
      hideToolbar(false);
    } else {
      showToolbar();
    }
  }

  ///当文本发生变化时，需要对文本编辑进行更新，更新的值必须在文本选择的范围内
  void _updateOrDisposeOfSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(_value);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    }
  }

  void _updateRemoteTextEditingValueIfNeeded() {
    if (_lastKnownRemoteTextEditingValue == _value) return;

    if (_textInputConnection != null) {
      _textInputConnection!.setEditingState(_value);
      _lastKnownRemoteTextEditingValue = _value;
    }
  }

  ///复制文本
  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection copyRange = textEditingValue.selection;
    if (!copyRange.isValid || copyRange.isCollapsed) return;
    final String text = textEditingValue.text;
    Clipboard.setData(ClipboardData(text: copyRange.textInside(text)));

    // 如果粘贴文本是通过工具栏完成的，需要隐藏工具栏，并将光标定位到文本的最后
    if (cause == SelectionChangedCause.toolbar) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          _userUpdateTextEditingValueWithDelta(
            TextEditingDeltaNonTextUpdate(
              oldText: textEditingValue.text,
              selection: TextSelection.collapsed(
                  offset: textEditingValue.selection.end),
              composing: TextRange.empty,
            ),
            cause,
          );
          break;
      }
      hideToolbar();
    }
    _clipboardStatus?.update();
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    final TextSelection cutRange = textEditingValue.selection;
    final String text = textEditingValue.text;

    if (cutRange.isCollapsed) return;
    Clipboard.setData(ClipboardData(text: cutRange.textInside(text)));
    final int lastSelectionIndex =
        math.min(cutRange.baseOffset, cutRange.extentOffset);
    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaReplacement(
        oldText: textEditingValue.text,
        replacementText: '',
        replacedRange: cutRange,
        selection: TextSelection.collapsed(offset: lastSelectionIndex),
        composing: TextRange.empty,
      ),
      cause,
    );
    if (cause == SelectionChangedCause.toolbar) hideToolbar();
    _clipboardStatus?.update();
  }

  //隐藏工具栏
  @override
  void hideToolbar([bool hideHandles = true]) {
    if (hideHandles) {
      _selectionOverlay?.hide();
    } else if (_selectionOverlay?.toolbarIsVisible ?? false) {
      // 只隐藏工具栏
      _selectionOverlay?.hideToolbar();
    }
  }

  //粘贴文字
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final TextSelection pasteRange = textEditingValue.selection;
    if (!pasteRange.isValid) return;

    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) return;

    // 粘贴文字后，光标的位置应该被定位于粘贴的内容后面
    final int lastSelectionIndex = math.max(
        pasteRange.baseOffset, pasteRange.baseOffset + data.text!.length);

    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaReplacement(
        oldText: textEditingValue.text,
        replacementText: data.text!,
        replacedRange: pasteRange,
        selection: TextSelection.collapsed(offset: lastSelectionIndex),
        composing: TextRange.empty,
      ),
      cause,
    );

    if (cause == SelectionChangedCause.toolbar) hideToolbar();
  }

  //选中所有文字
  @override
  void selectAll(SelectionChangedCause cause) {
    final TextSelection newSelection = _value.selection
        .copyWith(baseOffset: 0, extentOffset: _value.text.length);
    _userUpdateTextEditingValueWithDelta(
      TextEditingDeltaNonTextUpdate(
        oldText: textEditingValue.text,
        selection: newSelection,
        composing: TextRange.empty,
      ),
      cause,
    );
  }

  @override
  TextEditingValue get textEditingValue => _value;

  ///更新输入文本的值
  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) {
    if (value == _value) return;

    final bool selectionChanged = _value.selection != value.selection;

    if (cause == SelectionChangedCause.drag ||
        cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.tap) {
      // 这里的变化来自于手势，它调用RenderEditable来改变用户选择的文本区域。
      // 创建一个TextEditingDeltaNonTextUpdate后，我们可以获取Delta的历史RenderEditable
      final bool textChanged = _value.text != value.text;
      if (selectionChanged && !textChanged) {
        final TextEditingDeltaNonTextUpdate selectionUpdate =
            TextEditingDeltaNonTextUpdate(
          oldText: value.text,
          selection: value.selection,
          composing: value.composing,
        );
        if (widget.controller is ReplacementTextEditingController) {
          (widget.controller as ReplacementTextEditingController)
              .syncReplacementRanges(selectionUpdate);
        }
        manager.updateTextEditingDeltaHistory([selectionUpdate]);
      }
    }

    final bool selectionRangeChanged =
        _value.selection.start != value.selection.start ||
            _value.selection.end != value.selection.end;

    _value = value;

    if (selectionChanged) {
      _handleSelectionChanged(_value.selection, cause);

      if (selectionRangeChanged) {
        manager.updateToggleButtonsStateOnSelectionChanged(_value.selection,
            widget.controller as ReplacementTextEditingController);
      }
    }
  }

  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  final LayerLink _toolbarLayerLink = LayerLink();

  TextSelectionOverlay? _selectionOverlay;

  RenderEditable get renderEditable =>
      _textKey.currentContext!.findRenderObject()! as RenderEditable;

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    ///如果选择无效，我们将提前返回。这可能发生在
    /// [EditableText]的文本在选择的同时被更新由手势事件更改。
    if (!widget.controller.isSelectionWithinTextBounds(selection)) return;

    widget.controller.selection = selection;

    ///这将显示键盘上的所有选择更改
    switch (cause) {
      case null:
      case SelectionChangedCause.doubleTap:
      case SelectionChangedCause.drag:
      case SelectionChangedCause.forcePress:
      case SelectionChangedCause.longPress:
      case SelectionChangedCause.scribble:
      case SelectionChangedCause.tap:
      case SelectionChangedCause.toolbar:
        requestKeyboard();
        break;
      case SelectionChangedCause.keyboard:
        if (_hasFocus) {
          requestKeyboard();
        }
        break;
    }
    if (widget.selectionControls == null) {
      _selectionOverlay?.dispose();
      _selectionOverlay = null;
    } else {
      if (_selectionOverlay == null) {
        _selectionOverlay = TextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: _value,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditable,
          selectionControls: widget.selectionControls,
          selectionDelegate: this,
          dragStartBehavior: DragStartBehavior.start,
          onSelectionHandleTapped: () {
            _toggleToolbar();
          },
        );
      } else {
        _selectionOverlay!.update(_value);
      }
      _selectionOverlay!.handlesVisible = widget.showSelectionHandles;
      _selectionOverlay!.showHandles();
    }

    try {
      widget.onSelectionChanged.call(selection, cause);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context:
            ErrorDescription('while calling onSelectionChanged for $cause'),
      ));
    }
  }

  static final Map<ShortcutActivator, Intent> _defaultWebShortcuts =
      <ShortcutActivator, Intent>{
    // Activation
    const SingleActivator(LogicalKeyboardKey.space):
        const DoNothingAndStopPropagationIntent(),

    // Scrolling
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DoNothingAndStopPropagationIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DoNothingAndStopPropagationIntent(),
  };

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_didChangeTextEditingValue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    manager = AppStateWidget.of(context);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeTextEditingValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: kIsWeb ? _defaultWebShortcuts : <ShortcutActivator, Intent>{},
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: widget.focusNode,
          child: Scrollable(
            viewportBuilder: (context, position) {
              return CompositedTransformTarget(
                link: _toolbarLayerLink,
                child: _Editable(
                  key: _textKey,
                  startHandleLayerLink: _startHandleLayerLink,
                  endHandleLayerLink: _endHandleLayerLink,
                  inlineSpan: _buildTextSpan(),
                  value: _value,
                  // We pass value.selection to RenderEditable.
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.grey[100],
                  showCursor: ValueNotifier<bool>(_hasFocus),
                  forceLine: true,
                  // Whether text field will take full line regardless of width.
                  readOnly: false,
                  // editable text-field.
                  hasFocus: _hasFocus,
                  maxLines: null,
                  // multi-line text-field.
                  minLines: null,
                  expands: false,
                  // expands to height of parent.
                  strutStyle: null,
                  selectionColor: Colors.blue.withOpacity(0.40),
                  textScaleFactor: MediaQuery.textScaleFactorOf(context),
                  textAlign: TextAlign.left,
                  textDirection: _textDirection,
                  locale: Localizations.maybeLocaleOf(context),
                  textHeightBehavior: DefaultTextHeightBehavior.of(context),
                  textWidthBasis: TextWidthBasis.parent,
                  obscuringCharacter: '•',
                  obscureText: false,
                  // This is a non-private text field that does not require obfuscation.
                  offset: position,
                  onCaretChanged: null,
                  rendererIgnoresPointer: true,
                  cursorWidth: 2.0,
                  cursorHeight: null,
                  cursorRadius: const Radius.circular(2.0),
                  cursorOffset: Offset.zero,
                  paintCursorAboveText: false,
                  enableInteractiveSelection: true,
                  // make true to enable selection on mobile.
                  textSelectionDelegate: this,
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  promptRectRange: null,
                  promptRectColor: null,
                  clipBehavior: Clip.hardEdge,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  ///暂时未处理
  @override
  void bringIntoView(TextPosition position) {
    // TODO: implement bringIntoView
  }

  ///[DeltaTextInputClient] method implementations.
  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      widget.focusNode.unfocus();
      widget.controller.clearComposing();
    }
  }

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void performAction(TextInputAction action) {
    // TODO: implement performAction
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // TODO: implement updateEditingValue
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }
}

class _Editable extends MultiChildRenderObjectWidget {
  _Editable({
    super.key,
    required this.inlineSpan,
    required this.value,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    this.cursorColor,
    this.backgroundCursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.readOnly,
    this.textHeightBehavior,
    required this.textWidthBasis,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.strutStyle,
    this.selectionColor,
    required this.textScaleFactor,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    required this.obscuringCharacter,
    required this.obscureText,
    required this.offset,
    this.onCaretChanged,
    this.rendererIgnoresPointer = false,
    required this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    required this.cursorOffset,
    required this.paintCursorAboveText,
    this.enableInteractiveSelection = true,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    this.promptRectRange,
    this.promptRectColor,
    required this.clipBehavior,
  }) : super(children: _extractChildren(inlineSpan));

  /// 遍历InlineSpan树，深度优先收集的列表
  /// 在WidgetSpan中创建的子部件。
  static List<Widget> _extractChildren(InlineSpan span) {
    final List<Widget> result = <Widget>[];
    //通过visitChildren来实现对子节点的遍历
    span.visitChildren((span) {
      if (span is WidgetSpan) {
        result.add(span.child);
      }
      return true;
    });
    return result;
  }

  final InlineSpan inlineSpan;
  final TextEditingValue value;
  final Color? cursorColor;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final Color? backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool readOnly;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final StrutStyle? strutStyle;
  final Color? selectionColor;
  final double textScaleFactor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final String obscuringCharacter;
  final bool obscureText;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final ViewportOffset offset;
  final CaretChangedHandler? onCaretChanged;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Offset cursorOffset;
  final bool paintCursorAboveText;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final TextRange? promptRectRange;
  final Color? promptRectColor;
  final Clip clipBehavior;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return RenderEditable(
      text: inlineSpan,
      cursorColor: cursorColor,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      backgroundCursorColor: backgroundCursorColor,
      showCursor: showCursor,
      forceLine: forceLine,
      readOnly: readOnly,
      hasFocus: hasFocus,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      strutStyle: strutStyle,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      selection: value.selection,
      offset: offset,
      onCaretChanged: onCaretChanged,
      ignorePointer: rendererIgnoresPointer,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOffset: cursorOffset,
      paintCursorAboveText: paintCursorAboveText,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
      devicePixelRatio: devicePixelRatio,
      promptRectRange: promptRectRange,
      promptRectColor: promptRectColor,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditable renderObject) {
    renderObject
      ..text = inlineSpan
      ..cursorColor = cursorColor
      ..startHandleLayerLink = startHandleLayerLink
      ..endHandleLayerLink = endHandleLayerLink
      ..showCursor = showCursor
      ..forceLine = forceLine
      ..readOnly = readOnly
      ..hasFocus = hasFocus
      ..maxLines = maxLines
      ..minLines = minLines
      ..expands = expands
      ..strutStyle = strutStyle
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..locale = locale ?? Localizations.maybeLocaleOf(context)
      ..selection = value.selection
      ..offset = offset
      ..onCaretChanged = onCaretChanged
      ..ignorePointer = rendererIgnoresPointer
      ..textHeightBehavior = textHeightBehavior
      ..textWidthBasis = textWidthBasis
      ..obscuringCharacter = obscuringCharacter
      ..obscureText = obscureText
      ..cursorWidth = cursorWidth
      ..cursorHeight = cursorHeight
      ..cursorRadius = cursorRadius
      ..cursorOffset = cursorOffset
      ..enableInteractiveSelection = enableInteractiveSelection
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..paintCursorAboveText = paintCursorAboveText
      ..promptRectColor = promptRectColor
      ..clipBehavior = clipBehavior
      ..setPromptRectRange(promptRectRange);
  }
}

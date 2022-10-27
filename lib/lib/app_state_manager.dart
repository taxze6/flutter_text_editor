import 'package:flutter/widgets.dart';

import 'app_state.dart';

//共享数据
class AppStateManager extends InheritedWidget {
  const AppStateManager({
    super.key,
    required super.child,
    required AppState state,
  }) : _appState = state;

  static AppStateManager of(BuildContext context) {
    final AppStateManager? result =
        context.dependOnInheritedWidgetOfExactType<AppStateManager>();
    assert(result != null, '没有找到AppStateManager');
    return result!;
  }

  final AppState _appState;

  AppState get appState => _appState;

  @override
  bool updateShouldNotify(AppStateManager oldWidget) {
    return appState != oldWidget.appState;
  }
}

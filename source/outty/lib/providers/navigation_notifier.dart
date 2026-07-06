import 'package:flutter/foundation.dart';

/// Simple notifier that drives the bottom navigation index in HomeScreen.
/// Using this avoids circular imports between HomeScreen and its child screens.
class NavigationNotifier extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void switchToIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void switchToMatches() => switchToIndex(1);
}

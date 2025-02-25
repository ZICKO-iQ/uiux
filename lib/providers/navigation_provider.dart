import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  bool get isOnHomePage => _selectedIndex == 0;

  Future<bool> onWillPop() async {
    if (!isOnHomePage) {
      setSelectedIndex(0);
      return false;
    }
    return true;
  }
}

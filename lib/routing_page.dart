import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/views/shared/navigation_bar.dart';
import 'package:uiux/views/cart/cart_screen.dart';
import 'package:uiux/views/category/category_list_screen.dart';
import 'package:uiux/views/product/product_list_screen.dart';
import 'package:uiux/views/auth/auth_screen.dart';
import 'package:uiux/views/profile/profile_screen.dart';
import 'providers/navigation_provider.dart';

class RoutePage extends StatefulWidget {
  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  // Each tab gets its own Navigator key to preserve its state
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Handle back button behavior
  Future<bool> _onWillPop() async {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isFirstRouteInCurrentTab =
        !await _navigatorKeys[navigationProvider.selectedIndex].currentState!.maybePop();
    if (isFirstRouteInCurrentTab) {
      return true; // Allow app to exit
    }
    return false; // Prevent app from exiting
  }

  // Handle bottom navigation bar taps
  void _onTabTapped(int index) {
  final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

  if (navigationProvider.selectedIndex == index) {
    // If already on the current tab, pop to the first screen
    _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
  } else {
    // Change the selected index to the tapped tab
    navigationProvider.setSelectedIndex(index);
  }
}

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(bottom: 65),
          child: IndexedStack(
            index: navigationProvider.selectedIndex,
            children: [
              Navigator(
                key: _navigatorKeys[0], // Navigator for Home Tab
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => HomePage(),
                  );
                },
              ),
              Navigator(
                key: _navigatorKeys[1], // Navigator for Category Tab
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => CategoryPage(),
                  );
                },
              ),
              Navigator(
                key: _navigatorKeys[2], // Navigator for Cart Tab
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => CartPage(),
                  );
                },
              ),
              Navigator(
                key: _navigatorKeys[3], // Navigator for Profile Tab
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  );
                },
              ),
              Navigator(
                key: _navigatorKeys[4],
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => LoginRoute(),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: navigationProvider.selectedIndex == 4
            ? null
            : CustomNavigationBar(
                selectedIndex: navigationProvider.selectedIndex,
                onTabTapped: _onTabTapped,
              ),
      ),
    );
  }
}

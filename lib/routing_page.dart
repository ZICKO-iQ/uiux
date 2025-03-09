import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uiux/views/shared/navigation_bar.dart';
import 'package:uiux/views/cart/cart_screen.dart';
import 'package:uiux/views/category/category_list_screen.dart';
import 'package:uiux/views/product/product_list_screen.dart';
import 'package:uiux/views/auth/auth_screen.dart';
import 'package:uiux/views/profile/profile_screen.dart';
import 'providers/navigation_provider.dart';

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class RoutePage extends StatefulWidget {
  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  DateTime? _lastPressedAt;

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
      // If we're not on the home tab (index 0), switch to it
      if (navigationProvider.selectedIndex != 0) {
        navigationProvider.setSelectedIndex(0);
        return false; // Prevent app from exiting
      } else {
        // If we're on home page, handle double press
        if (_lastPressedAt == null || 
            DateTime.now().difference(_lastPressedAt!) > Duration(seconds: 2)) {
          _lastPressedAt = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      }
    }
    
    return false; // Prevent app from exiting if we can pop the current route
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
              KeepAlivePage(
                child: Navigator(
                  key: _navigatorKeys[0],
                  onGenerateRoute: (routeSettings) {
                    return MaterialPageRoute(
                      builder: (context) => HomePage(),
                    );
                  },
                ),
              ),
              KeepAlivePage(
                child: Navigator(
                  key: _navigatorKeys[1],
                  onGenerateRoute: (routeSettings) {
                    return MaterialPageRoute(
                      builder: (context) => CategoryPage(),
                    );
                  },
                ),
              ),
              KeepAlivePage(
                child: Navigator(
                  key: _navigatorKeys[2],
                  onGenerateRoute: (routeSettings) {
                    return MaterialPageRoute(
                      builder: (context) => CartPage(),
                    );
                  },
                ),
              ),
              KeepAlivePage(
                child: Navigator(
                  key: _navigatorKeys[3],
                  onGenerateRoute: (routeSettings) {
                    return MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    );
                  },
                ),
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

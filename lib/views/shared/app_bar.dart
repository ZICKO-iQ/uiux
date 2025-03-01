import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../search/search_screen.dart';
import '../../providers/search_provider.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onSearchTap;
  final Function()? onFilterTap;
  final bool showBackButton;  // Add this parameter

  const CustomAppBar({
    super.key, 
    required this.title,
    this.onSearchTap,
    this.onFilterTap,
    this.showBackButton = true,  // Default to true
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
  }
  
  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _focusNode.requestFocus();
      } else {
        _searchController.clear();
        _removeOverlay();
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionTile(String suggestion) {
    final isCategory = suggestion.startsWith('Category: ');
    final isBrand = suggestion.startsWith('Brand: ');
    
    return ListTile(
      leading: Icon(
        isCategory ? Icons.category :
        isBrand ? Icons.branding_watermark :
        Icons.search,
      ),
      title: Text(suggestion),
      onTap: () {
        final query = isCategory || isBrand ? 
            suggestion.split(': ')[1] : suggestion;
        _searchController.text = query;
        _removeOverlay();
        _onSearchSubmitted(query);
      },
    );
  }

  void _showSuggestions() {
    _removeOverlay();
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + size.height,
        left: offset.dx,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, _) {
              if (!_isSearching || _searchController.text.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (searchProvider.suggestions.isNotEmpty)
                        ...searchProvider.suggestions.map((suggestion) => 
                          _buildSuggestionTile(suggestion)
                        ).toList()
                      else if (!searchProvider.isLoading)
                        const ListTile(
                          title: Text('No suggestions found'),
                        ),
                      if (searchProvider.isLoading)
                        const ListTile(
                          title: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _removeOverlay();
      _toggleSearch();
      
      Provider.of<SearchProvider>(context, listen: false).clearSearch();
      
      // Check if we're already on a search screen
      Navigator.of(context).popUntil((route) {
        if (route.settings.name == 'search') {
          return false;
        }
        return true;
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'search'),
          builder: (context) => SearchScreen(
            searchQuery: query,
          ),
        ),
      );
    }
  }

  bool _isRootRoute(BuildContext context) {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final isFirstRoute = !Navigator.canPop(context);
    final isNamedRoot = route?.settings.name == 'product_list' || 
                       route?.settings.name == 'home';
    return isFirstRoute || isNamedRoot;
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _isRootRoute(context);
    
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: (!isRoot) ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ) : null,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              const Color.fromARGB(255, 31, 139, 24),
            ],
          ),
        ),
      ),
      title: Padding(
        padding: EdgeInsets.only(left: Navigator.canPop(context) ? 0 : 16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<SearchProvider>().getSuggestions(value);
                    _showSuggestions();
                  } else {
                    _removeOverlay();
                  }
                },
                onSubmitted: _onSearchSubmitted,
              )
            : Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1.2,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(60, 0, 0, 0),
                    ),
                  ],
                ),
              ),
        ),
      ),
      actions: [
        if (widget.onSearchTap != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _toggleSearch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      _isSearching ? Icons.close : Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.onFilterTap != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onFilterTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }
}

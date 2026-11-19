import 'package:flutter/material.dart';

/// Navigation item descriptor used by [GFAdaptiveNav].
class GFNavItem {
  const GFNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Default GroundFlow navigation items.
const List<GFNavItem> kDefaultNavItems = [
  GFNavItem(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  GFNavItem(
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today_rounded,
    label: 'Schedule',
  ),
  GFNavItem(
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    label: 'Chat',
  ),
  GFNavItem(
    icon: Icons.camera_alt_outlined,
    selectedIcon: Icons.camera_alt_rounded,
    label: 'Gear',
  ),
  GFNavItem(
    icon: Icons.more_horiz_rounded,
    selectedIcon: Icons.more_horiz_rounded,
    label: 'More',
  ),
];

/// Adaptive navigation bar that renders a [BottomNavigationBar] on mobile /
/// portrait tablet, and a [NavigationRail] on landscape tablet and desktop.
///
/// Wrap your scaffold body with this widget as a [Row] child or use it inside
/// a [Scaffold]'s bottomNavigationBar / drawer slots as appropriate.
///
/// ```dart
/// GFAdaptiveNav(
///   currentIndex: _selectedIndex,
///   onDestinationSelected: (i) => setState(() => _selectedIndex = i),
///   body: _pages[_selectedIndex],
/// )
/// ```
class GFAdaptiveNav extends StatelessWidget {
  const GFAdaptiveNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    this.items = kDefaultNavItems,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<GFNavItem> items;

  /// Width < 600 px → mobile.
  /// Width 600–1024 px + portrait → mobile bar; landscape → rail.
  /// Width > 1024 px → rail.
  bool _useRail(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    if (width >= 1024) return true;
    if (width >= 600 && isLandscape) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_useRail(context)) {
      return _RailLayout(
        items: items,
        currentIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        body: body,
      );
    }
    return _BottomBarLayout(
      items: items,
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar variant
// ---------------------------------------------------------------------------

class _BottomBarLayout extends StatelessWidget {
  const _BottomBarLayout({
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final List<GFNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        indicatorColor: colorScheme.primaryContainer,
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation rail variant
// ---------------------------------------------------------------------------

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.items,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final List<GFNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer,
            destinations: items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

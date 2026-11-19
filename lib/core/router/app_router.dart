import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/events/event_dashboard_screen.dart';
import '../../features/control_room/control_room_screen.dart';
import '../../features/tasks_shoots/tasks_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/assets_gear/gear_screen.dart';
import '../../features/pipeline/pipeline_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/issues/issues_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/profile/profile_screen.dart';

// ── Route path constants ───────────────────────────────────────────────────────

abstract class AppRoutes {
  static const String splash       = '/splash';
  static const String login        = '/auth/login';
  static const String register     = '/auth/register';
  static const String home         = '/';
  static const String profile      = '/profile';

  // Event sub-routes
  static const String event        = '/events/:eventId';
  static const String controlRoom  = '/events/:eventId/control-room';
  static const String tasks        = '/events/:eventId/tasks';
  static const String attendance   = '/events/:eventId/attendance';
  static const String gear         = '/events/:eventId/gear';
  static const String pipeline     = '/events/:eventId/pipeline';
  static const String chat         = '/events/:eventId/chat';
  static const String issues       = '/events/:eventId/issues';
  static const String reports      = '/events/:eventId/reports';

  static String eventDashboard(String eventId)   => '/events/$eventId';
  static String eventControlRoom(String eventId)  => '/events/$eventId/control-room';
  static String eventTasks(String eventId)        => '/events/$eventId/tasks';
  static String eventAttendance(String eventId)   => '/events/$eventId/attendance';
  static String eventGear(String eventId)         => '/events/$eventId/gear';
  static String eventPipeline(String eventId)     => '/events/$eventId/pipeline';
  static String eventChat(String eventId)         => '/events/$eventId/chat';
  static String eventIssues(String eventId)       => '/events/$eventId/issues';
  static String eventReports(String eventId)      => '/events/$eventId/reports';
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends ChangeNotifier {
  bool _isAuthenticated = true; // Default to true so user immediately sees GroundFlow interface

  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void signIn()  => setAuthenticated(true);
  void signOut() => setAuthenticated(false);
}

// ── Shell scaffold (bottom nav / nav rail) ─────────────────────────────────────

class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  static const _destinations = [
    _NavDestination(icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard_rounded,     label: 'Events'),
    _NavDestination(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month,      label: 'Schedule'),
    _NavDestination(icon: Icons.radar_outlined,         activeIcon: Icons.radar_rounded,        label: 'Control'),
    _NavDestination(icon: Icons.chat_bubble_outline,   activeIcon: Icons.chat_bubble_rounded,   label: 'Chat'),
    _NavDestination(icon: Icons.person_outline,        activeIcon: Icons.person_rounded,        label: 'Profile'),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  bool _isWideScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700;

  @override
  Widget build(BuildContext context) {
    final wide = _isWideScreen(context);
    final currentIndex = navigationShell.currentIndex;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: _onDestinationSelected,
              extended: MediaQuery.sizeOf(context).width >= 1000,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hub_rounded, color: Color(0xFF3D5AFE), size: 28),
                    SizedBox(width: 8),
                    Text('GroundFlow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onDestinationSelected,
        type: BottomNavigationBarType.fixed,
        items: _destinations.map((d) {
          return BottomNavigationBarItem(
            icon: Icon(d.icon),
            activeIcon: Icon(d.activeIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDestination({required this.icon, required this.activeIcon, required this.label});
}

// ── Router factory ─────────────────────────────────────────────────────────────

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,

    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authNotifier.isAuthenticated;
      final location = state.matchedLocation;
      final isOnAuth = location.startsWith('/auth') || location == AppRoutes.splash;

      if (!isAuth && !isOnAuth) {
        return AppRoutes.login;
      }
      if (isAuth && isOnAuth && location != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },

    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell (bottom nav / rail)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(navigationShell: shell),
        branches: [
          // Branch 0 — Home / Events Overview
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1 — Schedule / Shoots
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks-tab',
                name: 'tasksTab',
                builder: (context, state) => const TasksScreen(eventId: 'bcs-2026'),
              ),
            ],
          ),

          // Branch 2 — Control Room Live Radar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/control-room-tab',
                name: 'controlRoomTab',
                builder: (context, state) => const ControlRoomScreen(eventId: 'bcs-2026'),
              ),
            ],
          ),

          // Branch 3 — Chat & Communication Channels
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat-tab',
                name: 'chatTab',
                builder: (context, state) => const ChatScreen(eventId: 'bcs-2026'),
              ),
            ],
          ),

          // Branch 4 — Profile & Data Usage
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Event Sub-routes (deep-linked from tiles or cards)
      GoRoute(
        path: AppRoutes.event,
        name: 'eventDashboard',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? 'bcs-2026';
          return EventDashboardScreen(eventId: eventId);
        },
        routes: [
          GoRoute(
            path: 'control-room',
            name: 'controlRoom',
            builder: (context, state) => ControlRoomScreen(eventId: state.pathParameters['eventId']),
          ),
          GoRoute(
            path: 'tasks',
            name: 'tasks',
            builder: (context, state) => TasksScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
          GoRoute(
            path: 'attendance',
            name: 'attendance',
            builder: (context, state) => AttendanceScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
          GoRoute(
            path: 'gear',
            name: 'gear',
            builder: (context, state) => GearScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
          GoRoute(
            path: 'pipeline',
            name: 'pipeline',
            builder: (context, state) => PipelineScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
          GoRoute(
            path: 'chat',
            name: 'chat',
            builder: (context, state) => ChatScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
          GoRoute(
            path: 'issues',
            name: 'issues',
            builder: (context, state) => IssuesScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => ReportsScreen(eventId: state.pathParameters['eventId'] ?? 'bcs-2026'),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown route'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

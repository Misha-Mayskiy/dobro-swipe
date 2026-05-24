import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/volunteer/feed_screen.dart';
import 'presentation/foundation/dashboard_screen.dart';

void main() {
  runApp(const ProviderScope(child: DobroSwipeApp()));
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/volunteer/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/foundation/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});

class DobroSwipeApp extends ConsumerWidget {
  const DobroSwipeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'ДоброСвайп',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto toggle based on system
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

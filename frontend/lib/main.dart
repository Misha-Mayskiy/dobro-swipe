import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/volunteer/feed_screen.dart';
import 'presentation/volunteer/active_task_screen.dart';
import 'presentation/volunteer/profile_screen.dart';
import 'presentation/foundation/dashboard_screen.dart';
import 'presentation/foundation/create_task_screen.dart';
import 'presentation/foundation/review_screen.dart';
import 'data/models.dart';

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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/volunteer/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/volunteer/active',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ActiveTaskScreen(
            task: extra['task'] as Task,
            assignmentId: extra['assignmentId'] as int,
          );
        },
      ),
      GoRoute(
        path: '/volunteer/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/foundation/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/foundation/create_task',
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: '/foundation/review',
        builder: (context, state) => ReviewScreen(taskData: state.extra),
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

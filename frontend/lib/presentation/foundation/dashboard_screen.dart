import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд Фонда'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: dashboardState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: dashboardState.dashboardTasks.length,
                itemBuilder: (context, index) {
                  final task = dashboardState.dashboardTasks[index];
                  int activeAssignments = 0;
                  int underReview = 0;
                  
                  for (var a in task['assignments']) {
                    if (a['status'] == 'in_progress') activeAssignments++;
                    if (a['status'] == 'under_review') underReview++;
                  }

                  String statusText = '';
                  Color statusColor = Colors.grey;
                  
                  if (underReview > 0) {
                    statusText = '$underReview на проверке';
                    statusColor = Colors.blue;
                  } else if (activeAssignments > 0) {
                    statusText = '$activeAssignments в процессе';
                    statusColor = Colors.orange;
                  } else if (task['status'] == 'completed') {
                    statusText = 'Завершено';
                    statusColor = Colors.green;
                  } else {
                    statusText = 'Ожидает волонтеров';
                    statusColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildTaskRow(context, task['title'], statusText, statusColor, task),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/foundation/create_task'),
        label: const Text('Создать задачу'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, String title, String status, Color statusColor, dynamic task) {
    return InkWell(
      onTap: () {
        context.push('/foundation/review', extra: task);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(status, style: TextStyle(color: statusColor, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

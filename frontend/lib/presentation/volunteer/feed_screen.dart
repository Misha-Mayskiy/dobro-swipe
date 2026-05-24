import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_provider.dart';
import '../../providers/active_task_provider.dart';
import '../../data/models.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();

  Widget _buildActiveTaskBanner(TaskAssignment assignment) {
    final task = assignment.task;
    if (task == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.15),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.run_circle_outlined, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Активная задача в процессе:',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/volunteer/active', extra: {
                'task': task,
                'assignmentId': assignment.id,
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Продолжить', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final activeTaskState = ref.watch(activeTaskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента задач'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/volunteer/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (activeTaskState.assignment != null)
              _buildActiveTaskBanner(activeTaskState.assignment!),
            Expanded(
              child: feedState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : feedState.tasks.isEmpty
                      ? const Center(child: Text('Нет новых задач'))
                      : Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: AppinioSwiper(
                                  controller: controller,
                                  cardCount: feedState.tasks.length,
                                  onSwipeEnd: (previousIndex, targetIndex, activity) async {
                                    final task = feedState.tasks[previousIndex];
                                    if (activity.direction == AxisDirection.right) {
                                      final assignmentId = await ref.read(feedProvider.notifier).swipeRight(task.id);
                                      if (assignmentId != null) {
                                        ref.read(activeTaskProvider.notifier).fetchActiveAssignment();
                                        if (mounted) {
                                          context.push('/volunteer/active', extra: {
                                            'task': task,
                                            'assignmentId': assignmentId,
                                          });
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('У вас уже есть активная задача или задача недоступна!')),
                                          );
                                          ref.read(feedProvider.notifier).fetchFeed();
                                        }
                                      }
                                    } else if (activity.direction == AxisDirection.left) {
                                      await ref.read(feedProvider.notifier).swipeLeft(task.id);
                                    }
                                  },
                                  cardBuilder: (BuildContext context, int index) {
                                    return _buildCard(feedState.tasks[index]);
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  FloatingActionButton(
                                    heroTag: 'left',
                                    onPressed: () => controller.swipeLeft(),
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.close, color: Colors.red, size: 30),
                                  ),
                                  FloatingActionButton(
                                    heroTag: 'right',
                                    onPressed: () => controller.swipeRight(),
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.favorite, color: Colors.green, size: 30),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Task task) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                color: Colors.grey[300],
                width: double.infinity,
                child: const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChip(Icons.timer, '${task.durationMinutes} мин'),
                    if (task.city != null) _buildChip(Icons.location_on, task.city!),
                    _buildChip(Icons.star, '+${task.karmaReward} кармы'),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

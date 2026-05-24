import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_provider.dart';
import '../../data/models.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

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
                                final success = await ref.read(feedProvider.notifier).swipeRight(task.id);
                                if (success && mounted) {
                                  context.push('/volunteer/active', extra: task);
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

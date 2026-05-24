import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();
  
  // Mock data
  final List<Map<String, dynamic>> tasks = [
    {
      'title': 'Собрать мусор на пляже',
      'foundation': 'ЭкоСириус',
      'karma': 50,
      'duration': '30 мин',
      'distance': '1.2 км',
      'image': 'https://via.placeholder.com/400x300',
    },
    {
      'title': 'Отвезти продукты пенсионеру',
      'foundation': 'Доброе Дело',
      'karma': 100,
      'duration': '45 мин',
      'distance': '3.5 км',
      'image': 'https://via.placeholder.com/400x300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента задач'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: AppinioSwiper(
                  controller: controller,
                  cardCount: tasks.length,
                  onSwipeBegin: (previousIndex, previousDirection, customSwipeEvent) {},
                  onSwipeEnd: (previousIndex, targetIndex, activity) {
                    // activity.direction == AxisDirection.right -> take task
                  },
                  cardBuilder: (BuildContext context, int index) {
                    final task = tasks[index];
                    return _buildCard(task);
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

  Widget _buildCard(Map<String, dynamic> task) {
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
                color: Colors.grey[300], // Placeholder for image
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
                  task['title'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(task['foundation'], style: TextStyle(color: Theme.of(context).primaryColor)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildChip(Icons.timer, task['duration']),
                    _buildChip(Icons.location_on, task['distance']),
                    _buildChip(Icons.star, '+${task['karma']} кармы'),
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

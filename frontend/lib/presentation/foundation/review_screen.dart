import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final dynamic taskData;

  const ReviewScreen({Key? key, required this.taskData}) : super(key: key);

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _review(int assignmentId, bool approve) async {
    setState(() => _isSubmitting = true);
    final success = await ref.read(dashboardProvider.notifier).reviewAssignment(
      assignmentId, 
      approve, 
      _commentController.text.isNotEmpty ? _commentController.text : null,
    );
    setState(() => _isSubmitting = false);
    
    if (success && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find assignment under review
    List<dynamic> assignments = widget.taskData['assignments'] ?? [];
    var underReview = assignments.where((a) => a['status'] == 'under_review').toList();
    
    if (underReview.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Отчеты')),
        body: const Center(child: Text('Нет отчетов для проверки')),
      );
    }

    final assignment = underReview.first;
    final resultText = assignment['result_text'] ?? '';
    final imageUrlMatch = RegExp(r'\[Image: (.*?)\]').firstMatch(resultText);
    String? imageUrl = imageUrlMatch != null ? imageUrlMatch.group(1) : null;
    String textOnly = resultText.replaceAll(RegExp(r'\n?\[Image: .*?\]'), '');

    return Scaffold(
      appBar: AppBar(title: const Text('Проверка отчета')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.taskData['title'], style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Текст отчета:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(textOnly.isEmpty ? 'Без текста' : textOnly),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (imageUrl != null) ...[
                const Text('Прикрепленное фото:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Комментарий (обязателен при отклонении)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => _review(assignment['id'], false),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Отклонить'),
                    ),
                    ElevatedButton(
                      onPressed: () => _review(assignment['id'], true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Принять'),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}

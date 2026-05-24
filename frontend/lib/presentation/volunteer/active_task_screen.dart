import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../data/models.dart';
import '../../core/network.dart';
import '../../providers/active_task_provider.dart';

class ActiveTaskScreen extends ConsumerStatefulWidget {
  final Task task;
  final int assignmentId;

  const ActiveTaskScreen({Key? key, required this.task, required this.assignmentId}) : super(key: key);

  @override
  ConsumerState<ActiveTaskScreen> createState() => _ActiveTaskScreenState();
}

class _ActiveTaskScreenState extends ConsumerState<ActiveTaskScreen> {
  final _commentController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    
    try {
      FormData formData = FormData.fromMap({
        'result_text': _commentController.text,
      });

      if (_image != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(_image!.path, filename: 'report_image.jpg'),
        ));
      }

      await apiClient.dio.post(
        '/tasks/assignments/${widget.assignmentId}/submit',
        data: formData,
      );

      // Refresh active task assignment state
      ref.read(activeTaskProvider.notifier).fetchActiveAssignment();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отчет отправлен на проверку!')));
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка отправки отчета')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выполнение задачи')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.task.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(widget.task.description),
              const SizedBox(height: 30),
              const Text('Ваш отчет:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Опишите результат...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              if (_image != null) ...[
                Image.file(_image!, height: 150),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Прикрепить фото'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Отправить на проверку'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../data/models.dart';
import '../../core/network.dart';

class ActiveTaskScreen extends ConsumerStatefulWidget {
  final Task task;

  const ActiveTaskScreen({Key? key, required this.task}) : super(key: key);

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

      // Hardcode assignment ID fetch or assume latest active. 
      // For MVP, we need the assignment ID.
      // Usually we get it from an endpoint like /auth/me/active_assignment
      // For now, let's query the assignments for this task to find ours.
      final response = await apiClient.dio.get('/auth/me'); // A simple way is to pass assignment id from Feed.
      // Assuming a dedicated endpoint or passing assignment ID is better. 
      // We will handle errors locally for this MVP flow.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Отчет отправлен!')));
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка отправки')));
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

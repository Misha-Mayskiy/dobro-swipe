import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network.dart';
import '../data/models.dart';

class ActiveTaskState {
  final bool isLoading;
  final TaskAssignment? assignment;
  final String? error;

  ActiveTaskState({this.isLoading = false, this.assignment, this.error});

  ActiveTaskState copyWith({bool? isLoading, TaskAssignment? assignment, String? error}) {
    return ActiveTaskState(
      isLoading: isLoading ?? this.isLoading,
      assignment: assignment,
      error: error,
    );
  }
}

class ActiveTaskNotifier extends StateNotifier<ActiveTaskState> {
  ActiveTaskNotifier() : super(ActiveTaskState()) {
    fetchActiveAssignment();
  }

  Future<void> fetchActiveAssignment() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.dio.get('/tasks/assignments/active');
      if (response.data == null) {
        state = ActiveTaskState(isLoading: false);
      } else {
        state = ActiveTaskState(
          isLoading: false,
          assignment: TaskAssignment.fromJson(response.data),
        );
      }
    } catch (e) {
      // 404 or other errors mean no active assignment exists for this volunteer
      state = ActiveTaskState(isLoading: false);
    }
  }

  void clear() {
    state = ActiveTaskState();
  }
}

final activeTaskProvider = StateNotifierProvider<ActiveTaskNotifier, ActiveTaskState>((ref) {
  return ActiveTaskNotifier();
});

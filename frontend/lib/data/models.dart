class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final int karmaBalance;
  final int level;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.karmaBalance,
    required this.level,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      karmaBalance: json['karma_balance'] ?? 0,
      level: json['level'] ?? 1,
    );
  }
}

class Task {
  final int id;
  final int foundationId;
  final String title;
  final String description;
  final int durationMinutes;
  final int karmaReward;
  final String status;
  final String? city;

  Task({
    required this.id,
    required this.foundationId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.karmaReward,
    required this.status,
    this.city,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      foundationId: json['foundation_id'],
      title: json['title'],
      description: json['description'],
      durationMinutes: json['duration_minutes'],
      karmaReward: json['karma_reward'],
      status: json['status'],
      city: json['city'],
    );
  }
}

class TaskAssignment {
  final int id;
  final int taskId;
  final int volunteerId;
  final String status;
  final Task? task; // For nested responses

  TaskAssignment({
    required this.id,
    required this.taskId,
    required this.volunteerId,
    required this.status,
    this.task,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      id: json['id'],
      taskId: json['task_id'],
      volunteerId: json['volunteer_id'],
      status: json['status'],
      task: json['task'] != null ? Task.fromJson(json['task']) : null,
    );
  }
}

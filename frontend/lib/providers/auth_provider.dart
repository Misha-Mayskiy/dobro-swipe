import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network.dart';
import '../data/models.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({this.isLoading = false, this.user, this.error});

  AuthState copyWith({bool? isLoading, User? user, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('access_token') != null) {
      try {
        final response = await apiClient.dio.get('/auth/me');
        state = state.copyWith(user: User.fromJson(response.data));
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {'username': email, 'password': password},
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      
      final userResponse = await apiClient.dio.get('/auth/me');
      state = state.copyWith(isLoading: false, user: User.fromJson(userResponse.data));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ошибка входа');
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      });
      return await login(email, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ошибка регистрации');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    state = AuthState();
  }
}

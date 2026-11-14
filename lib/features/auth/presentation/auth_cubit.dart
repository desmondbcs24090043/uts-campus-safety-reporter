import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  
  // 这里把初始状态从 AuthInitial 改为 AuthUnauthenticated，直接显示登录页
  AuthCubit(this.repository) : super(const AuthUnauthenticated()); 

  Future<void> signUp(String email, String password) async {
    emit(const AuthLoading());
    try {
      await repository.signUp(email: email, password: password);
      emit(const AuthUnauthenticated(message: 'Registration successful. Please login.'));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      final role = await repository.signIn(email: email, password: password);
      emit(AuthAuthenticated(role: role)); 
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    await repository.signOut();
    emit(const AuthUnauthenticated()); 
  }
}
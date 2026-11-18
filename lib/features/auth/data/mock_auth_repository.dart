import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> signUp({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
    if (email == 'exists@test.com') {
      throw Exception('Email already registered');
    }
    // 注册成功
  }

  @override
  Future<String> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password == 'wrong') {
      throw Exception('Invalid login credentials');
    }
    // 如果邮箱包含 admin 则作为管理员登录，否则作为学生登录
    if (email.contains('admin')) {
      return 'admin';
    }
    return 'student';
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
abstract class AuthRepository {
  Future<void> signUp({required String email, required String password});
  // 登录成功返回角色（student 或 admin）
  Future<String> signIn({required String email, required String password});
  Future<void> signOut();
}
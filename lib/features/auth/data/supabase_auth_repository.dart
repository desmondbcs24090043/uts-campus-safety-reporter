import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      // 调用真实的 Supabase 注册
      await supabase.auth.signUp(
        email: email,
        password: password,
      );
      // 注意：注册成功后，如何向 profiles 表插入 role='student' 的数据？
      // 这个通常由 Member 4 在数据库中配置 Trigger（触发器）自动完成。
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during registration');
    }
  }

  @override
  Future<String> signIn({required String email, required String password}) async {
    try {
      // 调用真实的 Supabase 登录
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('User not found');
      }

      // 登录成功后，从 profiles 表查询该用户的角色 (role)
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', response.user!.id)
          .single();

      return profile['role'] as String;
      
    } on AuthException catch (e) {
      // 捕获真实的密码错误、账号未确认等错误
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      // 捕获数据库查询错误（比如 profiles 表不存在）
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
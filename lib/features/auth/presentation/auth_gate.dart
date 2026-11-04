import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // 加载中
        if (state is AuthLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // 已经登录，根据角色显示不同页面
        if (state is AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(title: const Text('Campus Safety')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Logged in as: ${state.role.toUpperCase()}', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<AuthCubit>().signOut(),
                    child: const Text('Logout'),
                  )
                ],
              ),
            ),
          );
        }
        
        // 未登录显示登录页
        return const LoginPage();
      },
    );
  }
}
import 'dart:ui';
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
        if (state is AuthLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B192C),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00A9FF))),
          );
        }
        
        // 已登录：显示精美 Dashboard
        if (state is AuthAuthenticated) {
          return _DashboardPage(role: state.role);
        }
        
        // 未登录
        return const LoginPage();
      },
    );
  }
}

// ==========================================
// 登录成功后的 Dashboard 页面
// ==========================================
class _DashboardPage extends StatelessWidget {
  final String role;
  const _DashboardPage({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0B192C),
      body: Stack(
        children: [
          // 背景光晕
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A9FF).withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00A9FF).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7A00E6).withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7A00E6).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50)
                ],
              ),
            ),
          ),

          // 主内容 (使用 SingleChildScrollView 防止内容溢出屏幕)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部导航栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          Text(
                            isAdmin ? 'Administrator' : 'Student',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      // 登出按钮
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        onPressed: () => context.read<AuthCubit>().signOut(),
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 状态卡片 (玻璃拟态)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF00A9FF), size: 50),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('System Secure', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAdmin ? 'Manage incoming reports' : 'Your reports are protected',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 功能模块标题
                  const Text(
                    'Quick Actions',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 20),
                  
                  // 使用 Row + Expanded 替代 GridView，完美适配宽屏和手机，不会出现溢出
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: isAdmin ? Icons.assignment_rounded : Icons.add_alert_rounded,
                          title: isAdmin ? 'All Reports' : 'Report Issue',
                          subtitle: isAdmin ? 'View pending' : 'Submit new',
                          color: const Color(0xFF00A9FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionCard(
                          icon: isAdmin ? Icons.people_rounded : Icons.history_rounded,
                          title: isAdmin ? 'Manage Users' : 'My Reports',
                          subtitle: isAdmin ? 'Student profiles' : 'Track status',
                          color: const Color(0xFF7A00E6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 单独抽离的“快捷操作”卡片组件
// ==========================================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.03),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title coming soon!'), behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              height: 160, // 固定高度，防止内容撑破布局
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const Spacer(),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
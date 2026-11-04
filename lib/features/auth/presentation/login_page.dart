import 'dart:ui'; // 引入模糊效果
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signIn(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B192C), // 极夜深蓝背景
      body: Stack(
        children: [
          // 背景装饰光晕 1 (左上角青色)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A9FF).withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A9FF).withValues(alpha: 0.3),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          // 背景装饰光晕 2 (右下角紫色)
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7A00E6).withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7A00E6).withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          
          // 主内容区域
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                      );
                    }
                    if (state is AuthUnauthenticated && state.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message!), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 动画呼吸 Logo
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.95, end: 1.05),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          builder: (context, double scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A9FF).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00A9FF).withValues(alpha: 0.5), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A9FF).withValues(alpha: 0.2),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.shield_rounded, size: 80, color: Color(0xFF00A9FF)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'SECURE CAMPUS',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4.0),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Next-Gen Incident Reporting System',
                          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6), letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 50),

                        // 玻璃拟态 (Glassmorphism) 悬浮卡片
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 模糊效果
                            child: Container(
                              padding: const EdgeInsets.all(28.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05), // 极淡的白色
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00A9FF)),
                                        filled: true,
                                        fillColor: Colors.black.withValues(alpha: 0.2), // 深色输入框
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFF00A9FF), width: 2),
                                        ),
                                      ),
                                      validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _password,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00A9FF)),
                                        filled: true,
                                        fillColor: Colors.black.withValues(alpha: 0.2),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFF00A9FF), width: 2),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white.withValues(alpha: 0.5)),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.length < 6 ? 'Password min 6 chars' : null,
                                    ),
                                    const SizedBox(height: 32),
                                    // 霓虹发光按钮
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00A9FF),
                                          foregroundColor: Colors.white,
                                          elevation: 8,
                                          shadowColor: const Color(0xFF00A9FF).withValues(alpha: 0.6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        onPressed: loading ? null : _submit,
                                        child: loading
                                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Text('SECURE LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: loading ? null : () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "New student? ",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                              children: const [
                                TextSpan(
                                  text: 'Create an account',
                                  style: TextStyle(color: Color(0xFF00A9FF), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
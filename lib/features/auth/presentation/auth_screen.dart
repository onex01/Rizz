import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart'; // для FirebaseAuthException
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';

import '../../../core/logger/app_logger.dart';
import '../../../shared/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _authService = GetIt.I<AuthService>();
  final _logger = GetIt.I<AppLogger>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          Fluttertoast.showToast(msg: "Вход выполнен успешно!", gravity: ToastGravity.BOTTOM);
        }
      } else {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Аккаунт создан! Подтвердите email",
            gravity: ToastGravity.BOTTOM,
            toastLength: Toast.LENGTH_LONG,
          );
          await _authService.signOut();

          setState(() {
            isLogin = true;
            _emailController.clear();
            _passwordController.clear();
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Ошибка авторизации";
      switch (e.code) {
        case 'email-already-in-use': msg = "Этот email уже используется"; break;
        case 'weak-password': msg = "Слишком слабый пароль (минимум 6 символов)"; break;
        case 'user-not-found': msg = "Пользователь не найден"; break;
        case 'wrong-password': msg = "Неверный пароль"; break;
        case 'invalid-email': msg = "Неверный формат email"; break;
        case 'user-disabled': msg = "Аккаунт отключен"; break;
        case 'too-many-requests': msg = "Слишком много попыток. Попробуйте позже"; break;
      }
      if (mounted) {
        Fluttertoast.showToast(
          msg: msg,
          backgroundColor: Colors.red,
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e, stack) {
      _logger.error('Auth error', error: e, stack: stack);
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Произошла ошибка: ${e.toString().split('\n').first}",
          backgroundColor: Colors.red,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Fluttertoast.showToast(
          msg: "Вход через Google выполнен успешно!",
          gravity: ToastGravity.BOTTOM,
        );
      } else if (mounted) {
        Fluttertoast.showToast(
          msg: "Не удалось войти через Google",
          backgroundColor: Colors.red,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e, stack) {
      _logger.error('Google sign in error', error: e, stack: stack);
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Ошибка входа через Google",
          backgroundColor: Colors.red,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? Colors.grey.shade50 : const Color(0xFF0F0F0F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Анимированная иконка
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      isLogin ? 'Добро пожаловать!' : 'Создать аккаунт',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin ? 'Войдите чтобы продолжить' : 'Зарегистрируйтесь чтобы начать общение',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Поле Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: isLight ? Colors.grey[700] : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isLight ? Colors.grey[700] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isLight ? Colors.white : Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isLight ? Colors.grey[300]! : Colors.grey[700]!,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите email';
                        if (!EmailValidator.validate(value)) return 'Неверный формат email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Поле Пароль
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        labelStyle: TextStyle(
                          color: isLight ? Colors.grey[700] : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isLight ? Colors.grey[700] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isLight ? Colors.white : Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isLight ? Colors.grey[300]! : Colors.grey[700]!,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите пароль';
                        if (value.length < 6) return 'Пароль должен содержать минимум 6 символов';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Кнопка входа / регистрации
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(isLogin ? 'Войти' : 'Зарегистрироваться', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                          _formKey.currentState?.reset();
                        });
                      },
                      child: Text(
                        isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',
                        style: TextStyle(fontSize: 14, color: Colors.blue[300]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    // Google
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Продолжить с Google'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isLight ? Colors.grey[300]! : Colors.grey[700]!),
                          foregroundColor: isLight ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
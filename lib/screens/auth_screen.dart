import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: '931475441186-h5gh1fo9hn6v3e2cddj2dq689m624qpd.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen(_handleGoogleSignIn);
  }

  Future<void> _handleGoogleSignIn(GoogleSignInAccount? account) async {
    if (account == null) return;

    setState(() => _isLoading = true);

    try {
      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Создаём профиль пользователя автоматически
      await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'nickname': firebaseUser.email!.split('@')[0].toLowerCase(), // временный ник
        'photoUrl': firebaseUser.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "Добро пожаловать!", backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: "Ошибка Google: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      Fluttertoast.showToast(msg: "Не удалось открыть Google", backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await cred.user!.sendEmailVerification();
        Fluttertoast.showToast(msg: "Аккаунт создан! Подтвердите email");
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Ошибка";
      if (e.code == 'email-already-in-use') msg = "Этот email уже используется";
      if (e.code == 'weak-password') msg = "Слишком слабый пароль";
      Fluttertoast.showToast(msg: msg, backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 90, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  isLogin ? 'Вход в ChatiX' : 'Регистрация в ChatiX',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => EmailValidator.validate(v ?? '') ? null : 'Неверный email',
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v != null && v.length >= 6) ? null : 'Минимум 6 символов',
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
                  ),
                ),

                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin
                      ? 'Нет аккаунта? Зарегистрироваться'
                      : 'Уже есть аккаунт? Войти'),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Войти через Google'),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
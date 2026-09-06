import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapmenu/core/network/api_client.dart';
import '../../core/network/database_service.dart'; // Або: import 'package:mapmenu/core/network/database_service.dart';
import '../contribution/contribution_screen.dart';
class AuthScreen extends StatefulWidget {
  final LatLng currentCenter;

  const AuthScreen({super.key, required this.currentCenter});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true; // Режим входу або реєстрації

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заповніть всі поля!')),
      );
      return;
    }

    if (_isLoginMode) {
      // Логіка входу
      final success = await DatabaseService.instance.loginUser(email, password);
      if (success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ContributionScreen(initialCenter: widget.currentCenter),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Невірний email або пароль! (Спробуйте test@mapmenu.com / password123)')),
          );
        }
      }
    } else {
      // Логіка реєстрації
      try {
        await DatabaseService.instance.registerUser(email, password);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Реєстрація успішна'),
              content: const Text('Ми відправили лист для верифікації на вашу пошту. Проте для тесту ви вже можете увійти.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isLoginMode = true);
                  },
                  child: const Text('Увійти'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Користувач з такою поштою вже існує!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Вхід у систему' : 'Реєстрація')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: _submit,
                child: Text(_isLoginMode ? 'Увійти' : 'Зареєструватися'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode ? 'Немає акаунта? Зареєструватися' : 'Вже є акаунт? Увійти'),
            ),
          ],
        ),
      ),
    );
  }
}
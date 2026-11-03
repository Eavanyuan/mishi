import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSending = false;
  bool _isResetting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty && _tokenController.text.isEmpty) {
      _tokenController.text = token;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnackBar('请输入有效邮箱');
      return;
    }

    setState(() {
      _isSending = true;
    });
    final error = await ref.read(authProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    setState(() {
      _isSending = false;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }
    _showSnackBar('如果邮箱已注册，重置邮件已发送');
  }

  Future<void> _resetPassword() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;
    if (token.isEmpty) {
      _showSnackBar('请输入邮件中的重置令牌');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('新密码至少 6 位');
      return;
    }

    setState(() {
      _isResetting = true;
    });
    final error = await ref.read(authProvider.notifier).resetPassword(
          token: token,
          newPassword: password,
        );
    if (!mounted) return;
    setState(() {
      _isResetting = false;
    });

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    _showSnackBar('密码重置成功，请重新登录');
    context.go('/login');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('忘记密码')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '步骤 1：发送重置邮件',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '邮箱',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: '发送重置邮件',
            onPressed: _sendResetEmail,
            isLoading: _isSending,
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            '步骤 2：输入令牌并设置新密码',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: '重置令牌（邮件中）',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '新密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: '提交重置',
            onPressed: _resetPassword,
            isLoading: _isResetting,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/auth_state.dart';
import '../../../services/api/auth_service.dart';
import '../../../shared/widgets/primary_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _sendingCode = false;
  String? _sendMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (!_isValidPhone(phone)) {
      setState(() {
        _sendMessage = '请输入有效手机号';
      });
      return;
    }

    setState(() {
      _sendingCode = true;
      _sendMessage = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).sendSMSCode(phone);
      if (!mounted) return;
      setState(() {
        _sendMessage = _formatSendMessage(result);
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _sendMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _sendingCode = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .loginWithSMSCode(
            _phoneController.text.trim(),
            _codeController.text.trim(),
          );
    }
  }

  void _navigateToLogin() {
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, current) {
      if (current.isAuthenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('手机号快捷登录'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '手机号快捷登录',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '首次验证即自动创建账号，不再需要用户名和密码',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    prefixIcon: Icon(Icons.phone_iphone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (!_isValidPhone(value?.trim() ?? '')) {
                      return '请输入有效手机号';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          prefixIcon: Icon(Icons.sms_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) {
                          final code = value?.trim() ?? '';
                          if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                            return '请输入6位验证码';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _sendingCode ? null : _sendCode,
                        child: _sendingCode
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('获取验证码'),
                      ),
                    ),
                  ],
                ),
                if (_sendMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _sendMessage!,
                    style: TextStyle(color: Colors.teal[700]),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  text: '登录 / 注册',
                  onPressed: _submit,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 20),
                if (authState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('想用邮箱密码?'),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: const Text('其他方式登录'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidPhone(String value) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(value);
  }

  String _formatSendMessage(SMSCodeResponse result) {
    if (result.devMode && result.code != null) {
      return '开发模式验证码：${result.code}';
    }
    return '验证码已发送，${result.expiresIn ~/ 60}分钟内有效';
  }
}

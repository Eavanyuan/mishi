import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mishi_app/features/auth/pages/register_page.dart';
import 'package:mishi_app/providers/auth_state.dart';

void main() {
  test('AuthState helpers work', () {
    const state = AuthState.unauthenticated();
    expect(state.isAuthenticated, isFalse);
    expect(state.isUnauthenticated, isTrue);
  });

  testWidgets('Register page defaults to phone OTP flow', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterPage())),
    );

    expect(find.text('手机号快捷登录'), findsWidgets);
    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('密码'), findsNothing);
    expect(find.text('确认密码'), findsNothing);
  });
}

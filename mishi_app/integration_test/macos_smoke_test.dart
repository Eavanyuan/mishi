import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mishi_app/main.dart' as app;

const _apiBaseUrl = String.fromEnvironment(
  'MISHI_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080/v1',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('macOS smoke: login, home recommendations, poem detail', (
    tester,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'macos_smoke_$stamp@mishi.app';
    const password = '123456';
    await _registerUser(email: email, password: password);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('登录'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(ElevatedButton, '登录'));

    await _pumpUntilFound(tester, find.text('今日推荐'));
    expect(find.text('今日推荐'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '查看详情'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, '查看详情').first);
    await _pumpUntilFound(tester, find.text('诗歌详情'));
    expect(find.text('诗歌详情'), findsOneWidget);
    expect(find.text('AI解读'), findsOneWidget);
  });
}

Future<void> _registerUser({
  required String email,
  required String password,
}) async {
  final client = HttpClient();
  client.findProxy = (_) => 'DIRECT';
  try {
    final uri = Uri.parse('$_apiBaseUrl/auth/register');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'email': email,
        'password': password,
        'username': 'macos_smoke',
      }),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode != 200 || decoded['code'] != 0) {
      throw StateError('register failed: ${response.statusCode} $body');
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  final visibleTexts = find
      .byType(Text)
      .evaluate()
      .map((element) => element.widget)
      .whereType<Text>()
      .map((widget) => widget.data)
      .whereType<String>()
      .where((text) => text.trim().isNotEmpty)
      .toList();
  fail('Timed out waiting for $finder. Visible texts: $visibleTexts');
}

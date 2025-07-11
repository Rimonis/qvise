// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qvise/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:qvise/main.dart';

void main() {
  testWidgets('App starts and shows SignInScreen when unauthenticated', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap MyApp in a ProviderScope for Riverpod.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Wait for all frames to settle.
    await tester.pumpAndSettle();

    // Verify that the SignInScreen is present.
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // Verify that the home screen is not present.
    expect(find.text('Home'), findsNothing);
  });
}

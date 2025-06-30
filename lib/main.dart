import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qvise/core/routes/app_router.dart';
// import 'package:qvise/features/auth/presentation/application/auth_providers.dart';
// import 'package:qvise/features/auth/presentation/application/auth_state.dart';
// import 'package:qvise/features/auth/presentation/screens/home_screen.dart';
import 'package:qvise/firebase_options.dart';
// import 'features/auth/presentation/screens/sign_in_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
        routerConfig: ref.watch(routerProvider), // From app_router.dart
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
      );
  }
}


// class AuthGate extends ConsumerStatefulWidget {
//   const AuthGate({super.key});

//   @override
//   ConsumerState<AuthGate> createState() => _AuthGateState();
// }

// class _AuthGateState extends ConsumerState<AuthGate> {
//   @override
//   void initState() {
//     super.initState();

//     // ✅ Delay the call until after build
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // ✅ Use container.listen to safely do this outside build
//       ref.read(authProvider.notifier).checkAuthStatus();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     ref.listen<AuthState>(
//       authProvider,
//       (previous, current) {
//         if (!mounted) return; // 🚨 required to avoid setState errors after disposal

//         current.maybeWhen(
//           authenticated: (_) {
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(builder: (_) => const HomeScreen()),
//             );
//           },
//           unauthenticated: () {
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(builder: (_) => const SignInScreen()),
//             );
//           },
//           orElse: () {},
//         );
//       },
//     );

//     final authState = ref.watch(authProvider);

//     return authState.maybeWhen(
//       loading: () => const Center(child: CircularProgressIndicator()),
//       orElse: () => const SizedBox.shrink(),
//     );
//   }
// }


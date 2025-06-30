// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:qvise/core/routes/route_names.dart';
// import 'package:qvise/features/auth/presentation/application/auth_providers.dart';


// class SplashScreen extends ConsumerStatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();

//     // Schedule after first build
//     WidgetsBinding.instance.addPostFrameCallback((_) async{
//       await ref.read(authProvider.notifier).signOut();
//       _autoLogin();
//     });
//   }

//   Future<void> _autoLogin() async {
//     const email = 'test@example.com';
//     const password = 'password123';

//     try {
//       await ref.read(authProvider.notifier).signInWithEmailPassword(
//         email,
//         password,
//       );

//       if (mounted) {
//         context.go(RouteNames.subjects);
//       }
//     } catch (e) {
//       debugPrint('❌ Auto-login failed: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Auto-login failed: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_providers.dart';

class DebugSplashScreen extends ConsumerStatefulWidget {
  const DebugSplashScreen({super.key});

  @override
  ConsumerState<DebugSplashScreen> createState() => _DebugSplashScreenState();
}

class _DebugSplashScreenState extends ConsumerState<DebugSplashScreen> {
  bool _hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Trigger auth check after first frame to avoid loops
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        ref.read(authProvider.notifier).checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Just show loading - let the router handle navigation
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.flutter_dash,
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Qvise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../application/auth_providers.dart';
// import '../application/auth_state.dart';

// class SplashScreen extends ConsumerStatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen> {
//   String _statusMessage = 'Initializing...';

//   @override
//   void initState() {
//     super.initState();
//     // Trigger auth check when splash screen loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(authProvider.notifier).checkAuthStatus();
//     });
//   }

//   String _getStatusMessage(AuthState state) {
//     return state.when(
//       initial: () => 'Initializing...',
//       loading: () => 'Checking authentication...',
//       authenticated: (user) => 'Welcome back, ${user.displayName ?? user.email.split('@')[0]}!',
//       unauthenticated: () => 'Redirecting to sign in...',
//       emailNotVerified: (user) => 'Please verify your email...',
//       error: (message) => 'Authentication error',
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authState = ref.watch(authProvider);
    
//     // Update status message based on auth state
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final newMessage = _getStatusMessage(authState);
//       if (_statusMessage != newMessage) {
//         setState(() {
//           _statusMessage = newMessage;
//         });
//       }
//     });
    
//     return Scaffold(
//       backgroundColor: Colors.blue,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // App logo
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.flutter_dash,
//                 size: 80,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Qvise',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1.2,
//               ),
//             ),
//             const SizedBox(height: 48),
            
//             // Loading indicator with different styles based on state
//             authState.when(
//               initial: () => const CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//               loading: () => const CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//               authenticated: (_) => const Icon(
//                 Icons.check_circle,
//                 color: Colors.white,
//                 size: 32,
//               ),
//               unauthenticated: () => const CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//               emailNotVerified: (_) => const Icon(
//                 Icons.email_outlined,
//                 color: Colors.white,
//                 size: 32,
//               ),
//               error: (_) => const Icon(
//                 Icons.error_outline,
//                 color: Colors.white,
//                 size: 32,
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             // Status message
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 300),
//               child: Text(
//                 _statusMessage,
//                 key: ValueKey(_statusMessage),
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.9),
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
            
//             // Debug info (remove in production)
//             if (kDebugMode) ...[
//               const SizedBox(height: 24),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 margin: const EdgeInsets.symmetric(horizontal: 32),
//                 decoration: BoxDecoration(
//                   color: Colors.black26,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Debug Info',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.7),
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Auth State: ${authState.toString()}',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.7),
//                         fontSize: 10,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
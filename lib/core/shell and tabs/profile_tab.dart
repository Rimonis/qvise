// lib/core/shell and tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/auth/presentation/application/auth_providers.dart';
import 'package:qvise/core/theme/theme_mode_provider.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

// Provider for premium status (for testing)
final premiumStatusProvider = StateProvider<bool>((ref) => false);

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isPremium = ref.watch(premiumStatusProvider);
    
    return authState.when(
      initial: () => const Center(child: CircularProgressIndicator()),
      loading: () => const Center(child: CircularProgressIndicator()),
      authenticated: (user) => SingleChildScrollView(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingAllLg,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: user.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.photoUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // User name
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // User email
                  Text(
                    user.email ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Settings List
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isPremium ? Icons.star : Icons.star_outline,
                      color: isPremium ? Colors.amber : Colors.grey,
                    ),
                    title: const Text('Premium Status'),
                    subtitle: Text(isPremium ? 'Premium features enabled' : 'Free tier active'),
                    trailing: Switch(
                      value: isPremium,
                      onChanged: (value) {
                        ref.read(premiumStatusProvider.notifier).state = value;
                      },
                    ),
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  
                  // Theme Toggle
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Theme'),
                    subtitle: const Text('Switch between light and dark mode'),
                    trailing: const ThemeToggleButton(),
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Account Settings'),
                    subtitle: const Text('Manage your account preferences'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account Settings - Coming Soon')),
                          );
                        }
                      });
                    },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy'),
                    subtitle: const Text('Data and privacy settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy Settings - Coming Soon')),
                          );
                        }
                      });
                    },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help and contact support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & Support - Coming Soon')),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            const Text(
              'Qvise v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      emailNotVerified: (user) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, color: AppColors.warning, size: 100),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Email Verification Required',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please verify your email to access your profile',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () => _handleLogout(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              child: const Text('Sign Out', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
      unauthenticated: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, color: context.textTertiaryColor, size: 100),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Not Signed In',
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please sign in to view your profile',
              style: context.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 100, color: Colors.red),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Authentication Error',
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => ref.refresh(authProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}
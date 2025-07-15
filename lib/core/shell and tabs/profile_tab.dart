// lib/core/shell and tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/error/app_failure.dart';
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Email
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Subscription status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isPremium ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                        color: isPremium ? Colors.amber.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPremium ? Icons.star : Icons.person,
                          size: 16,
                          color: isPremium ? Colors.amber : Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isPremium ? 'Premium User' : 'Free User',
                          style: TextStyle(
                            color: isPremium ? Colors.amber : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Email verification status
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: user.isEmailVerified 
                    ? AppColors.successLight 
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: user.isEmailVerified 
                      ? AppColors.success.withValues(alpha: 0.3) 
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user.isEmailVerified ? Icons.verified : Icons.warning,
                    color: user.isEmailVerified ? AppColors.success : AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isEmailVerified ? 'Email Verified' : 'Email Not Verified',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: user.isEmailVerified ? AppColors.successDark : AppColors.warningDark,
                          ),
                        ),
                        Text(
                          user.isEmailVerified
                              ? 'Your email address is verified'
                              : 'Please verify your email address',
                          style: TextStyle(
                            fontSize: 12,
                            color: user.isEmailVerified ? AppColors.successDark : AppColors.warningDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Settings Section
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  const ThemeModeListTile(),
                  Divider(height: 1, color: context.dividerColor),
                  
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
                  
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Account Settings'),
                    subtitle: const Text('Manage your account preferences'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account Settings - Coming Soon')),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy'),
                    subtitle: const Text('Data and privacy settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Settings - Coming Soon')),
                      );
                    },
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help and contact support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support - Coming Soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Container(
              width: double.infinity,
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: context.surfaceVariantColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.palette),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Quick Theme Toggle',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const ThemeToggleButton(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
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
            const Text('Not Authenticated'),
            const SizedBox(height: AppSpacing.sm),
            const Text('Please sign in to view your profile'),
          ],
        ),
      ),
      error: (failure) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 100),
            const SizedBox(height: AppSpacing.lg),
            const Text('Error'),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                failure.userFriendlyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).checkAuthStatus();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userFriendlyMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
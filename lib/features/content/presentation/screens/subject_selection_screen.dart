import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_state_providers.dart';
import '../widgets/content_loading_widget.dart';
import 'topic_selection_screen.dart';
import 'create_lesson_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class SubjectSelectionScreen extends ConsumerWidget {
  const SubjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsNotifierProvider);
    
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Subject',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackgroundColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          return ListView.builder(
            padding: AppSpacing.screenPaddingAll,
            itemCount: subjects.length + 1, // +1 for "New Subject" tile
            itemBuilder: (context, index) {
              if (index == subjects.length) {
                // "New Subject" tile at the bottom
                return _buildNewSubjectTile(context);
              }
              
              final subject = subjects[index];
              return _buildSubjectTile(context, subject);
            },
          );
        },
        loading: () => const ContentLoadingWidget(message: 'Loading subjects...'),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildNewSubjectTile(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      color: context.cardBackgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border.all(
              color: context.successColor.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.add,
            color: context.successColor,
            size: AppSpacing.iconLg,
          ),
        ),
        title: Text(
          'New Subject',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.successColor,
          ),
        ),
        subtitle: Text(
          'Create a lesson in a new subject',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: context.successColor,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateLessonScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectTile(BuildContext context, subject) {
    final proficiencyColor = Color(int.parse(subject.proficiencyColor.replaceAll('#', '0xFF')));
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: context.cardBackgroundColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: proficiencyColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(
            Icons.school,
            color: proficiencyColor,
            size: AppSpacing.iconLg,
          ),
        ),
        title: Text(
          subject.name,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${subject.topicCount} topics • ${subject.lessonCount} lessons',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: proficiencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    subject.proficiencyLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: proficiencyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: context.iconColor,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicSelectionScreen(
                subjectName: subject.name,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPaddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: context.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error: ${error.toString()}',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(subjectsNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/features/content/presentation/screens/create_lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qvise/core/providers/network_status_provider.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/create_lesson_params.dart';
import '../providers/content_providers.dart';
import '../providers/content_state_providers.dart';
import '../widgets/content_form_field.dart';
// Theme imports
import 'package:qvise/core/theme/app_colors.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class CreateLessonScreen extends ConsumerStatefulWidget {
  final String? initialSubjectName;
  final String? initialTopicName;

  const CreateLessonScreen({
    super.key,
    this.initialSubjectName,
    this.initialTopicName,
  });

  @override
  ConsumerState<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends ConsumerState<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _titleController = TextEditingController();

  bool _isNewSubject = true;
  bool _isNewTopic = true;
  bool _isLoading = false;

  List<String> _existingSubjects = [];
  List<String> _existingTopics = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialSubjectName != null) {
      _subjectController.text = widget.initialSubjectName!;
      _isNewSubject = false;
    }
    if (widget.initialTopicName != null) {
      _topicController.text = widget.initialTopicName!;
      _isNewTopic = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingContent();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _loadExistingContent() async {
    final subjectsAsync = ref.read(subjectsNotifierProvider);
    subjectsAsync.whenData((subjects) {
      if (mounted) {
        setState(() {
          _existingSubjects = subjects.map((s) => s.name).toList();
        });
      }

      if (widget.initialSubjectName != null) {
        _loadTopicsForSubject(widget.initialSubjectName!);
      }
    });
  }

  void _loadTopicsForSubject(String subjectName) async {
    final topicsAsync = ref.read(topicsNotifierProvider(subjectName));
    topicsAsync.whenData((topics) {
      if (mounted) {
        setState(() {
          _existingTopics = topics.map((t) => t.name).toList();
        });
      }
    });
  }

  void _onSubjectChanged(String value) {
    final isExisting = _existingSubjects.contains(value);
    setState(() {
      _isNewSubject = !isExisting;
      if (isExisting) {
        _loadTopicsForSubject(value);
      } else {
        _existingTopics = [];
        _isNewTopic = true;
      }
    });
  }

  void _onTopicChanged(String value) {
    final isExisting = _existingTopics.contains(value);
    setState(() {
      _isNewTopic = !isExisting;
    });
  }

  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final params = CreateLessonParams(
        subjectName: _subjectController.text.trim(),
        topicName: _topicController.text.trim(),
        lessonTitle:
            _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        isNewSubject: _isNewSubject,
        isNewTopic: _isNewTopic,
      );

      final shouldProceed = await _showAdDialog();
      if (!shouldProceed || !mounted) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final createLessonUseCase = ref.read(createLessonUseCaseProvider); // CORRECTED
      final result = await createLessonUseCase(params);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create lesson: ${failure.message}'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        (lesson) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lesson created successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('${RouteNames.app}/lesson/${lesson.id}');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create lesson: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showAdDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Watch Ad to Continue',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'As a free user, you need to watch a short ad to create a new lesson.\n\n'
          'This helps us keep the app free for everyone!',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
            ),
            child: const Text('Watch Ad'),
          ),
        ],
        actionsPadding: AppSpacing.paddingAllMd,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;

    if (!isOnline) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Create Lesson',
            style: context.textTheme.headlineSmall,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: AppSpacing.screenPaddingAll,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 64, color: context.textTertiaryColor),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Internet connection required',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please connect to the internet to create new lessons.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Lesson',
          style: context.textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPaddingAll,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContentFormField(
                controller: _subjectController,
                label: 'Subject',
                hint: 'e.g. Mathematics, Physics, History',
                icon: Icons.school,
                enabled: widget.initialSubjectName == null,
                suggestions: _existingSubjects,
                onChanged: _onSubjectChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              if (_isNewSubject && _subjectController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: AppSpacing.iconSm,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'This will create a new subject',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.infoDark,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              ContentFormField(
                controller: _topicController,
                label: 'Topic',
                hint: 'e.g. Calculus, Quantum Mechanics, World War II',
                icon: Icons.topic,
                enabled: widget.initialTopicName == null,
                suggestions: _existingTopics,
                onChanged: _onTopicChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a topic';
                  }
                  return null;
                },
              ),
              if (_isNewTopic && _topicController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      top: AppSpacing.xs,
                      bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: AppSpacing.iconSm,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'This will create a new topic',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.infoDark,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              ContentFormField(
                controller: _titleController,
                label: 'Lesson Title (Optional)',
                hint: 'e.g. Introduction to Derivatives',
                icon: Icons.book,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'If no title is provided, the lesson will be identified by its creation date.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textTertiaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info,
                          size: AppSpacing.iconSm,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Lesson Information',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• First review will be scheduled for tomorrow\n'
                      '• You can add flashcards and study materials after creation\n'
                      '• Free users need to watch an ad to create lessons',
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: AppColors.infoDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        context.textDisabledColor.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: AppSpacing.iconSm,
                          width: AppSpacing.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Lesson',
                          style: context.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
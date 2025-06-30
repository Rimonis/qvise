import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../domain/entities/create_lesson_params.dart';
import '../providers/content_state_providers.dart';
import '../widgets/content_form_field.dart';

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
    
    // Set initial values if provided
    if (widget.initialSubjectName != null) {
      _subjectController.text = widget.initialSubjectName!;
      _isNewSubject = false;
    }
    if (widget.initialTopicName != null) {
      _topicController.text = widget.initialTopicName!;
      _isNewTopic = false;
    }
    
    // Load existing subjects
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
      setState(() {
        _existingSubjects = subjects.map((s) => s.name).toList();
      });
      
      // Load topics if subject is pre-selected
      if (widget.initialSubjectName != null) {
        _loadTopicsForSubject(widget.initialSubjectName!);
      }
    });
  }
  
  void _loadTopicsForSubject(String subjectName) async {
    final topicsAsync = ref.read(topicsNotifierProvider(subjectName));
    topicsAsync.whenData((topics) {
      setState(() {
        _existingTopics = topics.map((t) => t.name).toList();
      });
    });
  }
  
  void _onSubjectChanged(String value) {
    // Check if it's an existing subject
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
    // Check if it's an existing topic
    final isExisting = _existingTopics.contains(value);
    setState(() {
      _isNewTopic = !isExisting;
    });
  }
  
  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final params = CreateLessonParams(
        subjectName: _subjectController.text.trim(),
        topicName: _topicController.text.trim(),
        lessonTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        isNewSubject: _isNewSubject,
        isNewTopic: _isNewTopic,
      );
      
      // Show ad dialog for free users (placeholder - implement actual ad logic)
      final shouldProceed = await _showAdDialog();
      if (!shouldProceed) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Create the lesson
      await ref.read(lessonsNotifierProvider(params.subjectName, params.topicName).notifier)
          .createNewLesson(params);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to the lessons screen
        context.go('${RouteNames.subjects}/${params.subjectName}/${params.topicName}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create lesson: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    // TODO: Implement actual ad logic here
    // For now, just show a placeholder dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Watch Ad to Continue'),
        content: const Text(
          'As a free user, you need to watch a short ad to create a new lesson.\n\n'
          'This helps us keep the app free for everyone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate ad watching
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
    
    if (!isOnline) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Lesson'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Internet connection required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please connect to the internet to create new lessons.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lesson'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject field
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
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'This will create a new subject',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Topic field
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
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'This will create a new topic',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Title field (optional)
              ContentFormField(
                controller: _titleController,
                label: 'Lesson Title (Optional)',
                hint: 'e.g. Introduction to Derivatives',
                icon: Icons.book,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'If no title is provided, the lesson will be identified by its creation date.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Lesson Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• First review will be scheduled for tomorrow\n'
                      '• You can add flashcards and study materials after creation\n'
                      '• Free users need to watch an ad to create lessons',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Create button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createLesson,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Lesson',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
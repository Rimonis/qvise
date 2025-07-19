# Details

Date : 2025-07-19 19:19:12

Directory d:\\Codes\\Test\\Flutter\\qvise\\lib

Total : 143 files,  17930 codes, 767 comments, 1782 blanks, all 20479 lines

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [lib/core/application/sync\_coordinator.dart](/lib/core/application/sync_coordinator.dart) | Dart | 71 | 4 | 12 | 87 |
| [lib/core/application/sync\_state.dart](/lib/core/application/sync_state.dart) | Dart | 14 | 1 | 4 | 19 |
| [lib/core/data/database/app\_database.dart](/lib/core/data/database/app_database.dart) | Dart | 179 | 5 | 22 | 206 |
| [lib/core/data/datasources/transactional\_data\_source.dart](/lib/core/data/datasources/transactional_data_source.dart) | Dart | 14 | 1 | 5 | 20 |
| [lib/core/data/migrations/add\_sync\_fields\_migration.dart](/lib/core/data/migrations/add_sync_fields_migration.dart) | Dart | 23 | 1 | 5 | 29 |
| [lib/core/data/migrations/database\_migration.dart](/lib/core/data/migrations/database_migration.dart) | Dart | 51 | 3 | 11 | 65 |
| [lib/core/data/providers/data\_providers.dart](/lib/core/data/providers/data_providers.dart) | Dart | 33 | 4 | 7 | 44 |
| [lib/core/data/repositories/base\_repository.dart](/lib/core/data/repositories/base_repository.dart) | Dart | 11 | 3 | 2 | 16 |
| [lib/core/data/unit\_of\_work.dart](/lib/core/data/unit_of_work.dart) | Dart | 41 | 3 | 6 | 50 |
| [lib/core/error/app\_failure.dart](/lib/core/error/app_failure.dart) | Dart | 93 | 2 | 11 | 106 |
| [lib/core/error/failures.dart](/lib/core/error/failures.dart) | Dart | 1 | 2 | 1 | 4 |
| [lib/core/providers/network\_status\_provider.dart](/lib/core/providers/network_status_provider.dart) | Dart | 66 | 1 | 15 | 82 |
| [lib/core/providers/providers.dart](/lib/core/providers/providers.dart) | Dart | 145 | 7 | 25 | 177 |
| [lib/core/routes/app\_router.dart](/lib/core/routes/app_router.dart) | Dart | 298 | 1 | 22 | 321 |
| [lib/core/routes/route\_guard.dart](/lib/core/routes/route_guard.dart) | Dart | 83 | 31 | 26 | 140 |
| [lib/core/routes/route\_names.dart](/lib/core/routes/route_names.dart) | Dart | 14 | 6 | 5 | 25 |
| [lib/core/services/file\_picker\_service.dart](/lib/core/services/file_picker_service.dart) | Dart | 63 | 2 | 4 | 69 |
| [lib/core/services/subscription\_service.dart](/lib/core/services/subscription_service.dart) | Dart | 24 | 4 | 6 | 34 |
| [lib/core/services/user\_service.dart](/lib/core/services/user_service.dart) | Dart | 22 | 1 | 5 | 28 |
| [lib/core/shell and tabs/analytics\_tab.dart](/lib/core/shell%20and%20tabs/analytics_tab.dart) | Dart | 109 | 1 | 3 | 113 |
| [lib/core/shell and tabs/browse\_tab.dart](/lib/core/shell%20and%20tabs/browse_tab.dart) | Dart | 526 | 6 | 23 | 555 |
| [lib/core/shell and tabs/create\_tab.dart](/lib/core/shell%20and%20tabs/create_tab.dart) | Dart | 187 | 1 | 12 | 200 |
| [lib/core/shell and tabs/home\_tab.dart](/lib/core/shell%20and%20tabs/home_tab.dart) | Dart | 203 | 3 | 10 | 216 |
| [lib/core/shell and tabs/main\_shell\_screen.dart](/lib/core/shell%20and%20tabs/main_shell_screen.dart) | Dart | 144 | 1 | 14 | 159 |
| [lib/core/shell and tabs/profile\_tab.dart](/lib/core/shell%20and%20tabs/profile_tab.dart) | Dart | 362 | 9 | 17 | 388 |
| [lib/core/sync/data/datasources/conflict\_local\_datasource.dart](/lib/core/sync/data/datasources/conflict_local_datasource.dart) | Dart | 117 | 1 | 12 | 130 |
| [lib/core/sync/domain/entities/sync\_conflict.dart](/lib/core/sync/domain/entities/sync_conflict.dart) | Dart | 32 | 1 | 5 | 38 |
| [lib/core/sync/domain/entities/sync\_report.dart](/lib/core/sync/domain/entities/sync_report.dart) | Dart | 42 | 1 | 7 | 50 |
| [lib/core/sync/services/conflict\_resolver.dart](/lib/core/sync/services/conflict_resolver.dart) | Dart | 109 | 11 | 20 | 140 |
| [lib/core/sync/services/remote\_entity\_cache.dart](/lib/core/sync/services/remote_entity_cache.dart) | Dart | 32 | 1 | 8 | 41 |
| [lib/core/sync/services/sync\_performance\_monitor.dart](/lib/core/sync/services/sync_performance_monitor.dart) | Dart | 33 | 1 | 5 | 39 |
| [lib/core/sync/services/sync\_service.dart](/lib/core/sync/services/sync_service.dart) | Dart | 342 | 8 | 41 | 391 |
| [lib/core/sync/utils/batch\_helpers.dart](/lib/core/sync/utils/batch_helpers.dart) | Dart | 30 | 1 | 5 | 36 |
| [lib/core/theme/app\_colors.dart](/lib/core/theme/app_colors.dart) | Dart | 98 | 13 | 27 | 138 |
| [lib/core/theme/app\_spacing.dart](/lib/core/theme/app_spacing.dart) | Dart | 109 | 13 | 18 | 140 |
| [lib/core/theme/app\_theme.dart](/lib/core/theme/app_theme.dart) | Dart | 387 | 30 | 32 | 449 |
| [lib/core/theme/app\_typography.dart](/lib/core/theme/app_typography.dart) | Dart | 200 | 12 | 28 | 240 |
| [lib/core/theme/theme\_extensions.dart](/lib/core/theme/theme_extensions.dart) | Dart | 316 | 19 | 41 | 376 |
| [lib/core/theme/theme\_mode\_provider.dart](/lib/core/theme/theme_mode_provider.dart) | Dart | 260 | 38 | 37 | 335 |
| [lib/core/utils/password\_validator.dart](/lib/core/utils/password_validator.dart) | Dart | 67 | 3 | 20 | 90 |
| [lib/core/widgets/error\_boundary.dart](/lib/core/widgets/error_boundary.dart) | Dart | 239 | 15 | 29 | 283 |
| [lib/features/auth/data/datasources/auth\_local\_data\_source.dart](/lib/features/auth/data/datasources/auth_local_data_source.dart) | Dart | 55 | 0 | 10 | 65 |
| [lib/features/auth/data/datasources/auth\_remote\_data\_source.dart](/lib/features/auth/data/datasources/auth_remote_data_source.dart) | Dart | 169 | 7 | 25 | 201 |
| [lib/features/auth/data/models/user\_model.dart](/lib/features/auth/data/models/user_model.dart) | Dart | 48 | 2 | 7 | 57 |
| [lib/features/auth/data/repositories/auth\_repository\_impl.dart](/lib/features/auth/data/repositories/auth_repository_impl.dart) | Dart | 108 | 1 | 12 | 121 |
| [lib/features/auth/domain/entities/user.dart](/lib/features/auth/domain/entities/user.dart) | Dart | 13 | 0 | 2 | 15 |
| [lib/features/auth/domain/repositories/auth\_repository.dart](/lib/features/auth/domain/repositories/auth_repository.dart) | Dart | 13 | 3 | 3 | 19 |
| [lib/features/auth/domain/usecases/check\_email\_verification.dart](/lib/features/auth/domain/usecases/check_email_verification.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/auth/domain/usecases/get\_current\_user.dart](/lib/features/auth/domain/usecases/get_current_user.dart) | Dart | 11 | 1 | 4 | 16 |
| [lib/features/auth/domain/usecases/initialize\_backend.dart](/lib/features/auth/domain/usecases/initialize_backend.dart) | Dart | 8 | 0 | 4 | 12 |
| [lib/features/auth/domain/usecases/reset\_password.dart](/lib/features/auth/domain/usecases/reset_password.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/auth/domain/usecases/send\_email\_verification.dart](/lib/features/auth/domain/usecases/send_email_verification.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/auth/domain/usecases/sign\_in\_with\_apple.dart](/lib/features/auth/domain/usecases/sign_in_with_apple.dart) | Dart | 0 | 11 | 3 | 14 |
| [lib/features/auth/domain/usecases/sign\_in\_with\_email\_password.dart](/lib/features/auth/domain/usecases/sign_in_with_email_password.dart) | Dart | 11 | 1 | 4 | 16 |
| [lib/features/auth/domain/usecases/sign\_in\_with\_google.dart](/lib/features/auth/domain/usecases/sign_in_with_google.dart) | Dart | 11 | 1 | 4 | 16 |
| [lib/features/auth/domain/usecases/sign\_out.dart](/lib/features/auth/domain/usecases/sign_out.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/auth/domain/usecases/sign\_up\_with\_email\_password.dart](/lib/features/auth/domain/usecases/sign_up_with_email_password.dart) | Dart | 11 | 1 | 3 | 15 |
| [lib/features/auth/presentation/application/auth\_notifier.dart](/lib/features/auth/presentation/application/auth_notifier.dart) | Dart | 27 | 1 | 7 | 35 |
| [lib/features/auth/presentation/application/auth\_providers.dart](/lib/features/auth/presentation/application/auth_providers.dart) | Dart | 197 | 6 | 29 | 232 |
| [lib/features/auth/presentation/application/auth\_state.dart](/lib/features/auth/presentation/application/auth_state.dart) | Dart | 13 | 1 | 2 | 16 |
| [lib/features/auth/presentation/screens/email\_verification\_screen.dart](/lib/features/auth/presentation/screens/email_verification_screen.dart) | Dart | 402 | 1 | 40 | 443 |
| [lib/features/auth/presentation/screens/forgot\_password\_screen.dart](/lib/features/auth/presentation/screens/forgot_password_screen.dart) | Dart | 334 | 1 | 28 | 363 |
| [lib/features/auth/presentation/screens/sign\_in\_screen.dart](/lib/features/auth/presentation/screens/sign_in_screen.dart) | Dart | 333 | 1 | 30 | 364 |
| [lib/features/auth/presentation/screens/sign\_up\_screen.dart](/lib/features/auth/presentation/screens/sign_up_screen.dart) | Dart | 402 | 1 | 43 | 446 |
| [lib/features/auth/presentation/screens/splash\_screen.dart](/lib/features/auth/presentation/screens/splash_screen.dart) | Dart | 68 | 210 | 28 | 306 |
| [lib/features/auth/presentation/widgets/auth\_button.dart](/lib/features/auth/presentation/widgets/auth_button.dart) | Dart | 65 | 0 | 3 | 68 |
| [lib/features/auth/presentation/widgets/auth\_text\_field.dart](/lib/features/auth/presentation/widgets/auth_text_field.dart) | Dart | 285 | 20 | 38 | 343 |
| [lib/features/content/data/datasources/content\_local\_data\_source.dart](/lib/features/content/data/datasources/content_local_data_source.dart) | Dart | 310 | 2 | 31 | 343 |
| [lib/features/content/data/datasources/content\_remote\_data\_source.dart](/lib/features/content/data/datasources/content_remote_data_source.dart) | Dart | 244 | 2 | 26 | 272 |
| [lib/features/content/data/models/lesson\_model.dart](/lib/features/content/data/models/lesson_model.dart) | Dart | 170 | 1 | 11 | 182 |
| [lib/features/content/data/models/subject\_model.dart](/lib/features/content/data/models/subject_model.dart) | Dart | 62 | 0 | 8 | 70 |
| [lib/features/content/data/models/topic\_model.dart](/lib/features/content/data/models/topic_model.dart) | Dart | 62 | 0 | 8 | 70 |
| [lib/features/content/data/repositories/content\_repository\_impl.dart](/lib/features/content/data/repositories/content_repository_impl.dart) | Dart | 498 | 4 | 49 | 551 |
| [lib/features/content/domain/entities/create\_lesson\_params.dart](/lib/features/content/domain/entities/create_lesson_params.dart) | Dart | 12 | 0 | 2 | 14 |
| [lib/features/content/domain/entities/lesson.dart](/lib/features/content/domain/entities/lesson.dart) | Dart | 71 | 1 | 14 | 86 |
| [lib/features/content/domain/entities/subject.dart](/lib/features/content/domain/entities/subject.dart) | Dart | 27 | 1 | 5 | 33 |
| [lib/features/content/domain/entities/topic.dart](/lib/features/content/domain/entities/topic.dart) | Dart | 27 | 1 | 5 | 33 |
| [lib/features/content/domain/repositories/content\_repository.dart](/lib/features/content/domain/repositories/content_repository.dart) | Dart | 27 | 1 | 2 | 30 |
| [lib/features/content/domain/usecases/create\_lesson.dart](/lib/features/content/domain/usecases/create_lesson.dart) | Dart | 12 | 1 | 4 | 17 |
| [lib/features/content/domain/usecases/delete\_lesson.dart](/lib/features/content/domain/usecases/delete_lesson.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/content/domain/usecases/delete\_subject.dart](/lib/features/content/domain/usecases/delete_subject.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/content/domain/usecases/delete\_topic.dart](/lib/features/content/domain/usecases/delete_topic.dart) | Dart | 10 | 1 | 4 | 15 |
| [lib/features/content/domain/usecases/get\_lessons\_by\_topic.dart](/lib/features/content/domain/usecases/get_lessons_by_topic.dart) | Dart | 11 | 1 | 4 | 16 |
| [lib/features/content/domain/usecases/get\_subjects.dart](/lib/features/content/domain/usecases/get_subjects.dart) | Dart | 11 | 1 | 4 | 16 |
| [lib/features/content/domain/usecases/get\_topics\_by\_subject.dart](/lib/features/content/domain/usecases/get_topics_by_subject.dart) | Dart | 11 | 1 | 3 | 15 |
| [lib/features/content/presentation/providers/content\_error\_handler.dart](/lib/features/content/presentation/providers/content_error_handler.dart) | Dart | 136 | 4 | 16 | 156 |
| [lib/features/content/presentation/providers/content\_providers.dart](/lib/features/content/presentation/providers/content_providers.dart) | Dart | 58 | 1 | 12 | 71 |
| [lib/features/content/presentation/providers/content\_state\_providers.dart](/lib/features/content/presentation/providers/content_state_providers.dart) | Dart | 198 | 8 | 28 | 234 |
| [lib/features/content/presentation/providers/tab\_navigation\_provider.dart](/lib/features/content/presentation/providers/tab_navigation_provider.dart) | Dart | 9 | 2 | 2 | 13 |
| [lib/features/content/presentation/screens/create\_lesson\_screen.dart](/lib/features/content/presentation/screens/create_lesson_screen.dart) | Dart | 435 | 4 | 28 | 467 |
| [lib/features/content/presentation/screens/lesson\_detail\_screen.dart](/lib/features/content/presentation/screens/lesson_detail_screen.dart) | Dart | 447 | 5 | 26 | 478 |
| [lib/features/content/presentation/screens/lessons\_screen.dart](/lib/features/content/presentation/screens/lessons_screen.dart) | Dart | 395 | 1 | 13 | 409 |
| [lib/features/content/presentation/screens/subject\_selection\_screen.dart](/lib/features/content/presentation/screens/subject_selection_screen.dart) | Dart | 238 | 1 | 8 | 247 |
| [lib/features/content/presentation/screens/subjects\_screen.dart](/lib/features/content/presentation/screens/subjects_screen.dart) | Dart | 324 | 0 | 8 | 332 |
| [lib/features/content/presentation/screens/topic\_selection\_screen.dart](/lib/features/content/presentation/screens/topic_selection_screen.dart) | Dart | 143 | 1 | 6 | 150 |
| [lib/features/content/presentation/screens/topics\_screen.dart](/lib/features/content/presentation/screens/topics_screen.dart) | Dart | 361 | 0 | 11 | 372 |
| [lib/features/content/presentation/screens/unlocked\_lesson\_screen.dart](/lib/features/content/presentation/screens/unlocked_lesson_screen.dart) | Dart | 311 | 1 | 10 | 322 |
| [lib/features/content/presentation/widgets/browse\_subject\_card.dart](/lib/features/content/presentation/widgets/browse_subject_card.dart) | Dart | 132 | 1 | 6 | 139 |
| [lib/features/content/presentation/widgets/content\_form\_field.dart](/lib/features/content/presentation/widgets/content_form_field.dart) | Dart | 174 | 0 | 13 | 187 |
| [lib/features/content/presentation/widgets/content\_loading\_widget.dart](/lib/features/content/presentation/widgets/content_loading_widget.dart) | Dart | 30 | 0 | 3 | 33 |
| [lib/features/content/presentation/widgets/due\_lesson\_card.dart](/lib/features/content/presentation/widgets/due_lesson_card.dart) | Dart | 225 | 9 | 9 | 243 |
| [lib/features/content/presentation/widgets/empty\_content\_widget.dart](/lib/features/content/presentation/widgets/empty_content_widget.dart) | Dart | 107 | 0 | 4 | 111 |
| [lib/features/content/presentation/widgets/lesson\_card.dart](/lib/features/content/presentation/widgets/lesson_card.dart) | Dart | 199 | 1 | 9 | 209 |
| [lib/features/content/presentation/widgets/subject\_card.dart](/lib/features/content/presentation/widgets/subject_card.dart) | Dart | 173 | 3 | 8 | 184 |
| [lib/features/content/presentation/widgets/topic\_tile.dart](/lib/features/content/presentation/widgets/topic_tile.dart) | Dart | 118 | 1 | 5 | 124 |
| [lib/features/content/presentation/widgets/unlocked\_lesson\_card.dart](/lib/features/content/presentation/widgets/unlocked_lesson_card.dart) | Dart | 245 | 9 | 11 | 265 |
| [lib/features/files/data/datasources/file\_local\_data\_source.dart](/lib/features/files/data/datasources/file_local_data_source.dart) | Dart | 72 | 1 | 9 | 82 |
| [lib/features/files/data/datasources/file\_remote\_data\_source.dart](/lib/features/files/data/datasources/file_remote_data_source.dart) | Dart | 39 | 49 | 10 | 98 |
| [lib/features/files/data/models/file\_model.dart](/lib/features/files/data/models/file_model.dart) | Dart | 89 | 1 | 8 | 98 |
| [lib/features/files/data/repositories/file\_repository\_impl.dart](/lib/features/files/data/repositories/file_repository_impl.dart) | Dart | 197 | 18 | 31 | 246 |
| [lib/features/files/domain/entities/file.dart](/lib/features/files/domain/entities/file.dart) | Dart | 72 | 1 | 6 | 79 |
| [lib/features/files/domain/repositories/file\_repository.dart](/lib/features/files/domain/repositories/file_repository.dart) | Dart | 14 | 1 | 6 | 21 |
| [lib/features/files/domain/usecases/create\_file.dart](/lib/features/files/domain/usecases/create_file.dart) | Dart | 28 | 1 | 7 | 36 |
| [lib/features/files/domain/usecases/delete\_file.dart](/lib/features/files/domain/usecases/delete_file.dart) | Dart | 10 | 1 | 3 | 14 |
| [lib/features/files/domain/usecases/get\_files\_by\_lesson.dart](/lib/features/files/domain/usecases/get_files_by_lesson.dart) | Dart | 11 | 1 | 3 | 15 |
| [lib/features/files/domain/usecases/get\_starred\_files.dart](/lib/features/files/domain/usecases/get_starred_files.dart) | Dart | 11 | 1 | 3 | 15 |
| [lib/features/files/domain/usecases/sync\_files.dart](/lib/features/files/domain/usecases/sync_files.dart) | Dart | 10 | 1 | 3 | 14 |
| [lib/features/files/domain/usecases/toggle\_file\_starred.dart](/lib/features/files/domain/usecases/toggle_file_starred.dart) | Dart | 24 | 1 | 7 | 32 |
| [lib/features/files/presentation/providers/file\_providers.dart](/lib/features/files/presentation/providers/file_providers.dart) | Dart | 133 | 10 | 23 | 166 |
| [lib/features/files/presentation/screens/lesson\_files\_screen.dart](/lib/features/files/presentation/screens/lesson_files_screen.dart) | Dart | 66 | 1 | 6 | 73 |
| [lib/features/files/presentation/widgets/file\_list\_item.dart](/lib/features/files/presentation/widgets/file_list_item.dart) | Dart | 181 | 4 | 10 | 195 |
| [lib/features/files/presentation/widgets/file\_list\_widget.dart](/lib/features/files/presentation/widgets/file_list_widget.dart) | Dart | 210 | 2 | 6 | 218 |
| [lib/features/flashcards/creation/domain/entities/flashcard\_difficulty.dart](/lib/features/flashcards/creation/domain/entities/flashcard_difficulty.dart) | Dart | 20 | 0 | 3 | 23 |
| [lib/features/flashcards/creation/domain/usecases/create\_flashcard.dart](/lib/features/flashcards/creation/domain/usecases/create_flashcard.dart) | Dart | 66 | 6 | 13 | 85 |
| [lib/features/flashcards/creation/domain/usecases/update\_flashcard.dart](/lib/features/flashcards/creation/domain/usecases/update_flashcard.dart) | Dart | 17 | 2 | 6 | 25 |
| [lib/features/flashcards/creation/presentation/providers/flashcard\_creation\_providers.dart](/lib/features/flashcards/creation/presentation/providers/flashcard_creation_providers.dart) | Dart | 10 | 2 | 2 | 14 |
| [lib/features/flashcards/creation/presentation/screens/flashcard\_creation\_screen.dart](/lib/features/flashcards/creation/presentation/screens/flashcard_creation_screen.dart) | Dart | 445 | 1 | 31 | 477 |
| [lib/features/flashcards/creation/presentation/widgets/difficulty\_selector\_widget.dart](/lib/features/flashcards/creation/presentation/widgets/difficulty_selector_widget.dart) | Dart | 98 | 1 | 6 | 105 |
| [lib/features/flashcards/creation/presentation/widgets/flashcard\_preview\_widget.dart](/lib/features/flashcards/creation/presentation/widgets/flashcard_preview_widget.dart) | Dart | 394 | 7 | 21 | 422 |
| [lib/features/flashcards/creation/presentation/widgets/hint\_input\_widget.dart](/lib/features/flashcards/creation/presentation/widgets/hint_input_widget.dart) | Dart | 193 | 1 | 11 | 205 |
| [lib/features/flashcards/creation/presentation/widgets/tag\_selector\_widget.dart](/lib/features/flashcards/creation/presentation/widgets/tag_selector_widget.dart) | Dart | 83 | 1 | 5 | 89 |
| [lib/features/flashcards/presentation/screens/flashcard\_preview\_screen.dart](/lib/features/flashcards/presentation/screens/flashcard_preview_screen.dart) | Dart | 307 | 1 | 13 | 321 |
| [lib/features/flashcards/shared/data/datasources/flashcard\_local\_data\_source.dart](/lib/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart) | Dart | 208 | 2 | 21 | 231 |
| [lib/features/flashcards/shared/data/datasources/flashcard\_remote\_data\_source.dart](/lib/features/flashcards/shared/data/datasources/flashcard_remote_data_source.dart) | Dart | 135 | 2 | 19 | 156 |
| [lib/features/flashcards/shared/data/models/flashcard\_model.dart](/lib/features/flashcards/shared/data/models/flashcard_model.dart) | Dart | 155 | 3 | 12 | 170 |
| [lib/features/flashcards/shared/data/repositories/flashcard\_repository\_impl.dart](/lib/features/flashcards/shared/data/repositories/flashcard_repository_impl.dart) | Dart | 227 | 4 | 27 | 258 |
| [lib/features/flashcards/shared/domain/entities/flashcard.dart](/lib/features/flashcards/shared/domain/entities/flashcard.dart) | Dart | 69 | 8 | 12 | 89 |
| [lib/features/flashcards/shared/domain/entities/flashcard\_tag.dart](/lib/features/flashcards/shared/domain/entities/flashcard_tag.dart) | Dart | 126 | 5 | 19 | 150 |
| [lib/features/flashcards/shared/domain/repositories/flashcard\_repository.dart](/lib/features/flashcards/shared/domain/repositories/flashcard_repository.dart) | Dart | 27 | 1 | 3 | 31 |
| [lib/features/flashcards/shared/presentation/providers/flashcard\_count\_provider.dart](/lib/features/flashcards/shared/presentation/providers/flashcard_count_provider.dart) | Dart | 13 | 2 | 3 | 18 |
| [lib/features/flashcards/shared/presentation/providers/flashcard\_providers.dart](/lib/features/flashcards/shared/presentation/providers/flashcard_providers.dart) | Dart | 36 | 4 | 6 | 46 |
| [lib/features/sync/presentation/widgets/sync\_status\_widget.dart](/lib/features/sync/presentation/widgets/sync_status_widget.dart) | Dart | 59 | 2 | 8 | 69 |
| [lib/main.dart](/lib/main.dart) | Dart | 218 | 1 | 23 | 242 |

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)
import 'package:qvise/features/auth/data/datasources/auth_remote_data_source.dart';


class InitializeBackend {
  final AuthRemoteDataSource repository;

  InitializeBackend(this.repository);

  Future<void> call() async {
    await repository.initialize();
  }
}
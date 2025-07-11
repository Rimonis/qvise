// lib/core/config/app_config.dart
import 'dart:convert';
import 'package:flutter/services.dart';

enum Environment { development, staging, production }

class AppConfig {
  final String appName;
  final String apiBaseUrl;
  final Environment environment;

  const AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.environment,
  });

  static Future<AppConfig> forEnvironment(String? env) async {
    final envString = env?? 'development';
    final contents = await rootBundle.loadString(
      'assets/config/$envString.json',
    );
    final json = jsonDecode(contents);
    return AppConfig(
      appName: json['appName'],
      apiBaseUrl: json,
      environment: Environment.values.firstWhere(
        (e) => e.name == envString,
        orElse: () => Environment.development,
      ),
    );
  }
}
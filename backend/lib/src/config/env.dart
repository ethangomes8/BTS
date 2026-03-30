import 'dart:io';

class Env {
  Env._();

  static String get jwtSecret => _env('JWT_SECRET', 'change_me_super_secret');
  static String get adminEmail => _env('ADMIN_EMAIL', 'admin@brasserie.local');
  static String get adminPassword => _env('ADMIN_PASSWORD', 'Admin1234!');

  static int get jwtTtlHours => int.tryParse(_env('JWT_TTL_HOURS', '24')) ?? 24;

  static String _env(String key, String fallback) => Platform.environment[key] ?? fallback;
}


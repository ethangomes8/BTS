import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

import '../../config/env.dart';
import '../../domain/entities/entities.dart';
import '../../infrastructure/db/app_database.dart';

class AuthService {
  AuthService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  void ensureAdminSeed() {
    final adminsCount = _db.raw
        .select('SELECT COUNT(*) as c FROM admins')
        .first['c'] as int;
    if (adminsCount != 0) return;

    final passwordHash = BCrypt.hashpw(Env.adminPassword, BCrypt.gensalt());
    final id = _uuid.v4();

    _db.raw.execute(
      'INSERT INTO admins (id, email, password_hash) VALUES (?, ?, ?)',
      [id, Env.adminEmail, passwordHash],
    );
  }

  LoginResult login({
    required String email,
    required String password,
  }) {
    final rows = _db.raw.select(
      'SELECT id, password_hash FROM admins WHERE email = ?',
      [email],
    );
    if (rows.isEmpty) {
      return const LoginResult.failure('Invalid credentials');
    }

    final row = rows.first;
    final adminId = row['id'] as String;
    final hash = row['password_hash'] as String;

    final ok = BCrypt.checkpw(password, hash);
    if (!ok) {
      return const LoginResult.failure('Invalid credentials');
    }

    final now = DateTime.now().toUtc();
    final exp = now.add(Duration(hours: Env.jwtTtlHours));

    final token = JWT(
      {
        'sub': adminId,
        'role': 'admin',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': exp.millisecondsSinceEpoch ~/ 1000,
      },
    ).sign(
      SecretKey(Env.jwtSecret),
    );

    return LoginResult.success(
      adminId: adminId,
      token: token,
      expiresAt: exp,
    );
  }

  AdminUser? userFromJwt(String token) {
    try {
      final jwt = JWT.verify(
        token,
        SecretKey(Env.jwtSecret),
      );

      final sub = jwt.payload['sub'];
      final role = jwt.payload['role'];
      if (sub is! String || role != 'admin') return null;

      final rows = _db.raw.select(
        'SELECT id, email, password_hash FROM admins WHERE id = ?',
        [sub],
      );
      if (rows.isEmpty) return null;

      final row = rows.first;
      return AdminUser(
        id: row['id'] as String,
        email: row['email'] as String,
        passwordHash: row['password_hash'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

class LoginResult {
  final bool ok;
  final String? token;
  final String? adminId;
  final DateTime? expiresAt;
  final String? error;

  const LoginResult._({
    required this.ok,
    this.token,
    this.adminId,
    this.expiresAt,
    this.error,
  });

  const LoginResult.failure(String error)
      : ok = false,
        token = null,
        adminId = null,
        expiresAt = null,
        error = error;

  factory LoginResult.success({
    required String adminId,
    required String token,
    required DateTime expiresAt,
  }) {
    return LoginResult._(
      ok: true,
      adminId: adminId,
      token: token,
      expiresAt: expiresAt,
    );
  }
}


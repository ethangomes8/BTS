import 'package:shelf/shelf.dart';

import '../application/services/auth_service.dart';

String? tokenFromRequest(Request request) {
  final header = request.headers['authorization'] ?? request.headers['Authorization'];
  if (header == null) return null;
  final parts = header.split(' ');
  if (parts.length != 2) return null;
  if (parts.first.toLowerCase() != 'bearer') return null;
  return parts.last;
}

Middleware requireAdmin(AuthService auth) {
  return (Handler innerHandler) {
    return (Request request) {
      final token = tokenFromRequest(request);
      if (token == null) {
        return Response.unauthorized(
          'Missing or invalid Authorization header',
          headers: const {'content-type': 'text/plain; charset=utf-8'},
        );
      }

      final user = auth.userFromJwt(token);
      if (user == null) {
        return Response.unauthorized(
          'Unauthorized',
          headers: const {'content-type': 'text/plain; charset=utf-8'},
        );
      }

      return innerHandler(request);
    };
  };
}

/// Middleware appliqué au niveau serveur qui protège uniquement `/admin/*`.
Middleware adminGuard(AuthService auth) {
  final adminMiddleware = requireAdmin(auth);
  return (Handler innerHandler) {
    final protectedInner = adminMiddleware(innerHandler);
    return (Request request) {
      // Shelf may provide the path with or without a leading "/".
      final rawPath = request.url.path;
      final normalized = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
      if (normalized.startsWith('admin/')) return protectedInner(request);
      return innerHandler(request);
    };
  };
}


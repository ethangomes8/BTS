import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/src/http/api_router.dart';
import '../lib/src/http/auth_middleware.dart';
import '../lib/src/infrastructure/db/app_database.dart';
import '../lib/src/application/services/auth_service.dart';
import '../lib/src/application/services/formats_service.dart';
import '../lib/src/application/services/products_service.dart';
import '../lib/src/application/services/types_service.dart';

Middleware corsHeaders() {
  // Minimal CORS middleware for a typical dev setup.
  return (innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: const {
            'access-control-allow-origin': '*',
            'access-control-allow-headers': 'authorization, content-type',
            'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
          },
        );
      }

      final response = await innerHandler(request);
      return response.change(
        headers: {
          ...response.headers,
          'access-control-allow-origin': '*',
          'access-control-allow-headers': 'authorization, content-type',
          'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        },
      );
    };
  };
}

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final healthRouter = Router()
    ..get('/health', (Request request) {
      return Response.ok('ok', headers: const {'content-type': 'text/plain'});
    });

  final db = await AppDatabase.connectAndMigrate();
  final authService = AuthService(db)..ensureAdminSeed();
  final typesService = TypesService(db);
  final formatsService = FormatsService(db);
  final productsService = ProductsService(db);

  final apiRouter = ApiRouter(
    authService: authService,
    typesService: typesService,
    formatsService: formatsService,
    productsService: productsService,
  ).router;

  final router = Router()
    ..mount('/', healthRouter)
    ..mount('/', apiRouter);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(adminGuard(authService))
      .addHandler(router);

  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  // ignore: avoid_print
  print('API listening on http://${server.address.address}:${server.port}');
}


import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import '../application/services/auth_service.dart';
import '../application/services/formats_service.dart';
import '../application/services/products_service.dart';
import '../application/services/types_service.dart';

class ApiRouter {
  ApiRouter({
    required AuthService authService,
    required TypesService typesService,
    required FormatsService formatsService,
    required ProductsService productsService,
  })  : _authService = authService,
        _typesService = typesService,
        _formatsService = formatsService,
        _productsService = productsService;

  final AuthService _authService;
  final TypesService _typesService;
  final FormatsService _formatsService;
  final ProductsService _productsService;

  Router get router {
    final router = Router();

    // Public: admin login
    router.post('/auth/login', _loginHandler);

    // Admin protected routes
    final admin = Router()
      ..get('/types', _getTypesHandler)
      ..post('/types', _postTypeHandler)
      ..put('/types/<id>', _putTypeHandler)
      ..delete('/types/<id>', _deleteTypeHandler)

      ..get('/formats', _getFormatsHandler)
      ..post('/formats', _postFormatHandler)
      ..put('/formats/<id>', _putFormatHandler)
      ..delete('/formats/<id>', _deleteFormatHandler)

      ..get('/products', _getProductsHandler)
      ..post('/products', _postProductHandler)
      ..put('/products/<id>', _putProductHandler)
      ..delete('/products/<id>', _deleteProductHandler);

    router.mount('/admin', admin);

    return router;
  }

  Response _json(Object data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Response _error(String message, {int statusCode = 400}) {
    return _json({'error': message}, statusCode: statusCode);
  }

  Future<Map<String, dynamic>> _readJson(Request request) async {
    final body = await request.readAsString();
    if (body.trim().isEmpty) return const {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Invalid JSON body');
  }

  Future<Response> _loginHandler(Request request) async {
    try {
      final data = await _readJson(request);
      final email = data['email'] as String?;
      final password = data['password'] as String?;
      if (email == null || password == null) {
        return _error('L\'email ou le mot de passe est manquant.', statusCode: 400);
      }

      final result = _authService.login(email: email, password: password);
      if (!result.ok) {
        return _error(result.error ?? 'Identifiants invalides.', statusCode: 401);
      }

      return _json(
        {
          'token': result.token,
          'adminId': result.adminId,
          'expiresAt': result.expiresAt?.toIso8601String(),
        },
      );
    } catch (e) {
      return _error('Erreur interne lors de la connexion.', statusCode: 500);
    }
  }

  Response _getTypesHandler(Request request) {
    final types = _typesService.list();
    return _json({'items': types.map((t) => {'id': t.id, 'name': t.name}).toList()});
  }

  Future<Response> _postTypeHandler(Request request) async {
    try {
      final data = await _readJson(request);
      final name = data['name'] as String?;
      if (name == null) return _error('Nom manquant.', statusCode: 400);

      final id = _typesService.create(name);
      return _json({'id': id, 'name': name.trim()}, statusCode: 201);
    } catch (e) {
      return _error('Impossible de créer le type.', statusCode: 400);
    }
  }

  Future<Response> _putTypeHandler(Request request, String id) async {
    try {
      final data = await _readJson(request);
      final name = data['name'] as String?;
      if (name == null) return _error('Nom manquant.', statusCode: 400);
      _typesService.update(id, name);
      return _json({'ok': true});
    } catch (e) {
      return _error('Impossible de modifier le type.', statusCode: 400);
    }
  }

  Future<Response> _deleteTypeHandler(Request request, String id) async {
    try {
      _typesService.delete(id);
      return _json({'ok': true});
    } on SqliteException catch (e) {
      // FK violation: the type is used by at least one stock product.
      if (e.extendedResultCode == 1811 || e.extendedResultCode == 787) {
        return _json(
          {'error': 'Impossible de supprimer : ce type est utilisé dans le stock.'},
          statusCode: 409,
        );
      }
      return _error('Erreur interne de la base de données.', statusCode: 500);
    } catch (e) {
      return _error('Impossible de supprimer le type.', statusCode: 400);
    }
  }

  Response _getFormatsHandler(Request request) {
    final formats = _formatsService.list();
    return _json({
      'items': formats
          .map((f) => {
                'id': f.id,
                'label': f.label,
                'volumeMl': f.volumeMl,
                'alcoholPercent': f.alcoholPercent,
              })
          .toList(),
    });
  }

  Future<Response> _postFormatHandler(Request request) async {
    try {
      final data = await _readJson(request);
      final label = data['label'] as String?;
      final volumeMl = data['volumeMl'] as int?;
      final alcoholPercent = (data['alcoholPercent'] as num?)?.toDouble();
      if (label == null || volumeMl == null || alcoholPercent == null) {
        return _error('Le libellé, le volume ou le pourcentage est manquant.', statusCode: 400);
      }
      final id = _formatsService.create(label: label, volumeMl: volumeMl, alcoholPercent: alcoholPercent);
      return _json({ 'id': id }, statusCode: 201);
    } catch (e) {
      return _error('Impossible de créer le format.', statusCode: 400);
    }
  }

  Future<Response> _putFormatHandler(Request request, String id) async {
    try {
      final data = await _readJson(request);
      final label = data['label'] as String?;
      final volumeMl = data['volumeMl'] as int?;
      final alcoholPercent = (data['alcoholPercent'] as num?)?.toDouble();
      if (label == null || volumeMl == null || alcoholPercent == null) {
        return _error('Le libellé, le volume ou le pourcentage est manquant.', statusCode: 400);
      }
      _formatsService.update(id: id, label: label, volumeMl: volumeMl, alcoholPercent: alcoholPercent);
      return _json({'ok': true});
    } catch (e) {
      return _error('Impossible de modifier le format.', statusCode: 400);
    }
  }

  Future<Response> _deleteFormatHandler(Request request, String id) async {
    try {
      _formatsService.delete(id);
      return _json({'ok': true});
    } on SqliteException catch (e) {
      if (e.extendedResultCode == 1811 || e.extendedResultCode == 787) {
        return _json(
          {'error': 'Impossible de supprimer : ce format est utilisé dans le stock.'},
          statusCode: 409,
        );
      }
      return _error('Erreur interne de la base de données.', statusCode: 500);
    } catch (e) {
      return _error('Impossible de supprimer le format.', statusCode: 400);
    }
  }

  Response _getProductsHandler(Request request) {
    final items = _productsService.list();
    return _json({'items': items.map((p) => {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'typeName': p.typeName,
      'formatLabel': p.formatLabel,
      'quantity': p.quantity,
      'imageKey': p.imageKey,
    }).toList()});
  }

  Future<Response> _postProductHandler(Request request) async {
    try {
      final data = await _readJson(request);
      final name = data['name'] as String?;
      final description = data['description'] as String?;
      final typeId = data['typeId'] as String?;
      final formatId = data['formatId'] as String?;
      final quantity = data['quantity'] as int?;
      final imageKey = data['imageKey'] as String?;
      if (name == null || description == null || typeId == null || formatId == null || quantity == null || imageKey == null) {
        return _error('Champs requis manquants.', statusCode: 400);
      }

      final id = _productsService.create(
        name: name,
        description: description,
        typeId: typeId,
        formatId: formatId,
        quantity: quantity,
        imageKey: imageKey,
      );
      return _json({'id': id}, statusCode: 201);
    } catch (e) {
      return _error('Impossible de créer le produit.', statusCode: 400);
    }
  }

  Future<Response> _putProductHandler(Request request, String id) async {
    try {
      final data = await _readJson(request);
      final name = data['name'] as String?;
      final description = data['description'] as String?;
      final typeId = data['typeId'] as String?;
      final formatId = data['formatId'] as String?;
      final quantity = data['quantity'] as int?;
      final imageKey = data['imageKey'] as String?;
      if (name == null || description == null || typeId == null || formatId == null || quantity == null || imageKey == null) {
        return _error('Champs requis manquants.', statusCode: 400);
      }
      _productsService.update(
        id: id,
        name: name,
        description: description,
        typeId: typeId,
        formatId: formatId,
        quantity: quantity,
        imageKey: imageKey,
      );
      return _json({'ok': true});
    } catch (e) {
      return _error('Impossible de modifier le produit.', statusCode: 400);
    }
  }

  Future<Response> _deleteProductHandler(Request request, String id) async {
    try {
      _productsService.delete(id);
      return _json({'ok': true});
    } catch (e) {
      return _error('Impossible de supprimer le produit.', statusCode: 400);
    }
  }
}


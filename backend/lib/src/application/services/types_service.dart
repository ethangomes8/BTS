import '../../domain/entities/entities.dart';
import '../../infrastructure/db/app_database.dart';

class TypesService {
  TypesService(this._db);

  final AppDatabase _db;

  List<ProductType> list() {
    final rows = _db.raw.select(
      'SELECT id, name FROM product_types ORDER BY name ASC',
    );
    return rows
        .map((r) => ProductType(id: r['id'] as String, name: r['name'] as String))
        .toList();
  }

  String create(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('name is required');

    final existing = _db.raw.select(
      'SELECT id FROM product_types WHERE name = ?',
      [trimmed],
    );
    if (existing.isNotEmpty) throw StateError('Type already exists');

    final id = _db.raw.select('SELECT lower(hex(randomblob(16))) as id').first['id'] as String;
    _db.raw.execute(
      'INSERT INTO product_types (id, name) VALUES (?, ?)',
      [id, trimmed],
    );
    return id;
  }

  void update(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('name is required');

    final exists = _db.raw.select(
      'SELECT id FROM product_types WHERE id = ?',
      [id],
    );
    if (exists.isEmpty) throw StateError('Type not found');

    final existing = _db.raw.select(
      'SELECT id FROM product_types WHERE name = ? AND id != ?',
      [trimmed, id],
    );
    if (existing.isNotEmpty) throw StateError('Type already exists');

    _db.raw.execute(
      'UPDATE product_types SET name = ? WHERE id = ?',
      [trimmed, id],
    );
  }

  void delete(String id) {
    final exists = _db.raw.select(
      'SELECT id FROM product_types WHERE id = ?',
      [id],
    );
    if (exists.isEmpty) throw StateError('Type not found');

    _db.raw.execute('DELETE FROM product_types WHERE id = ?', [id]);
  }
}


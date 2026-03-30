import '../../domain/entities/entities.dart';
import '../../infrastructure/db/app_database.dart';

class ProductsService {
  ProductsService(this._db);

  final AppDatabase _db;

  List<StockProductView> list() {
    final rows = _db.raw.select('''
      SELECT
        p.id,
        p.name,
        p.description,
        t.name as type_name,
        f.label as format_label,
        p.quantity,
        p.image_key
      FROM stock_products p
      JOIN product_types t ON p.type_id = t.id
      JOIN product_formats f ON p.format_id = f.id
      ORDER BY p.name ASC
    ''');

    return rows.map((r) {
      return StockProductView(
        id: r['id'] as String,
        name: r['name'] as String,
        description: r['description'] as String,
        typeName: r['type_name'] as String,
        formatLabel: r['format_label'] as String,
        quantity: r['quantity'] as int,
        imageKey: r['image_key'] as String,
      );
    }).toList();
  }

  StockProductView? getById(String id) {
    final rows = _db.raw.select('''
      SELECT
        p.id,
        p.name,
        p.description,
        t.name as type_name,
        f.label as format_label,
        p.quantity,
        p.image_key
      FROM stock_products p
      JOIN product_types t ON p.type_id = t.id
      JOIN product_formats f ON p.format_id = f.id
      WHERE p.id = ?
    ''', [id]);

    if (rows.isEmpty) return null;
    final r = rows.first;
    return StockProductView(
      id: r['id'] as String,
      name: r['name'] as String,
      description: r['description'] as String,
      typeName: r['type_name'] as String,
      formatLabel: r['format_label'] as String,
      quantity: r['quantity'] as int,
      imageKey: r['image_key'] as String,
    );
  }

  String create({
    required String name,
    required String description,
    required String typeId,
    required String formatId,
    required int quantity,
    required String imageKey,
  }) {
    final n = name.trim();
    final d = description.trim();
    final img = imageKey.trim();

    if (n.isEmpty) throw ArgumentError('name is required');
    if (d.isEmpty) throw ArgumentError('description is required');
    if (typeId.trim().isEmpty) throw ArgumentError('typeId is required');
    if (formatId.trim().isEmpty) throw ArgumentError('formatId is required');
    if (quantity < 0) throw ArgumentError('quantity must be >= 0');
    if (img.isEmpty) throw ArgumentError('imageKey is required');

    final id = _db.raw.select('SELECT lower(hex(randomblob(16))) as id').first['id'] as String;
    final now = DateTime.now().toUtc().toIso8601String();
    _db.raw.execute('''
      INSERT INTO stock_products (
        id, name, description, type_id, format_id, quantity, image_key, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [id, n, d, typeId, formatId, quantity, img, now, now]);
    return id;
  }

  void update({
    required String id,
    required String name,
    required String description,
    required String typeId,
    required String formatId,
    required int quantity,
    required String imageKey,
  }) {
    final exists = _db.raw.select(
      'SELECT id FROM stock_products WHERE id = ?',
      [id],
    );
    if (exists.isEmpty) throw StateError('Product not found');

    final n = name.trim();
    final d = description.trim();
    final img = imageKey.trim();

    if (n.isEmpty) throw ArgumentError('name is required');
    if (d.isEmpty) throw ArgumentError('description is required');
    if (typeId.trim().isEmpty) throw ArgumentError('typeId is required');
    if (formatId.trim().isEmpty) throw ArgumentError('formatId is required');
    if (quantity < 0) throw ArgumentError('quantity must be >= 0');
    if (img.isEmpty) throw ArgumentError('imageKey is required');

    _db.raw.execute('''
      UPDATE stock_products
      SET name = ?, description = ?, type_id = ?, format_id = ?, quantity = ?, image_key = ?, updated_at = ?
      WHERE id = ?
    ''', [
      n,
      d,
      typeId,
      formatId,
      quantity,
      img,
      DateTime.now().toUtc().toIso8601String(),
      id
    ]);
  }

  void delete(String id) {
    final exists =
        _db.raw.select('SELECT id FROM stock_products WHERE id = ?', [id]);
    if (exists.isEmpty) throw StateError('Product not found');

    _db.raw.execute('DELETE FROM stock_products WHERE id = ?', [id]);
  }
}


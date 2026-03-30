import '../../domain/entities/entities.dart';
import '../../infrastructure/db/app_database.dart';

class FormatsService {
  FormatsService(this._db);

  final AppDatabase _db;

  List<ProductFormat> list() {
    final rows = _db.raw.select(
      'SELECT id, label, volume_ml, alcohol_percent FROM product_formats ORDER BY volume_ml ASC, alcohol_percent ASC',
    );

    return rows
        .map(
          (r) => ProductFormat(
            id: r['id'] as String,
            label: r['label'] as String,
            volumeMl: r['volume_ml'] as int,
            alcoholPercent: (r['alcohol_percent'] as num).toDouble(),
          ),
        )
        .toList();
  }

  String create({
    required String label,
    required int volumeMl,
    required double alcoholPercent,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) throw ArgumentError('label is required');
    if (volumeMl <= 0) throw ArgumentError('volumeMl must be positive');
    if (alcoholPercent < 0) throw ArgumentError('alcoholPercent must be >= 0');

    final existing = _db.raw.select(
      'SELECT id FROM product_formats WHERE label = ?',
      [trimmed],
    );
    if (existing.isNotEmpty) throw StateError('Format already exists');

    final id = _db.raw.select('SELECT lower(hex(randomblob(16))) as id').first['id'] as String;
    _db.raw.execute(
      'INSERT INTO product_formats (id, label, volume_ml, alcohol_percent) VALUES (?, ?, ?, ?)',
      [id, trimmed, volumeMl, alcoholPercent],
    );
    return id;
  }

  void update({
    required String id,
    required String label,
    required int volumeMl,
    required double alcoholPercent,
  }) {
    final exists = _db.raw.select(
      'SELECT id FROM product_formats WHERE id = ?',
      [id],
    );
    if (exists.isEmpty) throw StateError('Format not found');

    final trimmed = label.trim();
    if (trimmed.isEmpty) throw ArgumentError('label is required');
    if (volumeMl <= 0) throw ArgumentError('volumeMl must be positive');
    if (alcoholPercent < 0) throw ArgumentError('alcoholPercent must be >= 0');

    final existing = _db.raw.select(
      'SELECT id FROM product_formats WHERE label = ? AND id != ?',
      [trimmed, id],
    );
    if (existing.isNotEmpty) throw StateError('Format already exists');

    _db.raw.execute(
      'UPDATE product_formats SET label = ?, volume_ml = ?, alcohol_percent = ? WHERE id = ?',
      [trimmed, volumeMl, alcoholPercent, id],
    );
  }

  void delete(String id) {
    final exists = _db.raw.select(
      'SELECT id FROM product_formats WHERE id = ?',
      [id],
    );
    if (exists.isEmpty) throw StateError('Format not found');

    _db.raw.execute('DELETE FROM product_formats WHERE id = ?', [id]);
  }
}


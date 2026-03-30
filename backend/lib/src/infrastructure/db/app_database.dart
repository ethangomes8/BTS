import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;
  final _uuid = const Uuid();

  static Future<AppDatabase> connectAndMigrate() async {
    final dbPath = File('brasserie.sqlite').absolute.path;
    final db = sqlite3.open(dbPath);

    final instance = AppDatabase._(db);
    instance._migrate();
    instance._seedIfEmpty();

    return instance;
  }

  Database get raw => _db;

  void _migrate() {
    // Force l'enforcement des contraintes FK pour garantir l'intégrité des données.
    _db.execute('PRAGMA foreign_keys = ON;');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS admins (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS product_types (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS product_formats (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL UNIQUE,
        volume_ml INTEGER NOT NULL,
        alcohol_percent REAL NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS stock_products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        type_id TEXT NOT NULL,
        format_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        image_key TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (type_id) REFERENCES product_types(id) ON DELETE RESTRICT,
        FOREIGN KEY (format_id) REFERENCES product_formats(id) ON DELETE RESTRICT
      );
    ''');

    _db.execute('CREATE INDEX IF NOT EXISTS idx_stock_products_type_id ON stock_products(type_id);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_stock_products_format_id ON stock_products(format_id);');
  }

  void _seedIfEmpty() {
    final productsCount =
        _db.select('SELECT COUNT(*) as c FROM stock_products').first['c'] as int;
    if (productsCount != 0) return;

    // Ensure types and formats exist first.
    final typeByName = <String, String>{};
    for (final type in const ['Bière', 'Whisky', 'Gin']) {
      final existing = _db.select(
        'SELECT id FROM product_types WHERE name = ?',
        [type],
      );
      if (existing.isNotEmpty) {
        typeByName[type] = existing.first['id'] as String;
        continue;
      }

      final id = _uuid.v4();
      _db.execute(
        'INSERT INTO product_types (id, name) VALUES (?, ?)',
        [id, type],
      );
      typeByName[type] = id;
    }

    final formatByLabel = <String, String>{};
    // Based on the provided bottle labels in `produits-*.png`.
    const formats = [
      {'label': '25CL - 4°', 'volumeMl': 250, 'alcohol': 4.0},
      {'label': '80CL - 20°', 'volumeMl': 800, 'alcohol': 20.0},
      {'label': '80CL - 60°', 'volumeMl': 800, 'alcohol': 60.0},
    ];

    for (final f in formats) {
      final label = f['label'] as String;
      final existing = _db.select(
        'SELECT id FROM product_formats WHERE label = ?',
        [label],
      );
      if (existing.isNotEmpty) {
        formatByLabel[label] = existing.first['id'] as String;
        continue;
      }

      final id = _uuid.v4();
      _db.execute(
        'INSERT INTO product_formats (id, label, volume_ml, alcohol_percent) VALUES (?, ?, ?, ?)',
        [id, label, f['volumeMl'], f['alcohol']],
      );
      formatByLabel[label] = id;
    }

    final descriptions = _parseDescriptionsFromTxt();

    // Map products to type/format and provided images.
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = <Map<String, Object?>>[
      {
        'name': 'Bière Blonde',
        'type': 'Bière',
        'format': '25CL - 4°',
        'imageKey': 'produits-01.png',
        'quantity': 50,
      },
      {
        'name': 'Bière Brune',
        'type': 'Bière',
        'format': '25CL - 4°',
        'imageKey': 'produits-02.png',
        'quantity': 50,
      },
      {
        'name': 'Bière IPA',
        'type': 'Bière',
        'format': '25CL - 4°',
        'imageKey': 'produits-03.png',
        'quantity': 50,
      },
      {
        'name': 'Gin',
        'type': 'Gin',
        'format': '80CL - 20°',
        'imageKey': 'produits-04.png',
        'quantity': 50,
      },
      {
        'name': 'Whisky',
        'type': 'Whisky',
        'format': '80CL - 60°',
        'imageKey': 'produits-05.png',
        'quantity': 50,
      },
    ];

    final stmt = _db.prepare('''
      INSERT INTO stock_products (
        id, name, description, type_id, format_id, quantity, image_key, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    for (final r in rows) {
      final name = r['name'] as String;
      final description = descriptions[name] ?? '';
      final typeId = typeByName[r['type'] as String]!;
      final formatId = formatByLabel[r['format'] as String]!;

      stmt.execute([
        _uuid.v4(),
        name,
        description,
        typeId,
        formatId,
        r['quantity'] as int,
        r['imageKey'] as String,
        now,
        now,
      ]);
    }

    stmt.dispose();
  }

  Map<String, String> _parseDescriptionsFromTxt() {
    final txtPath = File('../description_produit.txt').absolute.path;
    if (!File(txtPath).existsSync()) return const {};

    final raw = File(txtPath).readAsStringSync();
    final lines = raw
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((l) => l.trimRight())
        .toList();

    final productNames = const [
      'Bière Blonde',
      'Bière Brune',
      'Bière IPA',
      'Whisky',
      'Gin',
    ];

    final result = <String, String>{};
    String? current;
    final buffer = <String>[];

    void flush() {
      if (current == null) return;
      final text = buffer.join('\n').trim();
      if (text.isNotEmpty) result[current!] = text;
      buffer.clear();
    }

    for (final line in lines) {
      if (productNames.contains(line)) {
        flush();
        current = line;
        continue;
      }

      if (line.isEmpty) {
        // Keep paragraph breaks where relevant.
        if (buffer.isNotEmpty) buffer.add('');
        continue;
      }

      if (current != null) buffer.add(line);
    }

    flush();
    return result;
  }
}


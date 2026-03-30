class AdminUser {
  final String id;
  final String email;
  final String passwordHash;

  const AdminUser({
    required this.id,
    required this.email,
    required this.passwordHash,
  });
}

class ProductType {
  final String id;
  final String name;

  const ProductType({
    required this.id,
    required this.name,
  });
}

class ProductFormat {
  final String id;
  final String label;
  final int volumeMl;
  final double alcoholPercent;

  const ProductFormat({
    required this.id,
    required this.label,
    required this.volumeMl,
    required this.alcoholPercent,
  });
}

class StockProduct {
  final String id;
  final String name;
  final String description;
  final String typeId;
  final String formatId;
  final int quantity;
  final String imageKey;

  const StockProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.typeId,
    required this.formatId,
    required this.quantity,
    required this.imageKey,
  });
}

class StockProductView {
  final String id;
  final String name;
  final String description;
  final String typeName;
  final String formatLabel;
  final int quantity;
  final String imageKey;

  const StockProductView({
    required this.id,
    required this.name,
    required this.description,
    required this.typeName,
    required this.formatLabel,
    required this.quantity,
    required this.imageKey,
  });
}


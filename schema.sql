-- ============================================================================
-- MLD - Modèle Logique de Données
-- Brasserie Terroir & Savoirs (BTS SIO E6)
-- ============================================================================

-- Active les contraintes de clés étrangères
PRAGMA foreign_keys = ON;

-- ============================================================================
-- Table: admins
-- Description: Compte administrateur pour l'authentification
-- ============================================================================
CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL
);

-- ============================================================================
-- Table: product_types
-- Description: Types de produits (Bière, Whisky, Gin, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS product_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

-- ============================================================================
-- Table: product_formats
-- Description: Formats/bouteilles disponibles (volume et % d'alcool)
-- ============================================================================
CREATE TABLE IF NOT EXISTS product_formats (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL UNIQUE,
  volume_ml INTEGER NOT NULL,
  alcohol_percent REAL NOT NULL
);

-- ============================================================================
-- Table: stock_products
-- Description: Stock des produits avec références au type et au format
-- ============================================================================
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

-- ============================================================================
-- Index pour améliorer les performances
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_stock_products_type_id ON stock_products(type_id);
CREATE INDEX IF NOT EXISTS idx_stock_products_format_id ON stock_products(format_id);

-- ============================================================================
-- Données de seed (valeurs par défaut)
-- ============================================================================

-- Types de produits
INSERT OR IGNORE INTO product_types (id, name) VALUES 
  ('type_biere', 'Bière'),
  ('type_whisky', 'Whisky'),
  ('type_gin', 'Gin');

-- Formats/bouteilles
INSERT OR IGNORE INTO product_formats (id, label, volume_ml, alcohol_percent) VALUES 
  ('fmt_25cl_4', '25CL - 4°', 250, 4.0),
  ('fmt_80cl_20', '80CL - 20°', 800, 20.0),
  ('fmt_80cl_60', '80CL - 60°', 800, 60.0);

-- Produits (exemple de seed)
INSERT OR IGNORE INTO stock_products 
  (id_product, name, description, type_id, format_id, quantity, image_key, created_at, updated_at) 
VALUES 
  ('prod_1', 'Bière Blonde', 'Une bière blonde légère et rafraîchissante', 'type_biere', 'fmt_25cl_4', 50, 'produits-01.png', datetime('now'), datetime('now')),
  ('prod_2', 'Bière Brune', 'Une bière brune riche et maltée', 'type_biere', 'fmt_25cl_4', 50, 'produits-02.png', datetime('now'), datetime('now')),
  ('prod_3', 'Bière IPA', 'Une bière IPA houblonnée et puissante', 'type_biere', 'fmt_25cl_4', 50, 'produits-03.png', datetime('now'), datetime('now')),
  ('prod_4', 'Gin', 'Un gin distillé avec soin', 'type_gin', 'fmt_80cl_20', 50, 'produits-04.png', datetime('now'), datetime('now')),
  ('prod_5', 'Whisky', 'Un whisky premium vieilli en fûts', 'type_whisky', 'fmt_80cl_60', 50, 'produits-05.png', datetime('now'), datetime('now'));

-- ============================================================================
-- MLD - Diagramme relationnel
-- ============================================================================
--
-- admins
-- ├─ id (PK)
-- ├─ email (UQ)
-- └─ password_hash
--
-- product_types
-- ├─ id (PK)
-- └─ name (UQ)
--
-- product_formats
-- ├─ id (PK)
-- ├─ label (UQ)
-- ├─ volume_ml
-- └─ alcohol_percent
--
-- stock_products
-- ├─ id (PK)
-- ├─ name
-- ├─ description
-- ├─ type_id (FK → product_types.id)
-- ├─ format_id (FK → product_formats.id)
-- ├─ quantity
-- ├─ image_key
-- ├─ created_at
-- └─ updated_at
--
-- Relations:
-- - stock_products N→1 product_types (type_id)
-- - stock_products N→1 product_formats (format_id)
--

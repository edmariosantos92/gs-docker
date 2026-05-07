CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  slug VARCHAR(180) NOT NULL UNIQUE,
  description TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  image_url VARCHAR(600) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  category VARCHAR(80) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS login_events (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NULL,
  success TINYINT(1) NOT NULL DEFAULT 0,
  ip_address VARCHAR(80) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_login_events_customer_id (customer_id),
  CONSTRAINT fk_login_events_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO products (sku, name, slug, description, price, image_url, stock, category)
VALUES
  ('FONE-BT-PRO', 'Fone Bluetooth Pro', 'fone-bluetooth-pro', 'Fone sem fio com cancelamento de ruído, bateria de longa duração e estojo carregador.', 249.90, '/media/products/fone-bluetooth-pro.jpg', 25, 'Áudio'),
  ('SMART-FIT-ONE', 'Smartwatch Fit One', 'smartwatch-fit-one', 'Relógio inteligente com monitoramento de saúde, notificações e bateria para vários dias.', 399.90, '/media/products/smartwatch-fit-one.jpg', 18, 'Wearables'),
  ('MOCHILA-URBAN', 'Mochila Urban Tech', 'mochila-urban-tech', 'Mochila resistente para notebook, com compartimentos inteligentes e design urbano.', 189.90, '/media/products/mochila-urban-tech.jpg', 32, 'Acessórios')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description),
  price = VALUES(price),
  image_url = VALUES(image_url),
  stock = VALUES(stock),
  category = VALUES(category);

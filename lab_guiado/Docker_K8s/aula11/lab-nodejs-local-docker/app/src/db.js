import mysql from 'mysql2/promise';
import { config } from './config.js';

let pool;

export function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: config.db.host,
      port: config.db.port,
      database: config.db.database,
      user: config.db.user,
      password: config.db.password,
      waitForConnections: true,
      connectionLimit: 8,
      queueLimit: 0,
      ssl: config.db.ssl ? { minVersion: 'TLSv1.2', rejectUnauthorized: false } : undefined
    });
  }
  return pool;
}

export async function pingDb() {
  const [rows] = await getPool().query('SELECT 1 AS ok');
  return rows[0]?.ok === 1;
}

export async function listProducts() {
  const [rows] = await getPool().query(
    'SELECT id, sku, name, slug, description, price, image_url, stock, category FROM products ORDER BY id ASC LIMIT 20'
  );
  return rows;
}

export async function getProductBySlug(slug) {
  const [rows] = await getPool().execute(
    'SELECT id, sku, name, slug, description, price, image_url, stock, category FROM products WHERE slug = ? LIMIT 1',
    [slug]
  );
  return rows[0] || null;
}

export async function searchProductsMysql(term) {
  const like = `%${term}%`;
  const [rows] = await getPool().execute(
    `SELECT id, sku, name, slug, description, price, image_url, stock, category
       FROM products
      WHERE name LIKE ? OR description LIKE ? OR category LIKE ? OR sku LIKE ?
      ORDER BY name ASC
      LIMIT 20`,
    [like, like, like, like]
  );
  return rows;
}

export async function createCustomer({ name, email, passwordHash }) {
  const [result] = await getPool().execute(
    'INSERT INTO customers (name, email, password_hash) VALUES (?, ?, ?)',
    [name, email, passwordHash]
  );
  return result.insertId;
}

export async function findCustomerByEmail(email) {
  const [rows] = await getPool().execute(
    'SELECT id, name, email, password_hash FROM customers WHERE email = ? LIMIT 1',
    [email]
  );
  return rows[0] || null;
}

export async function insertLoginEvent(customerId, success, ip) {
  await getPool().execute(
    'INSERT INTO login_events (customer_id, success, ip_address) VALUES (?, ?, ?)',
    [customerId || null, success ? 1 : 0, ip || null]
  );
}

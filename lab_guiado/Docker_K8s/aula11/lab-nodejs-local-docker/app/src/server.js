import express from 'express';
import morgan from 'morgan';
import bcrypt from 'bcryptjs';
import { config } from './config.js';
import {
  createCustomer,
  findCustomerByEmail,
  getProductBySlug,
  insertLoginEvent,
  listProducts,
  pingDb,
  searchProductsMysql
} from './db.js';
import { getJson, pingCache, setJson } from './cache.js';
import { pingSearch, searchProductsElastic } from './search.js';
import { formPage, homePage, productPage, searchPage, statusPage } from './views.js';

const app = express();

app.disable('x-powered-by');
app.use(morgan('combined'));
app.use(express.urlencoded({ extended: false }));
app.use(express.json());
app.use('/assets', express.static('public/assets', { maxAge: '1h', immutable: false }));
app.use('/media', express.static(config.media.dir, { maxAge: '1h', immutable: false }));

app.get('/healthz', (_req, res) => {
  res.status(200).json({ status: 'ok', app: config.app.name, timestamp: new Date().toISOString() });
});

app.get('/readyz', async (_req, res) => {
  const db = await safe(pingDb());
  const cache = await pingCache();
  const elasticsearch = await pingSearch();
  const ok = db.ok === true;
  res.status(ok ? 200 : 503).json({ ok, db, cache, elasticsearch });
});

app.get('/status', async (_req, res) => {
  const status = {
    app: config.app,
    db: await safe(pingDb()),
    cache: await pingCache(),
    elasticsearch: await pingSearch()
  };
  res.send(statusPage(status));
});

app.get('/', async (_req, res, next) => {
  try {
    const products = await listProducts();
    res.send(homePage(products));
  } catch (err) {
    next(err);
  }
});

app.get('/produto/:slug', async (req, res, next) => {
  try {
    const product = await getProductBySlug(req.params.slug);
    res.status(product ? 200 : 404).send(productPage(product));
  } catch (err) {
    next(err);
  }
});

app.get('/busca', async (req, res, next) => {
  try {
    const query = String(req.query.q || '').trim();
    if (!query) return res.send(searchPage({ query: '', products: [], source: '' }));
    const result = await searchProducts(query);
    res.send(searchPage({ query, products: result.products, source: result.source }));
  } catch (err) {
    next(err);
  }
});

app.get('/cadastro', (_req, res) => res.send(formPage({ type: 'cadastro' })));
app.get('/login', (_req, res) => res.send(formPage({ type: 'login' })));

app.post('/cadastro', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');

    if (!name || !email || password.length < 6) {
      return res.status(400).send(formPage({ type: 'cadastro', error: 'Preencha nome, e-mail e uma senha com pelo menos 6 caracteres.' }));
    }

    const passwordHash = await bcrypt.hash(password, 10);
    await createCustomer({ name, email, passwordHash });
    res.send(formPage({ type: 'login', message: 'Cadastro realizado com sucesso. Agora faça login.' }));
  } catch (err) {
    const message = err?.code === 'ER_DUP_ENTRY' ? 'E-mail já cadastrado.' : err.message;
    res.status(500).send(formPage({ type: 'cadastro', error: message }));
  }
});

app.post('/login', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  try {
    const customer = await findCustomerByEmail(email);
    const valid = customer ? await bcrypt.compare(password, customer.password_hash) : false;
    await insertLoginEvent(customer?.id, valid, req.ip);
    if (!valid) return res.status(401).send(formPage({ type: 'login', error: 'E-mail ou senha inválidos.' }));
    res.cookie(config.app.sessionName, `customer-${customer.id}`, { httpOnly: true, sameSite: 'lax' });
    res.send(formPage({ type: 'login', message: `Bem-vindo, ${customer.name}! Login validado com MySQL local.` }));
  } catch (err) {
    res.status(500).send(formPage({ type: 'login', error: err.message }));
  }
});

app.get('/api/products', async (_req, res, next) => {
  try {
    res.json({ data: await listProducts() });
  } catch (err) {
    next(err);
  }
});

app.get('/api/products/:slug', async (req, res, next) => {
  try {
    const product = await getProductBySlug(req.params.slug);
    if (!product) return res.status(404).json({ error: 'Produto não encontrado' });
    res.json({ data: product });
  } catch (err) {
    next(err);
  }
});

app.get('/api/search', async (req, res, next) => {
  try {
    const query = String(req.query.q || '').trim();
    if (!query) return res.json({ data: [], source: 'empty' });
    const result = await searchProducts(query);
    res.json({ data: result.products, source: result.source });
  } catch (err) {
    next(err);
  }
});

app.post('/api/customers', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    const passwordHash = await bcrypt.hash(String(password || ''), 10);
    const id = await createCustomer({ name, email: String(email || '').toLowerCase(), passwordHash });
    res.status(201).json({ id, name, email });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post('/api/login', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const customer = await findCustomerByEmail(email);
  const valid = customer ? await bcrypt.compare(password, customer.password_hash) : false;
  await insertLoginEvent(customer?.id, valid, req.ip);
  if (!valid) return res.status(401).json({ error: 'E-mail ou senha inválidos' });
  res.json({ ok: true, customer: { id: customer.id, name: customer.name, email: customer.email } });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).send(`<pre>Erro na aplicação: ${escapeHtml(err.message)}</pre>`);
});

async function searchProducts(query) {
  const normalized = query.toLowerCase();
  const cacheKey = `search:v1:${normalized}`;
  const cached = await getJson(cacheKey);
  if (cached) return { products: cached, source: 'redis-cache' };

  try {
    const elasticProducts = await searchProductsElastic(query);
    if (elasticProducts) {
      await setJson(cacheKey, elasticProducts);
      return { products: elasticProducts, source: 'elasticsearch' };
    }
  } catch (err) {
    console.warn('[search] Elasticsearch falhou, usando fallback MySQL:', err.message);
  }

  const mysqlProducts = await searchProductsMysql(query);
  await setJson(cacheKey, mysqlProducts);
  return { products: mysqlProducts, source: 'mysql-fallback' };
}

async function safe(promise) {
  try {
    const ok = await promise;
    return { ok };
  } catch (err) {
    return { ok: false, error: err.message };
  }
}

function escapeHtml(value = '') {
  return String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

app.listen(config.app.port, () => {
  console.log(`${config.app.name} ouvindo na porta ${config.app.port}`);
});

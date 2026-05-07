import { config } from './config.js';

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

function layout({ title, content, active = '' }) {
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${escapeHtml(title)} | ${escapeHtml(config.app.name)}</title>
  <link rel="stylesheet" href="/assets/style.css" />
</head>
<body>
  <header class="topbar">
    <a class="brand" href="/">${escapeHtml(config.app.name)}</a>
    <nav>
      <a class="${active === 'home' ? 'active' : ''}" href="/">Home</a>
      <a class="${active === 'busca' ? 'active' : ''}" href="/busca">Busca</a>
      <a class="${active === 'cadastro' ? 'active' : ''}" href="/cadastro">Cadastro</a>
      <a class="${active === 'login' ? 'active' : ''}" href="/login">Login</a>
    </nav>
  </header>

  <main>
    ${content}
  </main>

  <footer class="footer">
    <span>EC2 + Docker + Traefik + RDS MySQL + S3 + Valkey + OpenSearch</span>
    <span class="pill muted">API interna em /api/*</span>
  </footer>
</body>
</html>`;
}

export function homePage(products) {
  const cards = products.map(productCard).join('');
  return layout({
    title: 'Home',
    active: 'home',
    content: `
<section class="hero">
  <div>
    <p class="eyebrow">Lab mão na massa</p>
    <h1>Webcommerce Node.js rodando em Docker na AWS</h1>
    <p>Aplicação simples para demonstrar container, imagem no ECR, banco RDS, cache Valkey, mídia no S3 e busca com OpenSearch.</p>
    <form class="searchbar" action="/busca" method="get">
      <input type="search" name="q" placeholder="Buscar produto..." />
      <button type="submit">Buscar</button>
    </form>
  </div>
</section>
<section>
  <div class="section-title">
    <h2>Produtos em destaque</h2>
    <span>Imagens vindas do S3</span>
  </div>
  <div class="grid">${cards}</div>
</section>`
  });
}

export function productPage(product) {
  if (!product) {
    return layout({ title: 'Produto não encontrado', content: '<section class="card"><h1>Produto não encontrado</h1><p>Volte para a home e escolha outro produto.</p></section>' });
  }
  return layout({
    title: product.name,
    content: `
<section class="product-detail">
  <img src="${escapeAttr(product.image_url)}" alt="${escapeAttr(product.name)}" />
  <div class="card detail-card">
    <p class="eyebrow">${escapeHtml(product.category)}</p>
    <h1>${escapeHtml(product.name)}</h1>
    <p>${escapeHtml(product.description)}</p>
    <strong class="price">${money.format(Number(product.price))}</strong>
    <p class="stock">Estoque: ${Number(product.stock)}</p>
    <a class="button" href="/">Voltar</a>
  </div>
</section>`
  });
}

export function searchPage({ query, products, source }) {
  const result = products.length
    ? `<div class="grid">${products.map(productCard).join('')}</div>`
    : '<div class="card"><p>Nenhum produto encontrado.</p></div>';

  return layout({
    title: 'Busca',
    active: 'busca',
    content: `
<section class="card">
  <h1>Busca de produtos</h1>
  <p>Consulta usa cache Valkey quando configurado. A busca principal usa Amazon OpenSearch e faz fallback para MySQL se necessário.</p>
  <form class="searchbar" action="/busca" method="get">
    <input type="search" name="q" value="${escapeAttr(query || '')}" placeholder="Ex: fone, smartwatch, mochila" />
    <button type="submit">Buscar</button>
  </form>
  ${query ? `<span class="pill">Fonte do resultado: ${escapeHtml(source)}</span>` : ''}
</section>
${query ? result : ''}`
  });
}

export function formPage({ type, message = '', error = '' }) {
  const isLogin = type === 'login';
  const fields = isLogin ? '' : `<label>Nome<input name="name" required placeholder="Seu nome" /></label>`;
  return layout({
    title: isLogin ? 'Login' : 'Cadastro',
    active: isLogin ? 'login' : 'cadastro',
    content: `
<section class="form-wrapper card">
  <h1>${isLogin ? 'Login do cliente' : 'Cadastro de cliente'}</h1>
  <p>${isLogin ? 'Valide o acesso de um cliente cadastrado no RDS MySQL.' : 'Crie um cliente no RDS MySQL.'}</p>
  ${message ? `<div class="alert success">${escapeHtml(message)}</div>` : ''}
  ${error ? `<div class="alert error">${escapeHtml(error)}</div>` : ''}
  <form method="post" action="/${isLogin ? 'login' : 'cadastro'}" class="form">
    ${fields}
    <label>E-mail<input type="email" name="email" required placeholder="cliente@email.com" /></label>
    <label>Senha<input type="password" name="password" required placeholder="Senha" /></label>
    <button type="submit">${isLogin ? 'Entrar' : 'Cadastrar'}</button>
  </form>
</section>`
  });
}

export function statusPage(status) {
  return layout({
    title: 'Status',
    content: `<section class="card"><h1>Status do LAB</h1><pre>${escapeHtml(JSON.stringify(status, null, 2))}</pre></section>`
  });
}

function productCard(product) {
  return `<article class="card product-card">
    <img src="${escapeAttr(product.image_url)}" alt="${escapeAttr(product.name)}" loading="lazy" />
    <div>
      <span class="category">${escapeHtml(product.category)}</span>
      <h3>${escapeHtml(product.name)}</h3>
      <p>${escapeHtml(product.description)}</p>
      <strong>${money.format(Number(product.price))}</strong>
      <a class="button" href="/produto/${escapeAttr(product.slug)}">Ver produto</a>
    </div>
  </article>`;
}

function escapeHtml(value = '') {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function escapeAttr(value = '') {
  return escapeHtml(value).replaceAll('`', '&#096;');
}

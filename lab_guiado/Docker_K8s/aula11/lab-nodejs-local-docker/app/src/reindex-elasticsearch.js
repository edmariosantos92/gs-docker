import { listProducts } from './db.js';
import { indexProducts, isSearchConfigured } from './search.js';

if (!isSearchConfigured()) {
  console.error('Elasticsearch não configurado. Confira ELASTICSEARCH_ENDPOINT.');
  process.exit(1);
}

try {
  const products = await listProducts();
  const total = await indexProducts(products);
  console.log(`Indexação concluída. Produtos enviados para o Elasticsearch: ${total}`);
  process.exit(0);
} catch (err) {
  console.error('Falha ao indexar produtos:', err);
  process.exit(1);
}

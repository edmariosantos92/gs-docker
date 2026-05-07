import { listProducts } from './db.js';
import { indexProducts, isOpenSearchConfigured } from './search.js';

if (!isOpenSearchConfigured()) {
  console.error('OpenSearch não configurado. Confira OPENSEARCH_ENDPOINT, OPENSEARCH_USERNAME e OPENSEARCH_PASSWORD.');
  process.exit(1);
}

try {
  const products = await listProducts();
  const total = await indexProducts(products);
  console.log(`Indexação concluída. Produtos enviados para o OpenSearch: ${total}`);
  process.exit(0);
} catch (err) {
  console.error('Falha ao indexar produtos:', err);
  process.exit(1);
}

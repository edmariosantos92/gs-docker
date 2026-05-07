import { Client } from '@opensearch-project/opensearch';
import { config } from './config.js';

let client;

export function isOpenSearchConfigured() {
  return Boolean(config.opensearch.endpoint && config.opensearch.username && config.opensearch.password);
}

export function getSearchClient() {
  if (!isOpenSearchConfigured()) return null;
  if (!client) {
    client = new Client({
      node: config.opensearch.endpoint,
      auth: {
        username: config.opensearch.username,
        password: config.opensearch.password
      },
      ssl: {
        rejectUnauthorized: true
      },
      requestTimeout: 3000
    });
  }
  return client;
}

export async function pingOpenSearch() {
  const search = getSearchClient();
  if (!search) return { configured: false, ok: false };
  try {
    const response = await search.ping();
    return { configured: true, ok: response.statusCode >= 200 && response.statusCode < 300 };
  } catch (err) {
    return { configured: true, ok: false, error: err.message };
  }
}

export async function ensureProductIndex() {
  const search = getSearchClient();
  if (!search) return false;
  const exists = await search.indices.exists({ index: config.opensearch.index });
  if (exists.statusCode === 404) {
    await search.indices.create({
      index: config.opensearch.index,
      body: {
        settings: {
          number_of_shards: 1,
          number_of_replicas: 0,
          analysis: {
            analyzer: {
              lab_text: {
                type: 'standard'
              }
            }
          }
        },
        mappings: {
          properties: {
            id: { type: 'integer' },
            sku: { type: 'keyword' },
            name: { type: 'text', analyzer: 'lab_text' },
            slug: { type: 'keyword' },
            description: { type: 'text', analyzer: 'lab_text' },
            category: { type: 'keyword' },
            price: { type: 'float' },
            image_url: { type: 'keyword' },
            stock: { type: 'integer' }
          }
        }
      }
    });
  }
  return true;
}

export async function indexProducts(products) {
  const search = getSearchClient();
  if (!search) return 0;
  await ensureProductIndex();

  const body = products.flatMap((product) => [
    { index: { _index: config.opensearch.index, _id: String(product.id) } },
    product
  ]);

  if (!body.length) return 0;
  const response = await search.bulk({ refresh: true, body });
  if (response.body.errors) {
    throw new Error('Falha ao indexar alguns produtos no OpenSearch');
  }
  return products.length;
}

export async function searchProductsOpenSearch(term) {
  const search = getSearchClient();
  if (!search) return null;

  const response = await search.search({
    index: config.opensearch.index,
    body: {
      size: 20,
      query: {
        multi_match: {
          query: term,
          fields: ['name^3', 'description', 'category', 'sku^2'],
          fuzziness: 'AUTO'
        }
      }
    }
  });

  return response.body.hits.hits.map((hit) => hit._source);
}

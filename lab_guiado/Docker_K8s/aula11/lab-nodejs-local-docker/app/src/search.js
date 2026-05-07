import { Client } from '@elastic/elasticsearch';
import { config } from './config.js';

let client;

export function isSearchConfigured() {
  return Boolean(config.search.endpoint);
}

export function getSearchClient() {
  if (!isSearchConfigured()) return null;
  if (!client) {
    const options = {
      node: config.search.endpoint,
      requestTimeout: 3000
    };

    if (config.search.username && config.search.password) {
      options.auth = {
        username: config.search.username,
        password: config.search.password
      };
    }

    client = new Client(options);
  }
  return client;
}

export async function pingSearch() {
  const search = getSearchClient();
  if (!search) return { configured: false, ok: false };
  try {
    const response = await search.ping();
    const ok = response === true || response?.statusCode === 200 || response?.body === true;
    return { configured: true, ok: Boolean(ok) };
  } catch (err) {
    return { configured: true, ok: false, error: err.message };
  }
}

export async function ensureProductIndex() {
  const search = getSearchClient();
  if (!search) return false;

  const existsResponse = await search.indices.exists({ index: config.search.index });
  const exists = existsResponse === true || existsResponse?.body === true || existsResponse?.statusCode === 200;

  if (!exists) {
    await search.indices.create({
      index: config.search.index,
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
    });
  }
  return true;
}

export async function indexProducts(products) {
  const search = getSearchClient();
  if (!search) return 0;
  await ensureProductIndex();

  const operations = products.flatMap((product) => [
    { index: { _index: config.search.index, _id: String(product.id) } },
    product
  ]);

  if (!operations.length) return 0;
  const response = await search.bulk({ refresh: true, operations });
  const hasErrors = response?.errors === true || response?.body?.errors === true;
  if (hasErrors) {
    throw new Error('Falha ao indexar alguns produtos no Elasticsearch');
  }
  return products.length;
}

export async function searchProductsElastic(term) {
  const search = getSearchClient();
  if (!search) return null;

  const response = await search.search({
    index: config.search.index,
    size: 20,
    query: {
      multi_match: {
        query: term,
        fields: ['name^3', 'description', 'category', 'sku^2'],
        fuzziness: 'AUTO'
      }
    }
  });

  const hits = response?.hits?.hits || response?.body?.hits?.hits || [];
  return hits.map((hit) => hit._source);
}

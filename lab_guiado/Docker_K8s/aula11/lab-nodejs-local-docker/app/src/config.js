export const config = {
  app: {
    name: process.env.APP_NAME || 'SkyNalytix Lab Node.js Local',
    url: process.env.APP_URL || 'http://localhost:8080',
    sessionName: process.env.APP_SESSION_NAME || 'LABNODELOCALSESSID',
    port: Number(process.env.PORT || 3000),
    nodeEnv: process.env.NODE_ENV || 'production',
    adminToken: process.env.ADMIN_TOKEN || 'local-dev-token'
  },
  db: {
    host: process.env.DB_HOST || 'mysql',
    port: Number(process.env.DB_PORT || 3306),
    database: process.env.DB_NAME || 'labnodejs',
    user: process.env.DB_USER || 'labnodejs_user',
    password: process.env.DB_PASSWORD || 'labnodejs_pass',
    ssl: process.env.DB_SSL === 'true'
  },
  cache: {
    host: process.env.CACHE_HOST || 'redis',
    port: Number(process.env.CACHE_PORT || 6379),
    tls: process.env.CACHE_TLS === 'true',
    ttlSeconds: Number(process.env.CACHE_TTL_SECONDS || 60)
  },
  search: {
    endpoint: process.env.ELASTICSEARCH_ENDPOINT || process.env.OPENSEARCH_ENDPOINT || 'http://elasticsearch:9200',
    username: process.env.ELASTICSEARCH_USERNAME || '',
    password: process.env.ELASTICSEARCH_PASSWORD || '',
    index: process.env.ELASTICSEARCH_INDEX || process.env.OPENSEARCH_INDEX || 'products'
  },
  media: {
    dir: process.env.MEDIA_DIR || '/app/public/media'
  }
};

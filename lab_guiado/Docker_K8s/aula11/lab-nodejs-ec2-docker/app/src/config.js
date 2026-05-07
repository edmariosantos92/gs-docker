export const config = {
  app: {
    name: process.env.APP_NAME || 'SkyNalytix Lab Node.js',
    url: process.env.APP_URL || 'http://localhost',
    sessionName: process.env.APP_SESSION_NAME || 'LABNODESESSID',
    port: Number(process.env.PORT || 3000),
    nodeEnv: process.env.NODE_ENV || 'production',
    adminToken: process.env.ADMIN_TOKEN || 'troque-este-token'
  },
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    database: process.env.DB_NAME || 'labnodejs',
    user: process.env.DB_USER || 'labnodejs_user',
    password: process.env.DB_PASSWORD || '',
    ssl: process.env.DB_SSL === 'true'
  },
  cache: {
    host: process.env.CACHE_HOST || '',
    port: Number(process.env.CACHE_PORT || 6379),
    tls: process.env.CACHE_TLS === 'true',
    ttlSeconds: Number(process.env.CACHE_TTL_SECONDS || 60)
  },
  opensearch: {
    endpoint: process.env.OPENSEARCH_ENDPOINT || '',
    username: process.env.OPENSEARCH_USERNAME || '',
    password: process.env.OPENSEARCH_PASSWORD || '',
    index: process.env.OPENSEARCH_INDEX || 'products'
  },
  aws: {
    region: process.env.AWS_REGION || 'us-east-1',
    s3Bucket: process.env.S3_BUCKET || ''
  }
};

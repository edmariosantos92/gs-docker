const http = require('http');

const port = Number(process.env.PORT || 3000);
const appName = process.env.APP_NAME || 'Lab Docker Scout Node.js';
const appVersion = process.env.APP_VERSION || '1.0.0';
const runtimeProfile = process.env.RUNTIME_PROFILE || 'demo';

function json(res, statusCode, payload) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store'
  });
  res.end(JSON.stringify(payload, null, 2));
}

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/info') {
    return json(res, 200, {
      message: appName,
      status: 'ok',
      appVersion,
      runtimeProfile,
      nodeVersion: process.version,
      platform: process.platform,
      uptimeSeconds: Math.round(process.uptime())
    });
  }

  if (req.url === '/healthz') {
    return json(res, 200, {
      status: 'healthy'
    });
  }

  return json(res, 404, {
    error: 'not_found',
    path: req.url
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`app=${appName} version=${appVersion} profile=${runtimeProfile} listening=0.0.0.0:${port} node=${process.version}`);
});

process.on('SIGTERM', () => {
  console.log('signal=SIGTERM action=shutdown');
  server.close(() => process.exit(0));
});

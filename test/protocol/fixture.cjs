'use strict';
const http = require('node:http');
const { spawn } = require('node:child_process');
const path = require('node:path');

// One deliberately small local fixture shared by the OCaml and pinned JS tests.
// Multipart assertions compare the file bytes, not the random boundary or a substring.
exports.start = async function () {
  const server = http.createServer(async (req, res) => {
    try {
      const chunks = [];
      for await (const chunk of req) chunks.push(chunk);
      const data = Buffer.concat(chunks);
      const pathname = new URL(req.url, 'http://localhost').pathname;
      if (pathname === '/style.css') {
        res.writeHead(200, { 'content-type': 'text/css' }).end('body { color: red } #one { padding: 12px }');
      } else if (pathname === '/bytes') {
        res.writeHead(200, { 'content-type': 'application/octet-stream' }).end(Buffer.from([0, 255, 128, 1, 13, 10]));
      } else if (pathname === '/echo') {
        let fileBase64 = null;
        const type = req.headers['content-type'] || '';
        if (type.startsWith('multipart/form-data;')) {
          const boundary = /boundary=(?:"([^"]+)"|([^;]+))/.exec(type);
          if (!boundary) throw new Error('missing multipart boundary');
          const marker = Buffer.from(`\r\n--${boundary[1] || boundary[2]}--\r\n`);
          const start = data.indexOf(Buffer.from('\r\n\r\n'));
          const end = data.lastIndexOf(marker);
          if (start < 0 || end < start + 4 || end + marker.length !== data.length)
            throw new Error('unexpected single-file multipart framing');
          fileBase64 = data.subarray(start + 4, end).toString('base64');
        }
        res.writeHead(200, { 'content-type': 'application/json' })
          .end(JSON.stringify({ bodyBase64: data.toString('base64'), fileBase64 }));
      } else {
        res.writeHead(200, { 'content-type': 'text/html' }).end(
          '<!doctype html><title>protocol fixture</title><link rel="stylesheet" href="/style.css">' +
          '<p id="one">styled</p><input id="file" type="file" multiple><button id="button">button</button>');
      }
    } catch (e) {
      console.error(e);
      res.writeHead(500).end(String(e));
    }
  });
  server.requestTimeout = 5000;
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  return { server, url: `http://127.0.0.1:${server.address().port}` };
};
exports.close = server => { server.closeAllConnections(); server.close(); };

if (require.main === module) (async () => {
  const { server, url } = await exports.start();
  // timeout also bounds teardown and kills the process group after the grace period.
  const child = spawn('/usr/bin/timeout', ['--signal=TERM', '--kill-after=3s', '35s', path.resolve(process.argv[2])],
    { env: { ...process.env, PROTOCOL_TEST_URL: url }, stdio: 'inherit' });
  child.on('error', e => { console.error(e); exports.close(server); process.exitCode = 1; });
  child.on('exit', (code, signal) => { exports.close(server); process.exitCode = signal ? 1 : code; });
})().catch(e => { console.error(e); process.exitCode = 1; });

#!/usr/bin/env node
// Vendors the protocol specification of a Playwright release and pins its driver.
//
//   node tools/update_protocol.js 1.66.0
//
// Downloads packages/protocol/spec/*.yml of the tag v<version> from GitHub into protocol/spec,
// asks the npm registry for the tarball and the checksum of playwright-core@<version>, and
// writes protocol/manifest.json.  Nothing is changed unless everything could be fetched.
// The next step is `dune build @gen --auto-promote`; see doc/dev/protocol.md.
//
// GITHUB_TOKEN, if set, is used for the requests to GitHub, whose anonymous rate limit is low.

'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const version = process.argv[2] || '';
if (!/^\d+\.\d+\.\d+(-[\w.]+)?$/.test(version)) {
  console.error('usage: node tools/update_protocol.js VERSION    for example: 1.66.0');
  process.exit(2);
}

const tag = 'v' + version;
const repository = 'https://api.github.com/repos/microsoft/playwright';
const specPath = 'packages/protocol/spec';
const github = {
  'user-agent': 'ocaml-playwright',
  accept: 'application/vnd.github+json',
  ...(process.env.GITHUB_TOKEN ? { authorization: 'Bearer ' + process.env.GITHUB_TOKEN } : {}),
};

async function get(url, headers = {}) {
  const response = await fetch(url, { headers, signal: AbortSignal.timeout(120000) });
  if (!response.ok) throw new Error(`${url}: HTTP ${response.status} ${response.statusText}`);
  return response;
}

(async () => {
  const commit = (await (await get(`${repository}/commits/${tag}`, github)).json()).sha;
  const listing = await (await get(`${repository}/contents/${specPath}?ref=${commit}`, github)).json();
  const names = listing.filter(entry => entry.type === 'file' && entry.name.endsWith('.yml')).map(entry => entry.name).sort();
  if (!names.length) throw new Error(`no specification in ${specPath} at ${tag}: has it moved?`);
  const files = [];
  for (const name of names) {
    const url = `https://raw.githubusercontent.com/microsoft/playwright/${commit}/${specPath}/${name}`;
    files.push({ name, bytes: Buffer.from(await (await get(url)).arrayBuffer()) });
  }
  const { dist } = await (await get(`https://registry.npmjs.org/playwright-core/${version}`)).json();
  if (!dist || !dist.tarball || !/^sha512-/.test(dist.integrity || '')) throw new Error('the npm registry gave no SHA-512 checksum for playwright-core@' + version);

  const root = path.resolve(__dirname, '..', 'protocol');
  const specDir = path.join(root, 'spec');
  fs.mkdirSync(specDir, { recursive: true });
  for (const name of fs.readdirSync(specDir)) if (name.endsWith('.yml')) fs.unlinkSync(path.join(specDir, name));
  const spec = {};
  for (const { name, bytes } of files) {
    fs.writeFileSync(path.join(specDir, name), bytes);
    spec[name] = crypto.createHash('sha256').update(bytes).digest('hex');
  }
  const manifest = {
    version,
    source: `https://github.com/microsoft/playwright/tree/${tag}/${specPath}`,
    commit,
    driver: { tarball: dist.tarball, integrity: dist.integrity },
    spec,
  };
  fs.writeFileSync(path.join(root, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  console.log(`protocol/ now describes Playwright ${version} (${commit.slice(0, 7)}, ${names.length} files).`);
  console.log('Next: dune build @gen --auto-promote');
})().catch(error => {
  console.error('update_protocol: ' + (error.cause ? `${error.message}: ${error.cause.message || error.cause}` : error.message));
  process.exit(1);
});

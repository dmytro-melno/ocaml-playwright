'use strict';
// Actual cached playwright-core 1.59.1, same browser/HTTP fixture as live_tests.exe.
// Private channels are intentional where the OCaml API exposes protocol-level methods.
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.join(require('node:os').homedir(), '.cache/playwright-ocaml-driver/1.59.1/package');
assert.equal(require(path.join(root, 'package.json')).version, '1.59.1');
const { chromium } = require(root);
const fixture = require('./fixture.cjs');
const edges = [Buffer.alloc(0), Buffer.from([0]), Buffer.from([255, 128, 0, ...Buffer.from('Hello\r\n')]),
  Buffer.from(Array.from({ length: 256 }, (_, i) => i))];
const png = bytes => assert.deepEqual(bytes.subarray(0, 8), Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
const jpeg = bytes => assert.deepEqual(bytes.subarray(0, 3), Buffer.from([255, 216, 255]));
const test = async (name, f) => { await f(); console.log(`PASS protocol JS 1.59.1 ${name}`); };
const until = async predicate => {
  const deadline = Date.now() + 3000;
  while (!predicate()) {
    assert.ok(Date.now() < deadline, 'event deadline');
    await new Promise(resolve => setTimeout(resolve, 10));
  }
};
(async () => {
  const { server, url } = await fixture.start();
  let browser;
  try {
    browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true });
    const context = await browser.newContext(), page = await context.newPage();
    page.setDefaultTimeout(3000);
    await page.goto(url);
    await test('manual context subscriptions and typed page-error/console events', async () => {
      const consoles = [], errors = [];
      context._channel.on('console', e => consoles.push(e));
      context._channel.on('pageError', e => errors.push(e));
      // pageError is not subscription-gated in this protocol.
      await context._channel.updateSubscription({ event: 'console', enabled: true });
      await page.evaluate("console.log('protocol-console'); setTimeout(() => { throw new Error('protocol-page-error') }, 0)");
      await until(() => consoles.length && errors.length);
      assert.equal(consoles[0].text, 'protocol-console');
      assert.ok(consoles[0].location.lineNumber >= 0 && consoles[0].location.columnNumber >= 0);
      assert.deepEqual(Object.keys(errors[0]).sort(), ['error', 'page']);
      assert.equal(errors[0].error.error.message, 'protocol-page-error');
      assert.equal(errors[0].page, page._channel);
      await context._channel.updateSubscription({ event: 'console', enabled: false });
    });
    await test('failed expect retains actual SerializedValue', async () => {
      const result = await page.mainFrame()._channel.expect({
        selector: '#one', expression: 'to.have.count', expectedNumber: 5, isNot: false, timeout: 100
      });
      assert.equal(result.matches, false); assert.equal(result.timedOut, true);
      assert.deepEqual(result.received, { n: 1 });
      assert.equal((await page.locator('#one')._expect('to.have.count', { expectedNumber: 5, isNot: false, timeout: 100 })).received, 1);
    });
    await test('selector Attached/Detached distinct from actionability Enabled', async () => {
      const body = await page.$('body');
      try {
        const button = await body.waitForSelector('#button', { state: 'attached', timeout: 1000 });
        try { await button.waitForElementState('enabled', { timeout: 1000 }); } finally { await button.dispose(); }
        await page.evaluate("document.querySelector('#button').remove()");
        assert.equal(await body.waitForSelector('#button', { state: 'detached', timeout: 1000 }), null);
      } finally { await body.dispose(); }
    });
    await test('nonempty JS coverage with typed function ranges', async () => {
      await page.coverage.startJSCoverage({ reportAnonymousScripts: true });
      await page.evaluate('(function covered(){return 42})()');
      const entries = await page.coverage.stopJSCoverage();
      assert.ok(entries.length > 0);
      assert.ok(entries.some(e => e.functions.some(f => f.ranges.some(r => r.endOffset > r.startOffset && r.count > 0))));
    });
    await test('nonempty external-stylesheet CSS coverage with CSS ranges', async () => {
      await page.coverage.startCSSCoverage();
      await page.goto(`${url}/styled`);
      const entries = await page.coverage.stopCSSCoverage();
      assert.ok(entries.some(e => e.url === `${url}/style.css` && e.ranges.some(r => r.end > r.start)));
    });
    await test('raw in-memory file upload exact edge bytes', async () => {
      await page.setInputFiles('#file', edges.map((buffer, i) => ({
        name: `${i}.bin`, mimeType: 'application/octet-stream', buffer
      })));
      const actual = await page.evaluate(async () => Promise.all(Array.from(document.querySelector('#file').files,
        async f => Array.from(new Uint8Array(await f.arrayBuffer())))));
      assert.deepEqual(actual, edges.map(b => Array.from(b)));
    });
    const fetchBody = async (pathname, options = {}) => {
      const response = await context.request.post(url + pathname, { timeout: 3000, ...options });
      try { assert.equal(response.status(), 200); return await response.body(); }
      finally { await response.dispose(); }
    };
    await test('direct request/response binary controls exact edge bytes', async () => {
      for (const data of edges)
        assert.equal(JSON.parse(await fetchBody('/echo', { data })).bodyBase64, data.toString('base64'));
      assert.deepEqual(await fetchBody('/bytes'), Buffer.from([0, 255, 128, 1, 13, 10]));
      let response;
      context._channel.on('response', e => {
        if (e.response._object._initializer.url === `${url}/bytes`) response = e.response._object;
      });
      await context._channel.updateSubscription({ event: 'response', enabled: true });
      await page.evaluate(async () => (await fetch('/bytes')).arrayBuffer());
      await until(() => response);
      assert.deepEqual(await response.body(), Buffer.from([0, 255, 128, 1, 13, 10]));
      await context._channel.updateSubscription({ event: 'response', enabled: false });
    });
    await test('multipart upload exact edge bytes', async () => {
      for (const buffer of edges) {
        const body = await fetchBody('/echo', { multipart: { file: { name: 'raw.bin', mimeType: 'application/octet-stream', buffer } } });
        assert.equal(JSON.parse(body).fileBase64, buffer.toString('base64'));
      }
    });
    await test('real request initializer optional binary decodes once', async () => {
      const requests = [];
      context._channel.on('request', e => requests.push(e.request._object));
      await context._channel.updateSubscription({ event: 'request', enabled: true });
      const bytes = Buffer.from([0, 255, 128, ...Buffer.from('Hello')]);
      await page.evaluate(async bytes => (await fetch('/echo', { method: 'POST', body: new Uint8Array(bytes) })).json(), Array.from(bytes));
      await until(() => requests.length);
      assert.equal(requests[0]._initializer.method, 'POST');
      assert.deepEqual(requests[0]._initializer.postData, bytes);
      assert.deepEqual(requests[0].postDataBuffer(), bytes);
      await context._channel.updateSubscription({ event: 'request', enabled: false });
    });
    await test('direct PNG/PDF and nested screenshot result signatures', async () => {
      png(await page.screenshot());
      assert.equal((await page.pdf()).subarray(0, 5).toString(), '%PDF-');
      const result = await page._expectScreenshot({ isNot: false, timeout: 3000 });
      assert.ok(Buffer.isBuffer(result.actual)); png(result.actual);
    });
    await test('screencast event contains raw JPEG bytes', async () => {
      let frame;
      await page.screencast.start({ onFrame: e => { frame = e.data; } });
      try {
        await page.evaluate("document.body.style.background='green'");
        await until(() => frame);
        assert.ok(Buffer.isBuffer(frame)); jpeg(frame);
      } finally { await page.screencast.stop(); }
    });
    await test('special-value wire literals incoming and outgoing live', async () => {
      for (const expression of ['NaN', 'Infinity', '-Infinity', '-0']) {
        const { value } = await page.mainFrame()._channel.evaluateExpression({ expression, arg: { value: { v: 'null' }, handles: [] } });
        assert.deepEqual(value, { v: expression });
        const result = await page.mainFrame()._channel.evaluateExpression({
          expression: `x => Object.is(x, ${expression})`, isFunction: true, arg: { value, handles: [] }
        });
        assert.deepEqual(result.value, { b: true });
      }
      assert.ok(Number.isNaN(await page.evaluate('NaN')));
      assert.equal(await page.evaluate('Infinity'), Infinity);
      assert.equal(await page.evaluate('-Infinity'), -Infinity);
      assert.ok(Object.is(await page.evaluate('-0'), -0));
    });
  } finally {
    try { if (browser) await browser.close(); }
    finally { fixture.close(server); }
  }
})().catch(e => { console.error(e); process.exitCode = 1; });

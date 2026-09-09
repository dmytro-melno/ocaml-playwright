'use strict';
// Pinned differential assertions, not a second copy of the OCaml implementation.
// Uses the same DOM fixture and browser as browser_tests.exe.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.join(require('node:os').homedir(), '.cache/playwright-ocaml-driver/1.59.1/package');
assert.equal(require(path.join(root, 'package.json')).version, '1.59.1');
const { chromium, selectors, errors } = require(root);
const fixture = fs.readFileSync(path.join(__dirname, 'fixture.js'), 'utf8');
const latency = JSON.parse(fs.readFileSync(path.join(__dirname, 'latency-fixture.json'), 'utf8'));
const special = 'Quote " slash \\ newline\n tab\t carriage\r Ω雪';
async function test(name, f) { await f(); console.log(`PASS JS 1.59.1 ${name}`); }
const strict = f => assert.rejects(f, /strict mode violation/);
const timeout = f => assert.rejects(f, e => e instanceof errors.TimeoutError);
(async () => {
  // Register before the first context creates its injected selector script.
  await selectors.register('slow', latency.slowEngine);
  const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true });
  try {
    const context = await browser.newContext({ hasTouch: true });
    const page = await context.newPage();
    await page.evaluate(`(${fixture})()`);
    const button = page.locator('#buttons button'), input = page.locator('.text');
    const checkbox = page.locator('.check'), select = page.locator('select'), file = page.locator('.file');
    const o = { timeout: 700 };
    const probes = [
      ['click', () => button.click(o)], ['fill', () => input.fill('wrong', o)],
      ['press', () => input.press('A', o)], ['get_attribute', () => button.getAttribute('id', o)],
      ['text_content', () => button.textContent(o)], ['inner_text', () => button.innerText(o)],
      ['inner_html', () => button.innerHTML(o)], ['check', () => checkbox.check(o)],
      ['uncheck', () => checkbox.uncheck(o)], ['dblclick', () => button.dblclick(o)],
      ['blur', () => input.blur(o)], ['focus', () => input.focus(o)], ['hover', () => button.hover(o)],
      ['input_value', () => input.inputValue(o)], ['select_option', () => select.selectOption([], o)],
      ['set_input_files', () => file.setInputFiles([], o)], ['tap', () => button.tap(o)],
      ['type', () => input.type('wrong', o)], ['dispatch_event', () => button.dispatchEvent('click', {}, o)],
      ['is_checked', () => checkbox.isChecked(o)], ['is_disabled', () => input.isDisabled(o)],
      ['is_enabled', () => input.isEnabled(o)], ['is_hidden', () => button.isHidden()],
      ['is_visible', () => button.isVisible()], ['is_editable', () => input.isEditable(o)],
      ['drag source', () => button.dragTo(button.first(), o)],
      ['drag target', () => button.first().dragTo(button, o)], ['clear', () => input.clear(o)],
      ...['attached', 'visible', 'hidden', 'detached'].map(state => [`wait ${state}`, () => button.waitFor({ ...o, state })]),
      ['evaluate', () => button.evaluate(el => el.id, null, o)],
      ['element_handle', () => button.elementHandle(o)], ['bounding_box', () => button.boundingBox(o)],
      ['scroll', () => button.scrollIntoViewIfNeeded(o)], ['screenshot', () => button.screenshot(o)]
    ];
    for (const [name, f] of probes) await test(`strict ${name}`, () => strict(f));
    await test('raw expect ambiguity and plural count; disambiguation', async () => {
      const result = await button._expect('to.be.visible', { ...o, isNot: false });
      assert.equal(result.matches, false);
      assert.match(result.errorMessage, /strict mode violation/);
      assert.equal((await button._expect('to.have.count', { ...o, expectedNumber: 2, isNot: false })).matches, true);
      assert.equal(await page.evaluate(() => window.clicked), null);
      await button.first().click(); assert.equal(await page.evaluate(() => window.clicked), 'one');
      await button.nth(1).click(); assert.equal(await page.evaluate(() => window.clicked), 'two');
      assert.equal(await button.last().innerText(), 'Cancel');
      assert.equal(await page.innerText('#buttons button'), 'Save');
      assert.equal(await button.count(), 2);
      assert.equal(await button.evaluateAll(els => els.length), 2);
      assert.deepEqual(await button.allInnerTexts(), ['Save', 'Cancel']);
      assert.deepEqual(await button.allTextContents(), ['Save', 'Cancel']);
      const hs = await button.elementHandles(); assert.equal(hs.length, 2);
      await Promise.all(hs.map(h => h.dispose()));
    });
    const one = async l => assert.equal(await l.count(), 1);
    await test('test-ID Page Frame nested; JS configuration is global', async () => {
      await one(page.getByTestId(special));
      await one(page.mainFrame().getByTestId(special));
      await one(page.locator('#article').getByTestId(special));
      await page.evaluate(() => document.querySelector('#special').removeAttribute('data-testid'));
      selectors.setTestIdAttribute('data-qa');
      await one(page.getByTestId(special));
      await one(page.mainFrame().getByTestId(special));
      await one(page.locator('#article').getByTestId(special));
      selectors.setTestIdAttribute('data-next'); await one(page.getByTestId(special));
    });
    await test('substring case whitespace and selector encoding', async () => {
      for (const text of ['Alpha', 'ALPHA', 'pha b', 'alpha \n\t\r beta', special])
        await one(page.locator('article').filter({ hasText: text }));
      assert.equal(await page.locator('article').filter({ hasText: 'AlphaBeta' }).count(), 0);
      await one(page.getByText(' Alpha\n Beta ', { exact: true }));
      assert.equal(await page.getByText(special, { exact: true }).count(), 2);
      for (const l of [
        page.getByLabel(special, { exact: true }), page.getByPlaceholder(special, { exact: true }),
        page.getByRole('textbox', { name: special, exact: true }), page.getByAltText(special, { exact: true }),
        page.getByTitle(special, { exact: true }), page.locator('#article').getByText(special, { exact: true })
      ]) await one(l);
      assert.equal(await page.getByTitle(special.toLowerCase(), { exact: true }).count(), 0);
      await one(page.getByTitle('QUOTE'));
    });
    await test('unions, chains, intersections, has, nested literal controls', async () => {
      const a = page.getByRole('button', { name: 'Save' }), b = page.getByText('Cancel', { exact: true });
      assert.equal(await a.or(b).count(), 2);
      await strict(() => a.or(b).click(o)); await one(a.or(b).first());
      assert.equal(await page.locator('#buttons >> #one').or(page.locator('#buttons >> #two')).count(), 2);
      await one(a.and(page.locator('#one')));
      const raw = page.getByTitle(special, { exact: true });
      await one(page.locator('#missing').or(raw));
      await one(page.locator('img').and(raw));
      await one(page.locator('section').filter({ has: a.or(b) }));
      await one(page.locator('article').filter({ has: page.getByText(special, { exact: true }) }));
      await one(page.locator('body').filter({ has: raw }));
    });
    const frame = await (await page.locator('iframe').elementHandle()).contentFrame();
    await frame.setContent("<button id='one'>child</button>");
    await test('frame checks in and/or/has; dragTo deliberately lacks the check', async () => {
      const a = page.locator('#one'), other = frame.locator('#one');
      assert.throws(() => a.and(other), /same frame/);
      assert.throws(() => a.or(other), /same frame/);
      assert.throws(() => a.filter({ has: other }), /same frame/);
      await a.dragTo(other, { trial: true, timeout: 1000 }); // Target is reinterpreted in a's frame.
      const same = page.mainFrame().locator('#one');
      await one(a.and(same)); await one(a.or(same));
      await a.dragTo(same, { trial: true, timeout: 1000 });
    });
    await test('immediate visibility, invalid selector, hidden geometry, iframe geometry', async () => {
      const hidden = page.locator('#hidden');
      assert.equal(await hidden.isVisible({ timeout: 0 }), false);
      assert.equal(await page.locator('#missing').isVisible({ timeout: 30000 }), false);
      assert.equal(await hidden.isHidden(), true);
      assert.equal(await page.locator('#missing').isHidden(), true);
      await assert.rejects(() => page.locator('[').isVisible(), /parsing css selector/);
      await assert.rejects(() => page.locator('[').isHidden(), /parsing css selector/);
      assert.equal(await hidden.boundingBox(), null);
      await frame.setContent("<style>body{margin:0}</style><div id='box' style='position:absolute;left:12px;top:15px;width:30px;height:20px'></div>");
      assert.deepEqual(await frame.locator('#box').boundingBox(), { x: 112, y: 215, width: 30, height: 20 });
    });
    await test('evaluate waits for insertion, not an arbitrary JS execution timeout', async () => {
      const pending = page.locator('#late').evaluate(el => el.id, null, { timeout: 1500 });
      await page.evaluate(() => document.body.insertAdjacentHTML('beforeend', '<div id="late"></div>'));
      assert.equal(await pending, 'late');
      let finished = false;
      const long = page.locator('#one').evaluate(el => new Promise(resolve => {
        window.releaseEval = () => resolve(el.id);
      }), null, { timeout: 150 }).then(value => { finished = true; return value; });
      await page.waitForFunction(() => typeof window.releaseEval === 'function');
      await new Promise(resolve => setTimeout(resolve, 200));
      assert.equal(finished, false);
      await page.evaluate(() => window.releaseEval());
      assert.equal(await long, 'one');
    });
    await test('slow selector finishes once per acquisition, including timeout zero', async () => {
      const target = page.locator('slow=#one');
      const operations = [
        async () => assert.equal(await target.evaluate(el => el.id, null, { timeout: 1600 }), 'one'),
        async () => assert.notEqual(await target.boundingBox({ timeout: 1600 }), null),
        () => target.scrollIntoViewIfNeeded({ timeout: 1600 }),
        async () => assert.deepEqual([...((await target.screenshot({ timeout: 1600 })).subarray(0, 4))], [137, 80, 78, 71]),
        async () => {
          const h = await target.elementHandle({ timeout: 1600 });
          assert.equal(await h.evaluate(el => el.id), 'one'); await h.dispose();
        },
        async () => assert.equal(await target.evaluate(el => el.id, null, { timeout: 0 }), 'one')
      ];
      for (const [i, operation] of operations.entries()) {
        await operation();
        assert.equal(await page.evaluate(() => window.slowQueries), i + 1);
      }
    });
    await test('busy page acquisition preserves a responsive driver and session', async () => {
      for (const plural of [true, false]) {
        const started = page.waitForEvent('console', { predicate: m => m.text() === 'BUSY-START', timeout: 3000 });
        await page.evaluate(`(${latency.busyPage})()`);
        await started;
        let completed = false;
        const pending = (plural ? page.locator('#one').elementHandles() :
          page.locator('#one').elementHandle({ timeout: 5000 }).then(h => [h]))
          .then(hs => { completed = true; return hs; });
        await context.cookies();
        assert.equal(completed, false, 'context RPC finishes while page query is pending');
        const hs = await pending;
        assert.equal(hs.length, 1);
        assert.equal(await hs[0].evaluate(el => el.id), 'one');
        await hs[0].dispose();
        assert.equal(browser.isConnected(), true);
        await context.cookies();
      }
    });
    await test('scroll actionability; screenshot success and distinct failures; caller handle ownership', async () => {
      await page.locator('#offscreen').scrollIntoViewIfNeeded({ timeout: 1200 });
      assert.equal(await page.evaluate(() => window.scrollY > 0), true);
      await timeout(() => page.locator('#hidden').scrollIntoViewIfNeeded({ timeout: 250 }));
      const png = await page.locator('#one').screenshot({ timeout: 1500 });
      assert.deepEqual([...png.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
      await timeout(() => page.locator('#hidden').screenshot({ timeout: 250 }));
      await assert.rejects(() => page.locator('#one').screenshot({ quality: 80 }), /quality is unsupported for the png screenshots/);
      const handle = await page.locator('#one').elementHandle();
      await page.locator('#one').boundingBox();
      assert.equal(await handle.evaluate(el => el.id), 'one');
      await handle.dispose();
      await page.close();
      await assert.rejects(() => page.locator('#one').isVisible(), /Target.*closed/);
      await assert.rejects(() => page.locator('#one').isHidden(), /Target.*closed/);
    });
  } finally {
    selectors.setTestIdAttribute('data-testid');
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });

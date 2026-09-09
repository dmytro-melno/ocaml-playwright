'use strict';
// Deterministic fake driver for public create/destroy lifecycle tests. Never
// downloads, launches a browser, or creates unowned descendant processes.
const fs = require('node:fs');
const mode = process.env.CRITICAL_DRIVER_MODE;
const log = text => fs.appendFileSync(process.env.CRITICAL_DRIVER_LOG, text + '\n');
log('pid ' + process.pid);
if (mode === 'exit') process.exit(23);
const send = message => {
  const body = Buffer.from(JSON.stringify(message));
  const header = Buffer.alloc(4);
  header.writeUInt32LE(body.length);
  process.stdout.write(Buffer.concat([header, body]));
};
if (['hang', 'stubborn', 'eof'].includes(mode)) {
  process.on('SIGTERM', () => log('TERM'));
  setInterval(() => {}, 1000);
}
let input = Buffer.alloc(0);
process.stdin.on('data', data => {
  input = Buffer.concat([input, data]);
  while (input.length >= 4 && input.length >= 4 + input.readUInt32LE(0)) {
    const size = input.readUInt32LE(0);
    const message = JSON.parse(input.subarray(4, 4 + size));
    input = input.subarray(4 + size);
    if (message.method === 'initialize') log('initialize');
    if (mode === 'hang') continue;
    if (message.method === 'initialize') {
      if (mode === 'error') {
        send({id: message.id, error: {error: {name: 'FixtureError', message: 'initialization rejected'}}});
      } else {
        send({guid: '', method: '__create__', params: {
          guid: 'Playwright', type: 'Playwright', initializer: {}
        }});
        send({id: message.id, result: {playwright: {guid: 'Playwright'}}});
      }
    } else if (mode === 'death') {
      process.exit(24);
    } else if (mode === 'eof') {
      fs.closeSync(1);
    }
  }
});
process.stdin.on('end', () => {
  log('EOF');
  if (!['hang', 'stubborn', 'eof'].includes(mode)) process.exit(0);
});

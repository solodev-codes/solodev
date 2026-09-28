// Escaping check: hostile input must never reach the HTML as markup.
const {
  acknowledgementTemplate,
  replyTemplate,
} = require('../functions/lib/email/templates.js');

const evil = '<img src=x onerror=alert(1)>"\'&';
const ack = acknowledgementTemplate(evil, evil);
const rep = replyTemplate(evil, evil, 'Body <b>bold</b> & "quoted"');

const checks = [
  ['ack: no raw <img', !ack.html.includes('<img src=x')],
  ['ack: escaped form present', ack.html.includes('&lt;img src=x')],
  ['ack: no <script', !ack.html.includes('<script')],
  // `onerror=alert(1)` legitimately survives as inert text inside the escaped
  // payload; what must never appear is an unescaped angle bracket in front of
  // it, or a script-bearing URL.
  ['ack: no javascript: URL', !ack.html.toLowerCase().includes('javascript:')],
  [
    'ack: injected payload is fully escaped',
    !new RegExp('<[^>]*' + 'onerror').test(ack.html),
  ],
  ['reply: no raw <b>', !rep.html.includes('<b>bold</b>')],
  ['reply: body escaped', rep.html.includes('&lt;b&gt;bold&lt;/b&gt;')],
  ['reply: subject escaped', rep.html.includes('&lt;img src=x')],
  ['plain text is literal', ack.text.includes('<img src=x')],
];

let failed = 0;
for (const [label, ok] of checks) {
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${label}`);
}
console.log(failed === 0 ? '\nAll escaping checks passed.' : `\n${failed} FAILED`);
process.exit(failed === 0 ? 0 : 1);

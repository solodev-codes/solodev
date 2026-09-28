// Renders the three production e-mail templates to disk for visual review.
//   node tool/render_email_templates.js   (run from the functions folder)
const fs = require('fs');
const path = require('path');
const {
  acknowledgementTemplate,
  replyTemplate,
  testEmailTemplate,
} = require('../functions/lib/email/templates.js');

const outDir = path.join(__dirname, 'email_samples');
fs.mkdirSync(outDir, { recursive: true });

const samples = {
  'acknowledgement.html': acknowledgementTemplate(
    'Amara Osei',
    'Flutter dashboard for a logistics startup',
  ),
  'reply.html': replyTemplate(
    'Amara Osei',
    'Re: Flutter dashboard for a logistics startup',
    'Thanks for reaching out — I have reviewed the brief and I think a ' +
      'Flutter + Firebase build is the right fit.\n\nI can start with a ' +
      'clickable prototype within two weeks, then iterate on the live ' +
      'tracking map once the data model is agreed.',
  ),
  'test.html': testEmailTemplate(),
};

for (const [file, { html, text }] of Object.entries(samples)) {
  fs.writeFileSync(path.join(outDir, file), html, 'utf8');
  fs.writeFileSync(path.join(outDir, file.replace('.html', '.txt')), text, 'utf8');

  // Structural sanity check: table markup must balance, or clients drop cells.
  const count = (re) => (html.match(re) || []).length;
  const rows = [count(/<tr[\s>]/g), count(/<\/tr>/g)];
  const tables = [count(/<table[\s>]/g), count(/<\/table>/g)];
  const cells = [count(/<td[\s>]/g), count(/<\/td>/g)];
  const balanced = (p) => p[0] === p[1];
  console.log(
    `${file.padEnd(22)} ${String(html.length).padStart(6)} bytes  ` +
      `tr ${rows.join('/')} ${balanced(rows) ? 'ok' : 'MISMATCH'}  ` +
      `table ${tables.join('/')} ${balanced(tables) ? 'ok' : 'MISMATCH'}  ` +
      `td ${cells.join('/')} ${balanced(cells) ? 'ok' : 'MISMATCH'}`,
  );
}
console.log(`\nWrote samples to ${outDir}`);

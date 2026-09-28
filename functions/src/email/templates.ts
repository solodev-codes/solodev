/**
 * HTML templates for outbound client e-mail (spec section 59).
 *
 * Plain inline styles only: Gmail and Apple Mail strip `<style>` blocks from
 * the message body, so every value is written as an attribute.
 */

/** Escape user-controlled text before it enters HTML. */
export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

const WRAP_STYLE =
  'max-width:560px;margin:0 auto;font-family:Helvetica,Arial,sans-serif;' +
  'color:#1f2937;line-height:1.6;';
const FOOTER_STYLE =
  'margin-top:28px;padding-top:16px;border-top:1px solid #e5e7eb;' +
  'font-size:12px;color:#6b7280;';

/** Shared page chrome around every message. */
function shell(innerHtml: string): string {
  return (
    '<div style="' +
    WRAP_STYLE +
    '">' +
    innerHtml +
    '<div style="' +
    FOOTER_STYLE +
    '">' +
    'Solodev &mdash; Flutter Developer &amp; AI Designer.<br/>' +
    'You are receiving this because you contacted us through our website.' +
    '</div>' +
    '</div>'
  );
}

/** New-enquiry acknowledgement sent to the visitor on submission. */
export function acknowledgementTemplate(
  name: string,
  subject: string,
): { html: string; text: string } {
  const safeName = escapeHtml(name);
  const safeSubject = escapeHtml(subject);
  const html = shell(
    '<h1 style="font-size:20px;margin:0 0 12px;">Thanks ' +
      safeName +
      ' &#128075;</h1>' +
      '<p style="margin:0 0 12px;">We received your enquiry' +
      (safeSubject ? ' &ldquo;' + safeSubject + '&rdquo;' : '') +
      ' and will get back to you within one business day.</p>' +
      '<p style="margin:0;">If your request is urgent, reply to this ' +
      'e-mail and it will land straight in our inbox.</p>',
  );
  const text =
    `Hi ${name},\n\nThanks for your enquiry` +
    (subject ? ` ("${subject}")` : '') +
    '. We received it and will get back to you within one business day.\n\n' +
    'If your request is urgent, just reply to this e-mail.\n\n- Solodev';
  return { html, text };
}

/** Administrator reply to an enquiry. */
export function replyTemplate(
  name: string,
  replySubject: string,
  replyBody: string,
): { html: string; text: string } {
  const paragraphs = escapeHtml(replyBody)
    .split(/\n{2,}/)
    .map((p) => '<p style="margin:0 0 12px;">' + p.replace(/\n/g, '<br/>') + '</p>')
    .join('');
  const html = shell(
    '<h1 style="font-size:20px;margin:0 0 12px;">Hi ' +
      escapeHtml(name) +
      ',</h1>' +
      '<p style="margin:0 0 12px;font-weight:bold;">' +
      escapeHtml(replySubject) +
      '</p>' +
      paragraphs,
  );
  const text = `Hi ${name},\n\n${replySubject}\n\n${replyBody}\n\n- Solodev`;
  return { html, text };
}

/** Self-test message triggered from the admin settings screen. */
export function testEmailTemplate(): { html: string; text: string } {
  const html = shell(
    '<h1 style="font-size:20px;margin:0 0 12px;">SMTP test successful</h1>' +
      '<p style="margin:0;">Gmail SMTP is configured correctly for the ' +
      'Solodev portfolio. Client notifications will be delivered from this ' +
      'address.</p>',
  );
  const text =
    'SMTP test successful. Gmail SMTP is configured correctly for the ' +
    'Solodev portfolio.';
  return { html, text };
}

/**
 * Brand-styled HTML templates for outbound client e-mail (spec section 59).
 *
 * Design language: the same dark surface, electric cyan accent and typographic
 * weight as the portfolio itself, so a notification feels like part of the
 * product rather than a generic mail.
 *
 * Client compatibility rules followed here:
 * - Layout is table-based and every visual value is an inline style attribute,
 *   because Gmail and Apple Mail strip `<style>` blocks from the body.
 * - The single `<style>` block only carries progressive enhancement (a mobile
 *   media query and resets); the design renders correctly without it.
 * - Gradients are emulated with adjacent solid cells, and buttons are padded
 *   anchors inside a `bgcolor` cell, the most durable combination.
 * - No external images, so nothing can be blocked: the mark is drawn as styled
 *   text and a bordered monogram.
 */

import { PORTFOLIO_SITE_URL } from '../config/constants';

/** Brand tokens, mirroring `AppColors` in the Flutter app. */
const BRAND = {
  background: '#0a0e17',
  surface: '#111827',
  surfaceAlt: '#161f30',
  border: '#1e3a4a',
  accent: '#00e5ff',
  primary: '#1565c0',
  text: '#f1f5f9',
  textMuted: '#94a3b8',
  textFaint: '#64748b',
} as const;

/** Escape user-controlled text before it enters HTML. */
export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/** Hidden inbox preview line. */
function preheader(text: string): string {
  return (
    '<div style="display:none;font-size:1px;line-height:1px;max-height:0;' +
    'max-width:0;opacity:0;overflow:hidden;mso-hide:all;">' +
    escapeHtml(text) +
    '</div>'
  );
}

/** Monogram block standing in for the logo. */
function monogram(): string {
  return (
    '<td width="44" height="44" valign="middle" align="center" ' +
    'style="width:44px;height:44px;background:' +
    BRAND.background +
    ';border:1px solid ' +
    BRAND.accent +
    ';border-radius:12px;font-family:Helvetica,Arial,sans-serif;' +
    'font-size:21px;font-weight:bold;color:' +
    BRAND.accent +
    ';line-height:44px;">S</td>'
  );
}

/** Wordmark, positioning line and the accent rule. */
function headerBlock(): string {
  return (
    '<tr><td class="px" style="padding:28px 32px 22px 32px;">' +
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">' +
    '<tr>' +
    monogram() +
    '<td width="12" style="width:12px;font-size:0;line-height:0;">&nbsp;</td>' +
    '<td valign="middle" style="font-family:Helvetica,Arial,sans-serif;">' +
    '<div style="font-size:17px;font-weight:bold;letter-spacing:1.2px;color:' +
    BRAND.text +
    ';">SOLO<span style="color:' +
    BRAND.accent +
    ';">DEV</span></div>' +
    '<div style="padding-top:3px;font-size:11px;letter-spacing:0.4px;color:' +
    BRAND.textFaint +
    ';">FLUTTER DEVELOPER &middot; AI DESIGNER</div>' +
    '</td>' +
    '</tr></table></td></tr>' +
    // Two solid cells instead of a gradient, which most clients cannot draw.
    '<tr><td class="px" style="padding:0 32px;font-size:0;line-height:0;">' +
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">' +
    '<tr><td width="38%" style="width:38%;height:2px;background:' +
    BRAND.accent +
    ';font-size:0;line-height:0;">&nbsp;</td>' +
    '<td width="62%" style="width:62%;height:2px;background:' +
    BRAND.primary +
    ';font-size:0;line-height:0;">&nbsp;</td></tr>' +
    '</table></td></tr>'
  );
}

/** Identity and reason-for-contact footer. */
function footerBlock(reason: string): string {
  return (
    '<tr><td class="px" style="padding:24px 32px 28px 32px;">' +
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">' +
    '<tr><td style="height:1px;line-height:1px;background:' +
    BRAND.border +
    ';font-size:0;">&nbsp;</td></tr></table>' +
    '<p style="margin:16px 0 0;font-family:Helvetica,Arial,sans-serif;' +
    'font-size:12px;line-height:18px;color:' +
    BRAND.textFaint +
    ';">' +
    escapeHtml(reason) +
    '</p>' +
    '<p style="margin:10px 0 0;font-family:Helvetica,Arial,sans-serif;' +
    'font-size:12px;line-height:18px;color:' +
    BRAND.textMuted +
    ';">Solodev &middot; ' +
    '<a href="' +
    PORTFOLIO_SITE_URL +
    '" style="color:' +
    BRAND.accent +
    ';text-decoration:none;">' +
    PORTFOLIO_SITE_URL.replace(/^https?:\/\//, '') +
    '</a></p>' +
    '</td></tr>'
  );
}

/** Full document around a message body. */
function shell(preheaderText: string, bodyHtml: string, reason: string): string {
  return [
    '<!DOCTYPE html>',
    '<html lang="en">',
    '<head>',
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width,initial-scale=1">',
    '<meta name="color-scheme" content="dark">',
    '<meta name="supported-color-schemes" content="dark">',
    '<title>Solodev</title>',
    '<!--[if mso]><noscript><xml><o:OfficeDocumentSettings>',
    '<o:PixelsPerInch>96</o:PixelsPerInch>',
    '</o:OfficeDocumentSettings></xml></noscript><![endif]-->',
    '<style>',
    'body{margin:0;padding:0;background:' + BRAND.background + ';}',
    'table{border-collapse:collapse;}',
    'img{-ms-interpolation-mode:bicubic;}',
    '@media only screen and (max-width:620px){',
    '.wrap{width:100%!important;}',
    '.px{padding-left:20px!important;padding-right:20px!important;}',
    '.h1{font-size:22px!important;line-height:28px!important;}',
    '.btn{width:100%!important;}',
    '}',
    '</style>',
    '</head>',
    '<body style="margin:0;padding:0;background:' +
      BRAND.background +
      ';-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">',
    preheader(preheaderText),
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:' +
      BRAND.background + ';">',
    '<tr><td align="center" style="padding:28px 12px;">',
    '<table role="presentation" class="wrap" width="600" cellpadding="0" cellspacing="0" border="0" style="width:600px;max-width:600px;background:' +
      BRAND.surface +
      ';border:1px solid ' +
      BRAND.border +
      ';border-radius:16px;">',
    headerBlock(),
    bodyHtml,
    footerBlock(reason),
    '</table>',
    '</td></tr>',
    '</table>',
    '</body>',
    '</html>',
  ].join('');
}

/** Small uppercase label that opens a section. */
function eyebrow(label: string): string {
  return (
    '<p style="margin:0 0 10px;font-family:Helvetica,Arial,sans-serif;' +
    'font-size:11px;font-weight:bold;letter-spacing:1.4px;color:' +
    BRAND.accent +
    ';">' +
    escapeHtml(label.toUpperCase()) +
    '</p>'
  );
}

/** Message headline. */
function heading(text: string): string {
  return (
    '<h1 class="h1" style="margin:0 0 14px;font-family:Helvetica,Arial,' +
    'sans-serif;font-size:26px;line-height:32px;font-weight:bold;color:' +
    BRAND.text +
    ';">' +
    text +
    '</h1>'
  );
}

/** Body copy paragraph. */
function paragraph(text: string): string {
  return (
    '<p style="margin:0 0 14px;font-family:Helvetica,Arial,sans-serif;' +
    'font-size:15px;line-height:23px;color:' +
    BRAND.textMuted +
    ';">' +
    text +
    '</p>'
  );
}

/** Raised panel for details worth pulling out of the body copy. */
function detailCard(label: string, value: string): string {
  return (
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" ' +
    'style="margin:4px 0 20px 0;background:' +
    BRAND.surfaceAlt +
    ';border:1px solid ' +
    BRAND.border +
    ';border-radius:12px;">' +
    '<tr><td style="padding:16px 18px;">' +
    '<p style="margin:0;font-family:Helvetica,Arial,sans-serif;font-size:11px;' +
    'font-weight:bold;letter-spacing:1.2px;color:' +
    BRAND.textFaint +
    ';">' +
    escapeHtml(label.toUpperCase()) +
    '</p>' +
    '<p style="margin:6px 0 0;font-family:Helvetica,Arial,sans-serif;' +
    'font-size:15px;line-height:22px;color:' +
    BRAND.text +
    ';">' +
    value +
    '</p>' +
    '</td></tr></table>'
  );
}

/** Primary call to action: a padded anchor inside a coloured cell. */
function button(label: string, url: string): string {
  return (
    '<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 8px 0;">' +
    '<tr><td class="btn" align="center" bgcolor="' +
    BRAND.primary +
    '" style="background:' +
    BRAND.primary +
    ';border-radius:10px;">' +
    '<a href="' +
    escapeHtml(url) +
    '" style="display:inline-block;padding:13px 26px;font-family:Helvetica,' +
    'Arial,sans-serif;font-size:15px;font-weight:bold;color:#ffffff;' +
    'text-decoration:none;border-radius:10px;">' +
    escapeHtml(label) +
    '</a>' +
    '</td></tr></table>'
  );
}

/** Sign-off block. */
function signature(): string {
  return (
    '<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:8px 0 0;">' +
    '<tr>' +
    monogram() +
    '<td width="12" style="width:12px;font-size:0;line-height:0;">&nbsp;</td>' +
    '<td valign="middle" style="font-family:Helvetica,Arial,sans-serif;">' +
    '<p style="margin:0;font-size:14px;font-weight:bold;color:' +
    BRAND.text +
    ';">Solodev</p>' +
    '<p style="margin:2px 0 0;font-size:12px;line-height:16px;color:' +
    BRAND.textFaint +
    ';">Flutter Developer &amp; AI Designer</p>' +
    '</td></tr></table>'
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
    'We have your enquiry and will reply within one business day.',
    '<tr><td class="px" style="padding:26px 32px 30px 32px;">' +
      eyebrow('Enquiry received') +
      heading('Thanks, ' + safeName + '.') +
      paragraph(
        'Your message reached our inbox and is queued for review. ' +
          'You will hear back from us within one business day.',
      ) +
      (subject ? detailCard('Your subject', safeSubject) : '') +
      paragraph(
        'Need something sooner? Replying to this e-mail reaches the same inbox ' +
          'and moves you to the front of the queue.',
      ) +
      button('View the portfolio', PORTFOLIO_SITE_URL) +
      '</td></tr>' +
      '<tr><td class="px" style="padding:0 32px 30px 32px;">' +
      signature() +
      '</td></tr>',
    'You are receiving this because you submitted an enquiry through the Solodev portfolio.',
  );
  const text =
    `Hi ${name},\n\n` +
    `Thanks for your enquiry` +
    (subject ? ` ("${subject}")` : '') +
    '.\n\nWe received it and will get back to you within one business day. ' +
    'If it is urgent, just reply to this e-mail.\n\n' +
    `Portfolio: ${PORTFOLIO_SITE_URL}\n\n- Solodev`;
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
    .filter((p) => p.trim().length > 0)
    .map(
      (p) =>
        '<p style="margin:0 0 14px;font-family:Helvetica,Arial,sans-serif;' +
        'font-size:15px;line-height:23px;color:' +
        BRAND.text +
        ';">' +
        p.replace(/\n/g, '<br/>') +
        '</p>',
    )
    .join('');
  const html = shell(
    replySubject,
    '<tr><td class="px" style="padding:26px 32px 30px 32px;">' +
      eyebrow('Reply from Solodev') +
      heading('Hi ' + escapeHtml(name) + ',') +
      '<p style="margin:0 0 20px;font-family:Helvetica,Arial,sans-serif;' +
      'font-size:16px;line-height:24px;font-weight:bold;color:' +
      BRAND.accent +
      ';">' +
      escapeHtml(replySubject) +
      '</p>' +
      paragraphs +
      button('View the portfolio', PORTFOLIO_SITE_URL) +
      '</td></tr>' +
      '<tr><td class="px" style="padding:0 32px 30px 32px;">' +
      signature() +
      '</td></tr>',
    'You are receiving this because you contacted us through the Solodev portfolio.',
  );
  const text =
    `Hi ${name},\n\n${replySubject}\n\n${replyBody}\n\n` +
    `Portfolio: ${PORTFOLIO_SITE_URL}\n\n- Solodev`;
  return { html, text };
}

/** Self-test message triggered from the admin settings screen. */
export function testEmailTemplate(): { html: string; text: string } {
  const html = shell(
    'SMTP delivery confirmed. No action needed.',
    '<tr><td class="px" style="padding:26px 32px 30px 32px;">' +
      eyebrow('System check') +
      heading('SMTP delivery confirmed.') +
      paragraph(
        'Gmail SMTP is configured correctly for the Solodev portfolio. ' +
          'Client notifications and replies will be delivered from this address.',
      ) +
      detailCard(
        'Status',
        '<span style="color:#10b981;font-weight:bold;">Delivered</span>' +
          ' &nbsp;&middot;&nbsp; templates and logging active',
      ) +
      paragraph(
        'This message was triggered from the admin settings screen. No action ' +
          'is required.',
      ) +
      '</td></tr>' +
      '<tr><td class="px" style="padding:0 32px 30px 32px;">' +
      signature() +
      '</td></tr>',
    'You are receiving this because an SMTP self-test was sent from the Solodev admin console.',
  );
  const text =
    'SMTP delivery confirmed.\n\nGmail SMTP is configured correctly for the ' +
    'Solodev portfolio. Client notifications and replies will be delivered ' +
    'from this address.\n\n- Solodev';
  return { html, text };
}

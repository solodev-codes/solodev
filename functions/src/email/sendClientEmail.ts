/**
 * `sendClientEmail` — administrator-composed e-mail to a client
 * (spec section 59).
 *
 * Three presets:
 *   * `ack`    — acknowledgement for an existing enquiry (server derives the
 *                recipient from the message document, so a client address can
 *                never be spoofed from the browser);
 *   * `reply`  — administrator reply to an enquiry;
 *   * `test`   — self-test delivered to any address the admin controls.
 *
 * All three share the daily cap, audit trail and `email_logs` record written
 * by `sendPortfolioEmail`.
 */
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db } from '../config/admin';
import { COLLECTIONS, REGION } from '../config/constants';
import { assertAdmin } from '../lib/guards';
import {
  isBoundedString,
  isPlainObject,
  isValidEmail,
  sanitiseText,
} from '../lib/validation';
import { GMAIL_APP_PASSWORD, GMAIL_USER, sendPortfolioEmail } from './mailer';
import {
  acknowledgementTemplate,
  replyTemplate,
  testEmailTemplate,
} from './templates';

const SUBJECT_MAX = 200;
const BODY_MAX = 4000;

/**
 * A v2 secret is only readable by the functions that list it in their own
 * options, so this callable declares both — omitting it makes
 * `GMAIL_USER.value()` resolve to `undefined` and every send fails with
 * "Missing credentials for PLAIN".
 */
const EMAIL_OPTIONS = {
  region: REGION,
  secrets: [GMAIL_USER, GMAIL_APP_PASSWORD],
};

export const sendClientEmail = onCall(EMAIL_OPTIONS, async (request) => {
  const callerUid = await assertAdmin(request);

  if (!isPlainObject(request.data)) {
    throw new HttpsError('invalid-argument', 'A request body is required.');
  }

  const { type, messageId, to, subject, body } = request.data as {
    type?: unknown;
    messageId?: unknown;
    to?: unknown;
    subject?: unknown;
    body?: unknown;
  };

  if (type !== 'ack' && type !== 'reply' && type !== 'test') {
    throw new HttpsError(
      'invalid-argument',
      '"type" must be one of "ack", "reply" or "test".',
    );
  }

  if (type === 'test') {
    if (!isValidEmail(to)) {
      throw new HttpsError(
        'invalid-argument',
        'A test e-mail needs a valid "to" address.',
      );
    }
    const { html, text } = testEmailTemplate();
    return sendPortfolioEmail({
      to,
      subject: 'Solodev — SMTP test',
      html,
      text,
      template: 'test',
      actorId: callerUid,
    });
  }

  // `ack` and `reply` always address the stored enquiry, never a client-
  // supplied address.
  if (typeof messageId !== 'string' || messageId.length === 0 || messageId.length > 128) {
    throw new HttpsError('invalid-argument', '"messageId" is malformed.');
  }

  const messageDoc = await db
    .collection(COLLECTIONS.messages)
    .doc(messageId)
    .get();

  if (!messageDoc.exists) {
    throw new HttpsError('not-found', 'That enquiry no longer exists.');
  }

  const message = messageDoc.data() ?? {};
  const clientEmail = typeof message.email === 'string' ? message.email : '';
  const clientName =
    typeof message.name === 'string' && message.name.trim().length > 0
      ? message.name
      : 'there';
  const originalSubject =
    typeof message.subject === 'string' ? message.subject : '';

  if (!isValidEmail(clientEmail)) {
    throw new HttpsError(
      'failed-precondition',
      'This enquiry has no valid e-mail address to reply to.',
    );
  }

  if (type === 'ack') {
    const { html, text } = acknowledgementTemplate(clientName, originalSubject);
    return sendPortfolioEmail({
      to: clientEmail,
      subject: originalSubject
        ? `Re: ${originalSubject}`
        : 'We received your enquiry',
      html,
      text,
      template: 'acknowledgement',
      actorId: callerUid,
      messageId,
    });
  }

  if (!isBoundedString(subject, 3, SUBJECT_MAX)) {
    throw new HttpsError(
      'invalid-argument',
      `"subject" must be between 3 and ${SUBJECT_MAX} characters.`,
    );
  }

  if (!isBoundedString(body, 5, BODY_MAX)) {
    throw new HttpsError(
      'invalid-argument',
      `"body" must be between 5 and ${BODY_MAX} characters.`,
    );
  }

  const { html, text } = replyTemplate(
    clientName,
    sanitiseText(subject),
    sanitiseText(body),
  );

  return sendPortfolioEmail({
    to: clientEmail,
    subject: sanitiseText(subject),
    html,
    text,
    template: 'reply',
    actorId: callerUid,
    messageId,
  });
});

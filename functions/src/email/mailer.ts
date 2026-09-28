/**
 * Gmail SMTP delivery for client e-mail (spec section 59).
 *
 * Credentials are Secret Manager values (`GMAIL_USER`, `GMAIL_APP_PASSWORD`)
 * bound with `defineSecret`, so they never appear in source, logs or config
 * files. Every send is capped per UTC day and recorded in `email_logs` plus
 * the audit trail, which keeps the collection a truthful record of what the
 * system actually delivered.
 */
import { HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { Timestamp } from 'firebase-admin/firestore';
import nodemailer from 'nodemailer';

import { db } from '../config/admin';
import { COLLECTIONS, EMAIL_DAILY_CAP } from '../config/constants';
import { SYSTEM_ACTOR, writeAuditLog } from '../lib/audit';
import { logger } from '../lib/logger';

/** Gmail account that sends client mail, e.g. `you@gmail.com`. */
export const GMAIL_USER = defineSecret('GMAIL_USER');

/** 16-character Gmail App Password for the account above. */
export const GMAIL_APP_PASSWORD = defineSecret('GMAIL_APP_PASSWORD');

/** Template kinds recorded in `email_logs`. */
export type EmailTemplate = 'acknowledgement' | 'reply' | 'test';

export interface SendEmailInput {
  to: string;
  subject: string;
  html: string;
  text: string;
  template: EmailTemplate;
  /** UID of the administrator, or `system` for automatic messages. */
  actorId: string;
  /** Related enquiry, when the e-mail answers one. */
  messageId?: string;
}

/** Start of the current UTC day, used as the daily-cap window boundary. */
function startOfUtcDay(): Date {
  const now = new Date();
  return new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
}

/**
 * Enforces the server-side daily cap before any SMTP traffic.
 *
 * The client cannot be trusted to throttle itself: a compromised or buggy
 * admin session must not be able to turn the portfolio into a spam cannon.
 */
async function assertDailyCap(): Promise<void> {
  const snapshot = await db
    .collection(COLLECTIONS.emailLogs)
    .where('createdAt', '>=', Timestamp.fromDate(startOfUtcDay()))
    .count()
    .get();
  const sentToday = snapshot.data().count;
  if (sentToday >= EMAIL_DAILY_CAP) {
    throw new HttpsError(
      'resource-exhausted',
      `Daily e-mail limit reached (${EMAIL_DAILY_CAP}/day). Try again after midnight UTC.`,
    );
  }
}

/**
 * Sends one e-mail over Gmail SMTP and records it.
 *
 * @throws HttpsError `failed-precondition` when the secrets are missing.
 * @throws HttpsError `resource-exhausted` when the daily cap is reached.
 * @throws HttpsError `internal` when SMTP delivery fails; nothing is logged
 *         as sent in that case, so the log never claims a delivery that
 *         did not happen.
 */
export async function sendPortfolioEmail(
  input: SendEmailInput,
): Promise<{ emailId: string }> {
  await assertDailyCap();

  let user: string;
  let password: string;
  try {
    user = GMAIL_USER.value();
    password = GMAIL_APP_PASSWORD.value();
  } catch (error) {
    logger.error('email.secrets_missing', error);
    throw new HttpsError('failed-precondition', NOT_CONFIGURED);
  }
  // A secret missing from the caller's `secrets` option resolves to
  // `undefined` rather than throwing, so emptiness has to be checked as well;
  // without this the failure surfaces as an opaque SMTP error.
  if (!user || !password) {
    logger.error('email.secrets_missing', {
      userBound: user !== undefined,
      passwordBound: password !== undefined,
    });
    throw new HttpsError('failed-precondition', NOT_CONFIGURED);
  }

  const transport = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: { user, pass: password },
  });

  try {
    await transport.sendMail({
      from: `"Solodev Portfolio" <${user}>`,
      to: input.to,
      subject: input.subject,
      html: input.html,
      text: input.text,
    });
  } catch (error) {
    logger.error('email.smtp_failed', error, {
      to: input.to,
      template: input.template,
    });
    throw new HttpsError('internal', 'The e-mail could not be delivered.');
  }

  const logRef = await db.collection(COLLECTIONS.emailLogs).add({
    to: input.to,
    subject: input.subject,
    template: input.template,
    messageId: input.messageId ?? null,
    status: 'sent',
    createdAt: Timestamp.now(),
  });

  await writeAuditLog({
    actorId: input.actorId,
    action: 'email.sent',
    collection: COLLECTIONS.emailLogs,
    documentId: logRef.id,
    details: {
      to: input.to,
      template: input.template,
      messageId: input.messageId ?? null,
    },
  });

  return { emailId: logRef.id };
}

/** Actor id used for automatic (trigger-driven) mail. */
export const EMAIL_SYSTEM_ACTOR = SYSTEM_ACTOR;

/** Message reused whenever the Gmail secrets are not available. */
const NOT_CONFIGURED =
  'E-mail is not configured. Run: firebase functions:secrets:set GMAIL_USER '
  + 'and firebase functions:secrets:set GMAIL_APP_PASSWORD';

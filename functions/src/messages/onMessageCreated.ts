import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { FieldValue } from '../config/admin';
import {
  COLLECTIONS,
  MESSAGE_LIMITS,
  NOTIFICATION_TYPES,
  REGION,
} from '../config/constants';
import { SYSTEM_ACTOR, writeAuditLog } from '../lib/audit';
import { logger } from '../lib/logger';
import { createNotification, sendToAdmins } from '../lib/notifications';
import {
  isBoundedString,
  isValidEmail,
  sanitiseText,
} from '../lib/validation';
import { EMAIL_SYSTEM_ACTOR, GMAIL_APP_PASSWORD, GMAIL_USER, sendPortfolioEmail } from '../email/mailer';
import { acknowledgementTemplate } from '../email/templates';

const MESSAGE_DOCUMENT = `${COLLECTIONS.messages}/{messageId}`;

/**
 * Normalises a newly submitted enquiry, then alerts the administrators.
 *
 * The security rules already reject malformed submissions, but this trigger is
 * the last point at which content can be normalised before it reaches the
 * inbox, so it re-validates independently and records the outcome in a
 * `validated` flag rather than trusting the client.
 *
 * It also stamps a server-side `receivedAt`, which is the ordering value the
 * dashboard should trust over the client-supplied `createdAt`.
 */
export const onMessageCreated = onDocumentCreated(
  {
    region: REGION,
    document: MESSAGE_DOCUMENT,
    // Bound lazily so a deployment without the Gmail secrets still registers
    // the trigger; the acknowledgement below degrades gracefully if they are
    // absent (spec section 59).
    secrets: [GMAIL_USER, GMAIL_APP_PASSWORD],
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const messageId = event.params.messageId;
    const data = snapshot.data();

    const asString = (value: unknown): string =>
      typeof value === 'string' ? sanitiseText(value) : '';

    const name = asString(data.name);
    const email = asString(data.email);
    const subject = asString(data.subject);
    const body = asString(data.message);

    const isValid =
      isBoundedString(name, MESSAGE_LIMITS.nameMin, MESSAGE_LIMITS.nameMax) &&
      isValidEmail(email) &&
      isBoundedString(body, MESSAGE_LIMITS.messageMin, MESSAGE_LIMITS.messageMax);

    await snapshot.ref.set(
      {
        name,
        email,
        subject,
        message: body,
        // The lifecycle state is owned by the backend, never by the submitter.
        status: 'new',
        validated: isValid,
        receivedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await writeAuditLog({
      actorId: SYSTEM_ACTOR,
      action: 'message.received',
      collection: COLLECTIONS.messages,
      documentId: messageId,
      details: { validated: isValid },
    });

    if (!isValid) {
      logger.warn('message.invalid_payload_quarantined', { messageId });
      return;
    }

    const summary = subject.length > 0 ? subject : email;

    await createNotification({
      type: NOTIFICATION_TYPES.newMessage,
      title: 'New enquiry received',
      body: `${name} — ${summary}`,
      link: '/admin/dashboard',
      metadata: { messageId, email },
    });

    await sendToAdmins(
      'New portfolio enquiry',
      `${name}: ${summary}`,
      '/admin/dashboard',
    );

    // Automatic acknowledgement to the visitor (spec section 59). Strictly
    // best-effort: an SMTP hiccup or a deployment without secrets must never
    // fail the enquiry pipeline that has already succeeded above.
    try {
      const { html, text } = acknowledgementTemplate(name, subject);
      await sendPortfolioEmail({
        to: email,
        subject: subject.length > 0 ? `Re: ${subject}` : 'We received your enquiry',
        html,
        text,
        template: 'acknowledgement',
        actorId: EMAIL_SYSTEM_ACTOR,
        messageId,
      });
    } catch (error) {
      logger.warn('email.acknowledgement_failed', { messageId, error });
    }
  },
);

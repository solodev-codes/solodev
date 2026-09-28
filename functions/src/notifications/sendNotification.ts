import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { COLLECTIONS, NOTIFICATION_TYPES, REGION } from '../config/constants';
import { writeAuditLog } from '../lib/audit';
import { assertAdmin } from '../lib/guards';
import { logger } from '../lib/logger';
import { createNotification, sendToAdmins } from '../lib/notifications';
import { isBoundedString, isPlainObject, sanitiseText } from '../lib/validation';

/** Length limits for a composed notification, mirroring the dashboard form. */
const TITLE_MAX = 120;
const BODY_MAX = 1000;
const LINK_MAX = 300;

/**
 * Broadcasts an administrator-composed notification.
 *
 * `firestore.rules` refuses every client write to `notifications`, so this
 * callable is the only path a compose form can take: the document and the push
 * payload are both written server-side, which keeps the collection trustworthy
 * as a record of what the system actually announced.
 *
 * A push failure is reported but never rolls the notification document back —
 * the in-app inbox is the durable channel, and a device that missed a push
 * still sees the entry when it next opens the dashboard.
 */
export const sendNotification = onCall({ region: REGION }, async (request) => {
  const callerUid = await assertAdmin(request);

  if (!isPlainObject(request.data)) {
    throw new HttpsError('invalid-argument', 'A request body is required.');
  }

  const { title, body, link, recipientId } = request.data as {
    title?: unknown;
    body?: unknown;
    link?: unknown;
    recipientId?: unknown;
  };

  if (!isBoundedString(title, 3, TITLE_MAX)) {
    throw new HttpsError(
      'invalid-argument',
      `"title" must be between 3 and ${TITLE_MAX} characters.`,
    );
  }

  if (!isBoundedString(body, 3, BODY_MAX)) {
    throw new HttpsError(
      'invalid-argument',
      `"body" must be between 3 and ${BODY_MAX} characters.`,
    );
  }

  let sanitisedLink: string | undefined;
  if (link !== undefined && link !== null && link !== '') {
    if (!isBoundedString(link, 1, LINK_MAX)) {
      throw new HttpsError(
        'invalid-argument',
        `"link" must be at most ${LINK_MAX} characters.`,
      );
    }
    // Only in-app destinations are accepted: a push payload must never be able
    // to steer an elevated session onto an arbitrary external origin.
    sanitisedLink = sanitiseText(link);
    if (!sanitisedLink.startsWith('/')) {
      throw new HttpsError(
        'invalid-argument',
        '"link" must be an in-app path beginning with "/".',
      );
    }
  }

  let sanitisedRecipient: string | undefined;
  if (recipientId !== undefined && recipientId !== null && recipientId !== '') {
    if (typeof recipientId !== 'string' || recipientId.length > 128) {
      throw new HttpsError('invalid-argument', '"recipientId" is malformed.');
    }
    sanitisedRecipient = recipientId;
  }

  const payload = {
    type: NOTIFICATION_TYPES.system,
    title: sanitiseText(title),
    body: sanitiseText(body),
    link: sanitisedLink,
    metadata: { composedBy: callerUid },
    recipientId: sanitisedRecipient,
  };

  const notificationId = await createNotification(payload);

  let delivered = true;
  try {
    await sendToAdmins(payload.title, payload.body, payload.link, sanitisedRecipient);
  } catch (error) {
    delivered = false;
    logger.error('notifications.push_failed', error, {
      notificationId,
      actorId: callerUid,
    });
  }

  await writeAuditLog({
    actorId: callerUid,
    action: 'notification.sent',
    collection: COLLECTIONS.notifications,
    documentId: notificationId,
    details: {
      recipientId: sanitisedRecipient ?? 'broadcast',
      link: sanitisedLink ?? null,
      pushDelivered: delivered,
    },
  });

  return { notificationId, pushDelivered: delivered };
});

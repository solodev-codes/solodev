import {
  onDocumentDeleted,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import { FieldValue } from '../config/admin';
import { COLLECTIONS, MESSAGE_STATUSES, REGION } from '../config/constants';
import { SYSTEM_ACTOR, writeAuditLog } from '../lib/audit';
import { logger } from '../lib/logger';
import { isOneOf } from '../lib/validation';

const MESSAGE_DOCUMENT = `${COLLECTIONS.messages}/{messageId}`;

/**
 * Maintains the enquiry lifecycle when its status changes.
 *
 * Two responsibilities. First, it rejects an unrecognised status by reverting
 * the document, so a bad write cannot leave the inbox in a state the UI cannot
 * render. Second, it stamps the matching transition timestamp and appends an
 * audit record, giving every enquiry an attributable history.
 */
export const onMessageStatusChanged = onDocumentUpdated(
  { region: REGION, document: MESSAGE_DOCUMENT },
  async (event) => {
    const change = event.data;
    if (!change) {
      return;
    }

    const before = change.before.data();
    const after = change.after.data();
    const messageId = event.params.messageId;

    if (before.status === after.status) {
      return;
    }

    if (!isOneOf(after.status, MESSAGE_STATUSES)) {
      const reverted = isOneOf(before.status, MESSAGE_STATUSES)
        ? before.status
        : 'new';

      await change.after.ref.set({ status: reverted }, { merge: true });

      logger.warn('message.invalid_status_reverted', {
        messageId,
        attempted: String(after.status),
        revertedTo: reverted,
      });

      await writeAuditLog({
        actorId: SYSTEM_ACTOR,
        action: 'message.invalid_status_reverted',
        collection: COLLECTIONS.messages,
        documentId: messageId,
        details: { attempted: String(after.status), revertedTo: reverted },
      });
      return;
    }

    const patch: Record<string, unknown> = {
      statusChangedAt: FieldValue.serverTimestamp(),
    };

    if (after.status === 'replied' && !after.repliedAt) {
      patch.repliedAt = FieldValue.serverTimestamp();
    }
    if (after.status === 'closed' && !after.closedAt) {
      patch.closedAt = FieldValue.serverTimestamp();
    }

    await change.after.ref.set(patch, { merge: true });

    await writeAuditLog({
      // `updatedBy` is set by the admin client; falls back to `system` when the
      // change originated outside the dashboard.
      actorId:
        typeof after.updatedBy === 'string' ? after.updatedBy : SYSTEM_ACTOR,
      action: 'message.status_changed',
      collection: COLLECTIONS.messages,
      documentId: messageId,
      details: {
        from: typeof before.status === 'string' ? before.status : null,
        to: after.status,
      },
    });
  },
);

/**
 * Records the deletion of an enquiry.
 *
 * The enquiry body is deliberately not copied into the audit entry: the audit
 * log is readable by every administrator and outlives the record, so retaining
 * a full copy there would defeat the deletion.
 */
export const onMessageDeleted = onDocumentDeleted(
  { region: REGION, document: MESSAGE_DOCUMENT },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data();

    await writeAuditLog({
      actorId: SYSTEM_ACTOR,
      action: 'message.deleted',
      collection: COLLECTIONS.messages,
      documentId: event.params.messageId,
      details: {
        email: typeof data.email === 'string' ? data.email : null,
        status: typeof data.status === 'string' ? data.status : null,
      },
    });
  },
);

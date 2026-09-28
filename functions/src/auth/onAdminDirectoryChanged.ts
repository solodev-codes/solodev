import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { COLLECTIONS, REGION } from '../config/constants';
import { SYSTEM_ACTOR, writeAuditLog } from '../lib/audit';
import { logger } from '../lib/logger';

/**
 * Audits every change to the administrator directory.
 *
 * `setAdminClaim` already records the administrator who granted or revoked
 * access. This trigger exists as a safety net for changes made *outside* that
 * callable, specifically the Firebase console and any direct Admin SDK use,
 * which bypass security rules and are therefore invisible to the application.
 *
 * The recorded `actorId` is `system` because an out-of-band writer has no
 * authenticated identity visible to the trigger. Entries are intentionally
 * allowed to duplicate the `setAdminClaim` audit line: an extra record is
 * harmless, whereas a missing one would mean an unexplained privilege change.
 */
export const onAdminDirectoryChanged = onDocumentWritten(
  {
    region: REGION,
    document: `${COLLECTIONS.admins}/{adminId}`,
  },
  async (event) => {
    const change = event.data;
    if (!change) {
      logger.warn('admin.directory_change_missing_payload', {
        adminId: event.params.adminId,
      });
      return;
    }

    const existedBefore = change.before.exists;
    const existsAfter = change.after.exists;

    if (existedBefore === existsAfter) {
      // Field-level update; the value change is recorded below.
      if (!existsAfter) return;
    }

    let action: string;
    if (!existedBefore && existsAfter) {
      action = 'admin.directory_created';
    } else if (existedBefore && !existsAfter) {
      action = 'admin.directory_deleted';
    } else {
      action = 'admin.directory_updated';
    }

    const adminId = event.params.adminId;
    const after = existsAfter ? change.after.data() : undefined;

    await writeAuditLog({
      actorId: SYSTEM_ACTOR,
      action,
      collection: COLLECTIONS.admins,
      documentId: adminId,
      details: {
        email: typeof after?.email === 'string' ? after.email : null,
        grantedBy:
          typeof after?.grantedBy === 'string' ? after.grantedBy : null,
      },
    });
  },
);

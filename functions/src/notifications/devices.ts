import { Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, FieldValue } from '../config/admin';
import { COLLECTIONS, REGION } from '../config/constants';
import { assertAdmin } from '../lib/guards';
import { logger } from '../lib/logger';
import { isPlainObject } from '../lib/validation';

/**
 * Device registrations untouched for this long are considered abandoned.
 *
 * Dead tokens are pruned on a schedule rather than only when FCM rejects them,
 * so a device that simply stopped refreshing cannot linger indefinitely.
 */
const DEVICE_TTL_DAYS = 180;

/**
 * Registers a push token for the signed-in administrator.
 *
 * The token document is keyed by the token itself rather than the UID, so a
 * single administrator holding two devices keeps both registrations. The UID
 * is taken from the caller's auth context and never from the request body, so
 * no administrator can hijack another account's delivery.
 *
 * `firestore.rules` refuses all client writes to `devices`, making this
 * callable the sole registration path.
 */
export const registerDevice = onCall({ region: REGION }, async (request) => {
  const uid = await assertAdmin(request);

  if (!isPlainObject(request.data)) {
    throw new HttpsError('invalid-argument', 'A request body is required.');
  }

  const { token, platform } = request.data as {
    token?: unknown;
    platform?: unknown;
  };

  if (typeof token !== 'string' || token.trim().length === 0) {
    throw new HttpsError('invalid-argument', '"token" is required.');
  }

  const cleanToken = token.trim();
  const platformLabel = typeof platform === 'string' ? platform : 'unknown';

  await db
    .collection(COLLECTIONS.devices)
    .doc(encodeURIComponent(cleanToken))
    .set(
      {
        token: cleanToken,
        uid,
        platform: platformLabel,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  logger.info('devices.registered', { uid, platform: platformLabel });
  return { registered: true };
});

/**
 * Removes device registrations that have not refreshed within the TTL.
 *
 * Runs on an administrator-configured schedule. Pruning by age is deliberately
 * conservative: it only reclaims devices that have been silent for six months,
 * while `sendToAdmins` handles the immediate case of a token FCM reports as
 * permanently invalid.
 */
export const pruneStaleTokens = onSchedule(
  {
    region: REGION,
    schedule: 'every 24 hours',
    timeZone: 'UTC',
  },
  async () => {
    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - DEVICE_TTL_DAYS * 24 * 60 * 60 * 1000),
    );

    const stale = await db
      .collection(COLLECTIONS.devices)
      .where('updatedAt', '<', cutoff)
      .get();

    if (stale.empty) {
      logger.info('devices.prune_none');
      return;
    }

    let removed = 0;
    for (const doc of stale.docs) {
      await doc.ref.delete();
      removed += 1;
    }

    logger.info('devices.pruned', { removed, ttlDays: DEVICE_TTL_DAYS });
  },
);

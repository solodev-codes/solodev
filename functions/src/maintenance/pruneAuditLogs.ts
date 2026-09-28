import { Timestamp } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db } from '../config/admin';
import {
  AUDIT_RETENTION_DAYS,
  COLLECTIONS,
  REGION,
} from '../config/constants';
import { logger } from '../lib/logger';

/** Maximum deletions committed per Firestore batch. */
const BATCH_SIZE = 400;

/**
 * Prunes audit records that have passed the retention window.
 *
 * Reads and deletes in bounded batches rather than materialising the whole
 * collection, so the job stays well inside the function's memory limit even
 * after years of accumulated history. Documents with no `createdAt` (an
 * interrupted write) are never matched by the range query and are therefore
 * left alone rather than silently discarded.
 */
export const pruneAuditLogs = onSchedule(
  { region: REGION, schedule: 'every 24 hours', timeZone: 'UTC' },
  async () => {
    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - AUDIT_RETENTION_DAYS * 24 * 60 * 60 * 1000),
    );

    const collection = db.collection(COLLECTIONS.auditLogs);
    let removed = 0;

    for (;;) {
      const page = await collection
        .where('createdAt', '<', cutoff)
        .limit(BATCH_SIZE)
        .get();

      if (page.empty) {
        break;
      }

      const writeBatch = db.batch();
      for (const doc of page.docs) {
        writeBatch.delete(doc.ref);
        removed += 1;
      }
      await writeBatch.commit();

      if (page.size < BATCH_SIZE) {
        break;
      }
    }

    logger.info('audit.pruned', {
      removed,
      retentionDays: AUDIT_RETENTION_DAYS,
    });
  },
);

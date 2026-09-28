import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { storage } from '../config/admin';
import { COLLECTIONS, REGION } from '../config/constants';
import { SYSTEM_ACTOR, writeAuditLog } from '../lib/audit';
import { logger } from '../lib/logger';

/**
 * Deletes the backing Storage object when its media document is removed.
 *
 * Keeping the two stores in step stops the bucket from accumulating objects
 * that no longer appear anywhere in the admin media library. `cleanupOrphans`
 * performs the same reconciliation from the opposite direction, for objects
 * that were removed from the bucket directly.
 */
export const onMediaDeleted = onDocumentDeleted(
  { region: REGION, document: `${COLLECTIONS.media}/{mediaId}` },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const mediaId = event.params.mediaId;
    const data = snapshot.data();
    const storagePath =
      typeof data.storagePath === 'string' ? data.storagePath : '';

    if (storagePath.length === 0) {
      logger.warn('media.delete_missing_storage_path', { mediaId });
      return;
    }

    try {
      const bucketName =
        typeof data.bucket === 'string' && data.bucket.length > 0
          ? data.bucket
          : undefined;

      const file = bucketName
        ? storage.bucket(bucketName).file(storagePath)
        : storage.bucket().file(storagePath);

      await file.delete({ ignoreNotFound: true });

      await writeAuditLog({
        actorId: SYSTEM_ACTOR,
        action: 'media.object_deleted',
        collection: COLLECTIONS.media,
        documentId: mediaId,
        details: { storagePath },
      });
    } catch (error) {
      // The document is already gone, so there is nothing to roll back.
      // `cleanupOrphans` reconciles this leftover on its next run.
      logger.error('media.object_delete_failed', error, { storagePath });
    }
  },
);

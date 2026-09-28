import { onObjectFinalized as onStorageObjectFinalized } from 'firebase-functions/v2/storage';
import { db, FieldValue, storage } from '../config/admin';
import {
  ALLOWED_CONTENT_TYPES,
  ALLOWED_CONTENT_TYPE_PREFIXES,
  COLLECTIONS,
  MAX_UPLOAD_BYTES,
  NOTIFICATION_TYPES,
  REGION,
  STORAGE,
  resolveStorageBucket,
} from '../config/constants';
import { SYSTEM_ACTOR, writeAuditLog } from '../lib/audit';
import { logger } from '../lib/logger';
import { createNotification } from '../lib/notifications';

/** True when the content type is inside the portfolio's allowlist. */
function isAllowedContentType(contentType: string): boolean {
  if (ALLOWED_CONTENT_TYPE_PREFIXES.some((p) => contentType.startsWith(p))) {
    return true;
  }
  return (ALLOWED_CONTENT_TYPES as readonly string[]).includes(contentType);
}

/**
 * Indexes each uploaded portfolio object and enforces the upload policy.
 *
 * The Storage rules already bound size and content type for client uploads, but
 * the Admin SDK and the Firebase console bypass those rules. Any object that
 * reaches this trigger outside the policy is therefore deleted and recorded,
 * rather than being left in place because the rules "should" have caught it.
 *
 * The media document ID is the URL-encoded storage path, which guarantees a
 * one-to-one mapping with the object and makes re-uploads idempotent.
 */
export const onObjectFinalized = onStorageObjectFinalized(
  // The bucket is supplied explicitly so registration never depends on
  // `FIREBASE_CONFIG` being present; see `resolveStorageBucket`.
  { region: REGION, memory: '256MiB', bucket: resolveStorageBucket() },
  async (event) => {
    const object = event.data;
    const name = object.name ?? '';
    const bucket = object.bucket;

    // Only portfolio media is tracked; derived thumbnails and unrelated
    // buckets or prefixes are ignored.
    if (!name.startsWith(`${STORAGE.publicMedia}/`)) {
      return;
    }

    const contentType = object.contentType ?? '';
    const size = Number(object.size ?? 0);

    const withinPolicy =
      isAllowedContentType(contentType) &&
      size > 0 &&
      size <= MAX_UPLOAD_BYTES;

    if (!withinPolicy) {
      logger.warn('media.upload_rejected', { name, contentType, size });

      await storage.bucket(bucket).file(name).delete({ ignoreNotFound: true });

      await writeAuditLog({
        actorId: SYSTEM_ACTOR,
        action: 'media.upload_rejected',
        collection: COLLECTIONS.media,
        documentId: name,
        details: { contentType, size, maxBytes: MAX_UPLOAD_BYTES },
      });
      return;
    }

    await db
      .collection(COLLECTIONS.media)
      .doc(encodeURIComponent(name))
      .set(
        {
          storagePath: name,
          bucket,
          contentType,
          size,
          md5Hash: object.md5Hash ?? null,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    await writeAuditLog({
      actorId: SYSTEM_ACTOR,
      action: 'media.indexed',
      collection: COLLECTIONS.media,
      documentId: name,
      details: { contentType, size },
    });

    await createNotification({
      type: NOTIFICATION_TYPES.mediaUploaded,
      title: 'Media uploaded',
      body: name,
      link: '/admin/dashboard',
      metadata: { storagePath: name, contentType, size },
    });
  },
);

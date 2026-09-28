import { getApps, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';

/**
 * Initialises the Firebase Admin SDK exactly once per function instance.
 *
 * The Admin SDK bypasses Firestore and Storage security rules. Every write
 * performed through these handles is therefore a privileged operation and must
 * be justified by server-side checks in the calling module, never by client
 * input.
 */
if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const messaging = getMessaging();
export const storage = getStorage();

export { FieldValue };

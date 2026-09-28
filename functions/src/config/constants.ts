/**
 * Shared constants for the Solodev portfolio backend.
 *
 * Collection names are centralised so a typo can never silently create a
 * parallel, rule-less collection, and the length limits here intentionally
 * mirror `firestore.rules` so client-side and server-side validation agree.
 */

/** Cloud Functions deployment region. */
export const REGION = 'us-central1';

/** Firestore collections managed by the portfolio. */
export const COLLECTIONS = {
  projects: 'projects',
  services: 'services',
  certificates: 'certificates',
  achievements: 'achievements',
  experiences: 'experiences',
  skills: 'skills',
  testimonials: 'testimonials',
  settings: 'settings',
  messages: 'messages',
  notifications: 'notifications',
  media: 'media',
  admins: 'admins',
  auditLogs: 'audit_logs',
  analytics: 'analytics',
  devices: 'devices',
  emailLogs: 'email_logs',
} as const;

/** Cloud Storage prefixes managed by the portfolio. */
export const STORAGE = {
  publicMedia: 'portfolio',
  thumbnails: 'thumbnails',
} as const;

/**
 * Resolves the bucket targeted by the Storage triggers.
 *
 * `firebase-functions` falls back to `FIREBASE_CONFIG.storageBucket` and throws
 * *eagerly at module scope* when neither is available. That aborts the module
 * before any export can be registered, which surfaces as
 * "User code failed to load. Cannot determine backend specification" during
 * deployment. Resolving the bucket here and passing it explicitly makes trigger
 * registration independent of the environment the module happens to load in.
 */
export function resolveStorageBucket(): string {
  const raw = process.env.FIREBASE_CONFIG;
  if (raw) {
    try {
      const parsed: unknown = JSON.parse(raw);
      if (
        typeof parsed === 'object' &&
        parsed !== null &&
        'storageBucket' in parsed
      ) {
        const bucket = (parsed as { storageBucket?: unknown }).storageBucket;
        if (typeof bucket === 'string' && bucket.length > 0) {
          return bucket;
        }
      }
    } catch {
      // Malformed FIREBASE_CONFIG; fall through to the fallbacks below.
    }
  }

  const project = process.env.GCLOUD_PROJECT;
  if (typeof project === 'string' && project.length > 0) {
    return `${project}.appspot.com`;
  }

  // Last resort: the default bucket of the registered project.
  return 'solodevportfolio.appspot.com';
}

/** Maximum accepted upload size in bytes (25 MB). */
export const MAX_UPLOAD_BYTES = 25 * 1024 * 1024;

/** Content type prefixes accepted for uploads. */
export const ALLOWED_CONTENT_TYPE_PREFIXES = ['image/', 'video/'] as const;

/** Exact content types accepted in addition to the prefixes above. */
export const ALLOWED_CONTENT_TYPES = ['application/pdf'] as const;

/** Contact enquiry length limits, mirroring the Firestore rules. */
export const MESSAGE_LIMITS = {
  nameMin: 2,
  nameMax: 100,
  emailMax: 200,
  subjectMax: 200,
  messageMin: 6,
  messageMax: 4000,
} as const;

/** Every valid contact message lifecycle state. */
export const MESSAGE_STATUSES = [
  'new',
  'read',
  'in_progress',
  'replied',
  'closed',
] as const;

export type MessageStatus = (typeof MESSAGE_STATUSES)[number];

/** Notification categories surfaced to administrators. */
export const NOTIFICATION_TYPES = {
  newMessage: 'new_message',
  mediaUploaded: 'media_uploaded',
  system: 'system',
} as const;

/** Analytics rollups older than this many days are pruned. */
export const ANALYTICS_RETENTION_DAYS = 400;

/** Server-side cap on outbound client e-mails per UTC day (spec section 59). */
export const EMAIL_DAILY_CAP = 400;

/** Retention for the outbound e-mail log, in days. */
export const EMAIL_LOG_RETENTION_DAYS = 365;

/**
 * Audit records older than this many days are pruned.
 *
 * Deliberately far longer than the analytics window: an audit trail exists to
 * answer "who did this and when" months after the fact, so trimming it at the
 * same cadence as a dashboard metric would defeat its purpose.
 */
export const AUDIT_RETENTION_DAYS = 1095;

/** Firestore collection holding registered administrator push tokens. */
export const DEVICE_COLLECTION = COLLECTIONS.devices;

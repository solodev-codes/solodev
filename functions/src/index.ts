/**
 * Cloud Functions entry point for the Solodev portfolio.
 *
 * Every export below becomes a deployed function, and the export name *is* the
 * deployed function name. Renaming an export therefore provisions a new
 * function and orphans the old one on the next deploy, so treat these names as
 * part of the public surface of the project rather than local identifiers.
 *
 * The module deliberately exports functions only: `package.json` points `main`
 * at `lib/index.js`, the compiled output of this file, and Firebase inspects
 * these exports to discover what to deploy.
 */

// Administrator access control.
export { setAdminClaim } from './auth/setAdminClaim';
export { onAdminDirectoryChanged } from './auth/onAdminDirectoryChanged';

// Contact enquiry lifecycle.
export { onMessageCreated } from './messages/onMessageCreated';
export {
  onMessageStatusChanged,
  onMessageDeleted,
} from './messages/messagesLifecycle';

// Media library indexing and Storage reconciliation.
export { onObjectFinalized } from './media/onObjectFinalized';
export { onMediaDeleted } from './media/onMediaDeleted';

// Push registration and retention.
export { registerDevice, pruneStaleTokens } from './notifications/devices';

// Administrator-composed notifications.
export { sendNotification } from './notifications/sendNotification';

// Client e-mail over Gmail SMTP (spec section 59).
export { sendClientEmail } from './email/sendClientEmail';

// Server-derived portfolio summary.
export {
  refreshPortfolioStats,
  dailyStatsRollup,
} from './analytics/analytics';

// Audit history retention.
export { pruneAuditLogs } from './maintenance/pruneAuditLogs';

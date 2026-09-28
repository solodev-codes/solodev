import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, FieldValue } from '../config/admin';
import { COLLECTIONS, REGION } from '../config/constants';
import { SYSTEM_ACTOR } from '../lib/audit';
import { assertAdmin } from '../lib/guards';
import { logger } from '../lib/logger';

/** Document ID of the single portfolio summary the dashboard reads. */
const STATS_DOCUMENT = 'portfolio_stats';

/** Message states that count as still needing a response. */
const OPEN_STATUSES = new Set<string>(['new', 'read', 'in_progress']);

/** The server-derived summary of the portfolio's current state. */
interface PortfolioStats {
  totalProjects: number;
  publishedProjects: number;
  publishedSkills: number;
  totalMessages: number;
  newMessages: number;
  openMessages: number;
}

/**
 * Counts the collections the dashboard summarises.
 *
 * Every figure is derived from the database on the server, so no client can
 * inflate a metric and the numbers always match what the rules would let an
 * administrator see. Projections are used to avoid loading entire documents.
 */
async function computeStats(): Promise<PortfolioStats> {
  const projects = await db
    .collection(COLLECTIONS.projects)
    .select('isPublished')
    .get();

  const skills = await db
    .collection(COLLECTIONS.skills)
    .select('isPublished')
    .get();

  const messages = await db
    .collection(COLLECTIONS.messages)
    .select('status')
    .get();

  const stats: PortfolioStats = {
    totalProjects: projects.size,
    publishedProjects: 0,
    publishedSkills: 0,
    totalMessages: messages.size,
    newMessages: 0,
    openMessages: 0,
  };

  projects.forEach((doc) => {
    if (doc.get('isPublished') === true) stats.publishedProjects += 1;
  });

  skills.forEach((doc) => {
    if (doc.get('isPublished') === true) stats.publishedSkills += 1;
  });

  messages.forEach((doc) => {
    const status = doc.get('status');
    if (status === 'new') stats.newMessages += 1;
    if (OPEN_STATUSES.has(status)) stats.openMessages += 1;
  });

  return stats;
}

/** Writes the computed summary to `analytics/portfolio_stats`. */
async function publishStats(actorId: string): Promise<PortfolioStats> {
  const stats = await computeStats();

  await db
    .collection(COLLECTIONS.analytics)
    .doc(STATS_DOCUMENT)
    .set(
      { ...stats, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );

  logger.info('analytics.stats_published', { actorId, ...stats });
  return stats;
}

/**
 * Recomputes the portfolio summary on demand.
 *
 * Used after a bulk edit so the dashboard does not wait for the next scheduled
 * run. Restricted to administrators, because although the figures are not
 * sensitive, an unauthenticated caller could otherwise trigger repeated full
 * collection scans.
 */
export const refreshPortfolioStats = onCall(
  { region: REGION },
  async (request) => {
    await assertAdmin(request);
    return publishStats(request.auth?.uid ?? SYSTEM_ACTOR);
  },
);

/** Recomputes the summary once a day. */
export const dailyStatsRollup = onSchedule(
  { region: REGION, schedule: 'every 24 hours', timeZone: 'UTC' },
  async () => {
    try {
      await publishStats(SYSTEM_ACTOR);
    } catch (error) {
      logger.error('analytics.rollup_failed', error);
      throw error;
    }
  },
);

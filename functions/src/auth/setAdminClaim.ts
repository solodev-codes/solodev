import { getAuth } from 'firebase-admin/auth';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db, FieldValue } from '../config/admin';
import { COLLECTIONS, REGION } from '../config/constants';
import { writeAuditLog } from '../lib/audit';
import { assertAdmin } from '../lib/guards';
import { isPlainObject } from '../lib/validation';

/**
 * Grants or revokes administrator privileges for an existing account.
 *
 * Bootstrapping the first administrator cannot go through this callable, since
 * it already requires an administrator. Instead, create the `admins/{uid}`
 * document once from the Firebase console, which bypasses security rules, or
 * set a `role: 'admin'` custom claim directly. See `functions/README.md`.
 *
 * Both representations are written together so `isAdmin()` in the security
 * rules and `assertAdmin()` here never disagree about who is an administrator.
 */
export const setAdminClaim = onCall({ region: REGION }, async (request) => {
  const callerUid = await assertAdmin(request);

  if (!isPlainObject(request.data)) {
    throw new HttpsError('invalid-argument', 'A request body is required.');
  }

  const { uid, email, grant } = request.data as {
    uid?: unknown;
    email?: unknown;
    grant?: unknown;
  };

  if (typeof grant !== 'boolean') {
    throw new HttpsError('invalid-argument', '"grant" must be a boolean.');
  }

  let targetUid: string;
  if (typeof uid === 'string' && uid.length > 0) {
    targetUid = uid;
  } else if (typeof email === 'string' && email.length > 0) {
    const byEmail = await getAuth().getUserByEmail(email);
    targetUid = byEmail.uid;
  } else {
    throw new HttpsError(
      'invalid-argument',
      'Supply either "uid" or "email" to identify the account.',
    );
  }

  // Refusing self-revocation prevents the last administrator from locking the
  // project out of its own admin surface.
  if (!grant && targetUid === callerUid) {
    throw new HttpsError(
      'failed-precondition',
      'You cannot revoke your own administrator privileges.',
    );
  }

  const target = await getAuth().getUser(targetUid);
  const claims = { ...(target.customClaims ?? {}) };

  if (grant) {
    await getAuth().setCustomUserClaims(targetUid, {
      ...claims,
      role: 'admin',
    });
    await db.collection(COLLECTIONS.admins).doc(targetUid).set(
      {
        uid: targetUid,
        email: target.email ?? null,
        grantedBy: callerUid,
        grantedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } else {
    delete (claims as Record<string, unknown>).role;
    await getAuth().setCustomUserClaims(targetUid, claims);
    await db.collection(COLLECTIONS.admins).doc(targetUid).delete();
  }

  await writeAuditLog({
    actorId: callerUid,
    action: grant ? 'admin.granted' : 'admin.revoked',
    collection: COLLECTIONS.admins,
    documentId: targetUid,
    details: { email: target.email ?? null },
  });

  return { uid: targetUid, grant };
});

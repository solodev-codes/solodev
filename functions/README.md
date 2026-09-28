# Solodev Cloud Functions

Server-side backend for the Solodev portfolio. TypeScript, Node 22, second-gen
functions in `us-central1`.

## Commands

```bash
cd functions
npm install
npm run build          # tsc -> lib/
npm run serve          # build + start the Functions emulator
npm run logs           # tail deployed logs
```

Deploy everything the backend needs:

```bash
firebase deploy --only firestore:rules,storage,firestore:indexes,functions
```

## Function inventory

| Export | Trigger | Purpose |
| --- | --- | --- |
| `setAdminClaim` | callable | Grant or revoke administrator access |
| `onAdminDirectoryChanged` | Firestore `admins/{id}` | Audit out-of-band privilege changes |
| `onMessageCreated` | Firestore `messages/{id}` | Normalise an enquiry, notify admins |
| `onMessageStatusChanged` | Firestore `messages/{id}` | Validate status, stamp transition, audit |
| `onMessageDeleted` | Firestore `messages/{id}` | Audit the deletion without retaining the body |
| `onObjectFinalized` | Storage `portfolio/**` | Enforce upload policy, index into `media` |
| `onMediaDeleted` | Firestore `media/{id}` | Delete the backing Storage object |
| `registerDevice` | callable | Register a push token for the caller |
| `pruneStaleTokens` | daily schedule | Drop device registrations idle over 180 days |
| `refreshPortfolioStats` | callable | Recompute the dashboard summary on demand |
| `dailyStatsRollup` | daily schedule | Recompute the dashboard summary |
| `pruneAuditLogs` | daily schedule | Trim audit history past the retention window |

## Bootstrapping the first administrator

There is a chicken-and-egg problem: `setAdminClaim` requires an administrator
to call it. There is deliberately no public sign-up flow, so the first account
is created out of band.

1. Create the user in **Firebase console → Authentication → Users**.
2. Create the document **Firebase console → Firestore → `admins`** with document
   ID equal to that user's **UID**, containing e.g. `{"uid": "<UID>"}`.

The console bypasses security rules, which is exactly what is needed here, and
`onAdminDirectoryChanged` will write an audit record for the change. Once
signed in, use `setAdminClaim` to manage every subsequent account.

Both representations — the `role: 'admin'` custom claim and the `admins/{uid}`
document — are written together, so `isAdmin()` in `firestore.rules` and
`assertAdmin()` in `src/lib/guards.ts` can never disagree about who is an
administrator.

## Division of responsibility

The security rules are the authority on authorisation. A function is only
reached *after* the rules have already permitted the write, so functions here
normalise, enrich, notify, and audit — they do not re-implement permission
checks for ordinary content. Where a callable is publicly invocable
(`setAdminClaim`, `registerDevice`, `refreshPortfolioStats`), `assertAdmin()`
runs first.

## Deliberate omissions

- **No thumbnail generation.** Server-side image resizing would need `sharp`,
  which is a native dependency and a frequent source of platform-specific
  build failures. `storage.rules` also denies clients access to
  `thumbnails/**`, and the Flutter client never requests a thumbnail URL, so
  adding it would introduce a build risk for no functional gain. Revisit only
  if the media library displays small previews.
- **No email forwarding.** Requires a third-party provider and API key; the
  dashboard inbox is the source of truth until a provider is chosen.
- **No tests.** Cancelled by project decision.

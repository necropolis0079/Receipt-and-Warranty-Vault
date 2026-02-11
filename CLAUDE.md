# Receipt & Warranty Vault — Project Memory

## STATUS: Implementation Phase — Offline-Only Simplification
**Last Updated**: 2026-02-11
**Phase**: Ideation → Documentation → Implementation → **SIMPLIFIED TO OFFLINE-ONLY**

---

## APP IDENTITY
- **Display name**: Warranty Vault
- **Android package**: `com.cronos.warrantyvault`
- **iOS bundle ID**: `io.cronos.warrantyvault.app`
- **Flutter project dir**: `app/`

## PROJECT OVERVIEW
A mobile app that helps people capture, organize, and retrieve receipts and warranty information.
- **Core promise**: One place for every receipt and warranty
- **Hero feature**: Warranty expiry tracking + reminders
- **Languages**: English + Greek (v1)
- **Target**: Global users, first 5 testers (team)

---

## ALL DECISIONS MADE (Do NOT change without user approval)

### Product Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Hero feature | Warranty expiry tracking + reminders | Underserved market, strong differentiator |
| OCR extraction | Must-have, LLM-powered | Without it, app is just a photo album |
| Offline support | Full offline functionality | Users need capture in stores with no signal |
| On-device OCR fallback | ML Kit (Latin) + Tesseract (Greek) hybrid | ML Kit doesn't support Greek script — Tesseract fills the gap |
| Digital receipts v1 | Import from gallery/files (images + PDF) | Email forwarding deferred to v2 |
| Smart search v1 | Keyword search + filters ONLY | LLM natural language search deferred to v1.5 |
| Auto-archiving | Configurable, user-approved | User controls when old receipts get archived |
| Categories | User can create custom categories from v1 | 10 defaults provided as suggestions |
| "Marked as returned" | YES, included in v1 | Simple status toggle, low dev cost |
| Soft delete | 30-day recovery, hard wipe on account deletion | GDPR compliant |
| Bulk import | Scan gallery for receipt-like images at onboarding | Solves cold-start problem |
| Home screen widget | Quick capture, included in v1 | Critical for habit formation |
| Stats display | "X receipts · €Y in active warranties" on home | Reinforces value |
| Biometric/PIN lock | Optional but prompted at onboarding | Not forced |
| Storage mode | **Device-Only** (cloud removed 2026-02-11) | Simplified to offline-only for v1 |
| Revenue model | TBD before public launch | Not blocking v1 development |
| Shared vault | Deferred to v2 | Multi-user sync too complex for v1 |

### Technical Decisions (ACTIVE)
| Decision | Choice | Research Finding |
|----------|--------|-----------------|
| Framework | Flutter + Dart | Best offline-first + ML Kit support |
| Platforms | iOS + Android | Both via Flutter single codebase |
| Local database | **Drift** (SQLite + SQLCipher AES-256 encryption) | Isar abandoned; Drift has encryption, FTS5, migrations, actively maintained |
| Image compression | **JPEG 85%** quality, strip GPS EXIF | 1-2MB per receipt, preserves OCR readability |
| On-device OCR | **ML Kit** (Latin/numbers) + **Tesseract** (Greek) hybrid | ML Kit doesn't support Greek script |
| Auth | **MockAuthRepository** (offline mock) | Cloud auth (Cognito/Amplify) removed; to be revisited later |
| App lock | **local_auth** package (biometric/PIN) | Works offline |
| Push notifications | **Local notifications** (warranty reminders) | Server push (SNS) removed |
| Encryption | AES-256 local (Drift+SQLCipher) | Full encryption at rest |

### Technical Decisions (REMOVED — cloud/sync stripped 2026-02-11)
AWS infrastructure destroyed. The following were removed from the codebase:
- Backend (API Gateway + Lambda), DynamoDB, S3, CloudFront, KMS
- Cognito + Amplify Flutter Gen 2 auth
- Sync engine (custom delta sync, conflict resolver, image sync, background sync)
- API client (Dio + interceptors), remote data sources
- ConnectivityService, WorkManager, SNS server push
- Dependencies: dio, amplify_flutter, amplify_auth_cognito, workmanager, connectivity_plus, internet_connection_checker_plus

### Compliance Decisions
| Decision | Choice |
|----------|--------|
| Standard | GDPR applied globally (strictest = covers CCPA, LGPD, etc.) |
| User rights | Full export, full deletion |
| Privacy policy | Required before public launch |
| Data storage | Device-only (no cloud) |

---

## RESEARCH COMPLETED (2026-02-08)
- [x] Drift vs Isar → **Drift** (encryption, maintained, SQL power, FTS5)
- [x] Google ML Kit → Does NOT support Greek! **Hybrid ML Kit + Tesseract** recommended
- [x] ~~DynamoDB schema~~ (removed — no cloud)
- [x] ~~Sync architecture~~ (removed — no cloud)
- [x] ~~S3/Cognito/SNS~~ (removed — no cloud)

---

## COST ESTIMATE (Monthly)

**$0/month** — fully offline, no AWS resources. All cloud infrastructure destroyed 2026-02-11.

---

## FEATURE PRIORITY (LOCKED)

### v1.0 — Core (5 testers) — OFFLINE-ONLY
1. Photo capture + import from files
2. On-device OCR (ML Kit + Tesseract hybrid) — instant basic extraction
3. Manual edit/correct all fields
4. Warranty tracking with expiry countdown
5. Push notification reminders (local only, configurable timing)
6. Keyword search + FTS5 full-text search + filters
7. Offline Drift DB (device-only storage)
8. Mock auth (offline — to be revisited for real auth later)
9. Biometric/PIN lock (optional, via local_auth)
10. Export/share single receipt
11. Custom categories (10 defaults + user-created)
12. "Mark as returned" status
13. Soft delete with 30-day recovery (local Drift TTL)
14. Bulk import from photo gallery (onboarding)
15. Home screen widget (quick capture)
16. Stats display on home screen
17. English + Greek localization
18. Batch export by date range

### v1.5 — Polish (before public launch)
- Cloud LLM refinement (Bedrock Haiku 4.5) — polishes OCR extraction when online
- LLM smart search (natural language)
- Spending insights dashboard
- Additional languages
- Auto-archiving with user approval
- Real auth (Cognito or alternative) — replace MockAuthRepository

### v2.0 — Growth
- Cloud sync + backup (re-introduce if needed)
- Email forwarding capture
- Household shared vault
- Return window tracking
- Revenue model implementation

---

## DATA MODEL — Local Drift Database

All data stored locally in Drift (SQLite + SQLCipher AES-256 encryption).
DynamoDB schema was removed with cloud infrastructure (2026-02-11).
The local schema is defined in `app/lib/core/database/tables/`.
Note: `sync_queue_table` still exists in schema to avoid DB migration but is unused.

---

## FLUTTER PACKAGE STACK (CURRENT — post-simplification)
| Package | Purpose |
|---------|---------|
| drift + sqlcipher_flutter_libs | Local DB with AES-256 encryption |
| google_mlkit_text_recognition | On-device OCR (Latin/numbers) |
| flutter_tesseract_ocr | On-device OCR (Greek text) |
| local_auth | Biometric/PIN app lock |
| flutter_local_notifications | Offline warranty reminders |
| image / flutter_image_compress | Image preprocessing + compression |
| image_cropper | User-guided crop/rotate |
| image_picker | Camera + gallery access |
| uuid | Client-side ID generation |
| flutter_secure_storage | Secure token/key storage |

**Removed** (2026-02-11): dio, amplify_flutter, amplify_auth_cognito, workmanager, connectivity_plus, internet_connection_checker_plus

---

## DESIGN DIRECTION (APPROVED)
- **Palette**: Warm cream (#FAF7F2), forest green (#2D5A3D), amber (#D4920B), red (#C0392B)
- **Typography**: DM Serif Display (headings) + Plus Jakarta Sans (body)
- **Style**: Card-based layout, subtle shadows, clean modern aesthetic
- **Navigation**: Bottom tab bar (Vault, Expiring, +Add, Search, Settings)
- **Mockup file**: D:\Receipt and Warranty Vault\mockup\index.html

---

## DOCUMENTATION FILES
```
D:\Receipt and Warranty Vault\
├── CLAUDE.md                         ← This file (project memory)
├── mockup\
│   └── index.html                    ← Visual mockup (approved)
├── app\                              ← Flutter project
├── .github\workflows\ci.yml          ← GitHub Actions CI
├── docs\
│   ├── 01-project-overview.md
│   ├── 02-user-personas.md
│   ├── 03-feature-specification.md
│   ├── 04-user-flows.md
│   ├── 05-technical-architecture.md  ← (partially outdated — cloud refs)
│   ├── 06-data-model.md              ← (partially outdated — DynamoDB refs)
│   ├── 07-api-design.md              ← (outdated — API removed)
│   ├── 08-aws-infrastructure.md      ← (outdated — AWS destroyed)
│   ├── 09-security-compliance.md
│   ├── 10-offline-sync-architecture.md ← (outdated — sync removed)
│   ├── 11-llm-integration.md         ← (deferred to v1.5)
│   ├── 12-deployment-strategy.md
│   ├── 13-testing-strategy.md
│   ├── 14-roadmap.md
│   ├── devlog.md                     ← Development journal
│   └── regression-checklist.md       ← Regression checklist
├── .claude/
│   ├── settings.local.json         ← Hooks + compaction config
│   ├── SESSION_STATE.md             ← Current session state (read after compaction)
│   ├── hooks/
│   │   ├── pre-compact-save.sh      ← Auto-saves before compaction
│   │   ├── post-compact-context.sh  ← Re-injects context after compaction
│   │   └── compaction.log           ← Compaction event log
│   └── agents/
│       ├── flutter-ui.md            ← UI/Widget specialist
│       ├── flutter-bloc.md          ← State management specialist
│       ├── drift-db.md              ← Local database specialist
│       └── test-writer.md           ← Testing specialist
```

**Note**: `aws-lambda.md`, `aws-cdk.md`, `sync-engine.md` agents are no longer relevant (cloud removed). Docs 07, 08, 10 are outdated but kept for historical reference.

---

## INFRASTRUCTURE & ACCOUNTS

| Resource | Value |
|----------|-------|
| GitHub repo | `https://github.com/necropolis0079/Receipt-and-Warranty-Vault.git` |
| AWS | **DESTROYED** (2026-02-11) — all resources torn down, no active infra |
| AWS account | `882868333122` (inactive, budget alert still active) |

---

## IMPLEMENTATION WORKFLOW (AGREED)

### Approach: Option C — Parallel Agents
- Multiple agents work simultaneously on isolated features
- Each agent works in separate directories to avoid conflicts
- Integration + full test suite runs after each parallel batch
- All work is documented in devlog.md

### Git Strategy
- **`main`** = stable, always builds
- **Feature branches** = `feature/<name>`, merged after tests pass
- Push to GitHub after each merge

### Build Order (Sprint 1-2)
1. Flutter project creation + clean architecture structure
2. Core dependencies in pubspec.yaml
3. GitHub Actions CI pipeline
4. Initial commit + push
5. **Parallel batch**: Theme + Drift DB + Localization + UI Shell
6. Integration + full test suite + regression check

---

## DOCUMENTATION STRATEGY (5 LAYERS)

| Layer | File | Purpose | Updated When |
|-------|------|---------|-------------|
| 1 | `docs/devlog.md` | Chronological dev journal — every decision, change, issue | Every action |
| 2 | `.claude/SESSION_STATE.md` | Quick recovery snapshot | Before compaction, at milestones |
| 3 | `CLAUDE.md` | Source of truth for permanent decisions | When decisions change |
| 4 | Git commits | What + why for each change | Every commit |
| 5 | Architecture READMEs | Structure explanations in key dirs | When dirs are created |

**Rule**: Nothing happens without it being logged in devlog.md.

---

## ANTI-REGRESSION STRATEGY (MANDATORY)

### Rules
1. **Every feature gets tests at build time** — not later
2. **Run ALL tests before every merge** — not just new tests
3. **GitHub Actions CI** — automated on every push (analyze + test + build)
4. **Regression checklist** (`docs/regression-checklist.md`) — grows with each feature
5. **Feature isolation for agents** — each agent works in separate dirs
6. **Golden rule**: Never move to next step until current tests pass AND regression checklist is green
7. **If a regression is found**: Stop → fix it → add test for it → log in devlog → then continue

---

## COMPACTION PROTECTION PROTOCOL (MANDATORY)

### Rules I MUST Follow

1. **After ANY compaction**: Read `CLAUDE.md` + `.claude/SESSION_STATE.md` before doing anything
2. **Before starting complex work**: Update `SESSION_STATE.md` with what I'm about to do
3. **After completing milestones**: Update `SESSION_STATE.md` with what was done
4. **When context reaches ~60%**: Proactively update `SESSION_STATE.md` with full current state
5. **Before any `/compact`**: Update `SESSION_STATE.md` first

### What Gets Saved Automatically
- **PreCompact hook**: Auto-commits all files to git (if repo initialized)
- **SessionStart hook**: After compaction, outputs reminder to read SESSION_STATE.md
- **CLAUDE.md**: Always reloaded — contains all project decisions
- **SESSION_STATE.md**: Contains current session state, active tasks, next steps

### Configuration
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70` — compaction triggers at 70% (not default 95%)
- This gives headroom for me to save state before compaction
- PreCompact hook runs before compaction starts
- SessionStart (compact matcher) runs after compaction completes

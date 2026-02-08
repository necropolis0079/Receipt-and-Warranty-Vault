# Receipt & Warranty Vault — Project Memory

## STATUS: Implementation Phase — Sprint 1-2 (Foundation)
**Last Updated**: 2026-02-08
**Phase**: Ideation → Documentation COMPLETE → **Implementation STARTED**

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
| Storage mode | User choice: Cloud+Device OR Device-Only | GDPR user autonomy |
| Revenue model | TBD before public launch | Not blocking v1 development |
| Shared vault | Deferred to v2 | Multi-user sync too complex for v1 |

### Technical Decisions (ALL RESEARCHED AND FINALIZED)
| Decision | Choice | Research Finding |
|----------|--------|-----------------|
| Framework | Flutter + Dart | Best offline-first + ML Kit support |
| Platforms | iOS + Android | Both via Flutter single codebase |
| Backend | AWS (API Gateway + Lambda) | Serverless, pay-per-use |
| Cloud database | DynamoDB (single-table, 6 GSIs, on-demand) | <$0.01/mo at 5 users, ~$0.16/mo at 1K users |
| Local database | **Drift** (SQLite + SQLCipher AES-256 encryption) | Isar abandoned; Drift has encryption, FTS5, migrations, actively maintained |
| Image storage | S3 with **SSE-KMS** (CMK + Bucket Keys) | GDPR crypto-shredding, CloudTrail audit, ~$1/mo |
| Image delivery | **CloudFront** with OAC | Free tier 1TB/month, faster than S3 direct |
| Image compression | **JPEG 85%** quality, strip GPS EXIF | 1-2MB per receipt, preserves OCR readability |
| Thumbnails | **Lambda trigger** on S3 upload, 200x300px JPEG 70% | ~$0.08/month for 50K thumbnails |
| Storage tiering | **S3 Intelligent-Tiering** for images, Standard for thumbnails | Auto-optimizes based on access patterns |
| LLM | **Bedrock Claude Haiku 4.5** (primary), Sonnet 4.5 (fallback) | ~$0.004/receipt, sub-1s latency, skip Textract |
| On-device OCR | **ML Kit** (Latin/numbers) + **Tesseract** (Greek) hybrid | ML Kit doesn't support Greek script |
| Auth | **Cognito User Pool** (Lite tier) + **Amplify Flutter Gen 2** | $0/month up to 10K MAUs |
| Social login | Google Sign-In + Apple Sign-In | Apple mandatory if offering Google on iOS |
| App lock | **local_auth** package (biometric/PIN) | Separate from Cognito, works offline |
| Push notifications | **Local notifications** (warranty reminders) + **SNS** (server events) | Hybrid: offline reminders + server push |
| Notification scheduling | **EventBridge** + Lambda (daily warranty check, weekly summary) | Serverless cron jobs |
| Sync engine | **Custom** (NOT AppSync) — timestamp + version + field-level merge | AppSync DataStore is Gen 1/maintenance mode |
| Sync strategy | Delta sync primary, full reconciliation every 7 days | Efficient + safety net |
| Conflict resolution | **Field-level merge with ownership tiers** | LLM fields=server wins, user fields=client wins |
| Background sync | Silent push (primary) + WorkManager (backup) + on-resume | Best cross-platform reliability |
| Region | eu-west-1 (single region, GDPR for all) | Multi-region deferred |
| Encryption | AES-256 everywhere (Drift+SQLCipher local, SSE-KMS S3, DynamoDB default) | Full encryption at rest |
| Pre-signed URLs | 10-minute expiry, content-type/size restricted | Generated server-side only |
| S3 soft delete | S3 Versioning + NoncurrentVersionExpiration 30 days | Native, atomic, no copy+delete race |
| Token config | Access/ID: 1 hour, Refresh: 30-90 days | Amplify handles refresh transparently |

### Compliance Decisions
| Decision | Choice |
|----------|--------|
| Standard | GDPR applied globally (strictest = covers CCPA, LGPD, etc.) |
| Data residency | eu-west-1 for now, multi-region later |
| Bedrock data policy | No storage, no training by AWS (confirmed) |
| User rights | Full export, full deletion, storage mode choice |
| Privacy policy | Required before public launch |
| User deletion | Lambda cascade: Cognito → DynamoDB → S3 (hard wipe) |
| Bucket security | Block all public access, enforce TLS, enforce KMS, restrict IAM, logging enabled |

---

## RESEARCH COMPLETED (2026-02-08)
- [x] Drift vs Isar → **Drift** (encryption, maintained, SQL power, FTS5)
- [x] DynamoDB schema → **Single table, 6 GSIs**, all 13 access patterns covered
- [x] Bedrock Claude vision → **Haiku 4.5** primary ($0.004/receipt), Sonnet fallback
- [x] Google ML Kit → Does NOT support Greek! **Hybrid ML Kit + Tesseract** recommended
- [x] Sync architecture → **Custom engine**, timestamp+version, field-level merge, skip AppSync
- [x] S3 encryption → **SSE-KMS** with CMK + Bucket Keys, CloudFront, Intelligent-Tiering
- [x] Push notifications → **Local notifications** (offline reminders) + **SNS** (server events)
- [x] Cognito social login → **Amplify Flutter Gen 2**, User Pool only, Lite tier ($0)

---

## COST ESTIMATE (Monthly)

### At 5 Users (Testing)
| Service | Cost |
|---------|------|
| DynamoDB | <$0.01 |
| S3 storage | ~$0.50 |
| Bedrock (100 receipts) | ~$0.40 |
| KMS | ~$1.00 |
| Cognito | $0.00 |
| Lambda/API Gateway | $0.00 (free tier) |
| SNS/FCM | $0.00 |
| CloudFront | $0.00 (free tier) |
| **Total** | **~$2/month** |

### At 1,000 Users
| Service | Cost |
|---------|------|
| DynamoDB | ~$0.16 |
| S3 storage + transfer | ~$5 |
| Bedrock (20K receipts) | ~$80 |
| KMS | ~$1 |
| Cognito | $0.00 |
| Lambda/API Gateway | ~$2 |
| SNS | <$0.15 |
| CloudFront | $0.00 (free tier) |
| **Total** | **~$88/month** |

---

## FEATURE PRIORITY (LOCKED)

### v1.0 — Core (5 testers)
1. Photo capture + import from files
2. On-device OCR (ML Kit + Tesseract hybrid) — instant basic extraction
3. Cloud LLM refinement (Bedrock Haiku 4.5) — polishes extraction when online
4. Manual edit/correct all fields
5. Warranty tracking with expiry countdown
6. Push notification reminders (local + server, configurable timing)
7. Keyword search + FTS5 full-text search + filters
8. Offline-first Drift DB with custom cloud sync engine
9. Storage mode choice (cloud+device / device-only)
10. Cognito auth (email + Google/Apple via Amplify Flutter Gen 2)
11. Biometric/PIN lock (optional, via local_auth)
12. Export/share single receipt
13. Custom categories (10 defaults + user-created)
14. "Mark as returned" status
15. Soft delete with 30-day recovery (S3 Versioning + DynamoDB TTL)
16. Bulk import from photo gallery (onboarding)
17. Home screen widget (quick capture)
18. Stats display on home screen
19. English + Greek localization
20. Batch export by date range

### v1.5 — Polish (before public launch)
- LLM smart search (natural language via Bedrock)
- Spending insights dashboard
- Additional languages
- Auto-archiving with user approval

### v2.0 — Growth
- Email forwarding capture
- Household shared vault
- Return window tracking
- Multi-region deployment
- Revenue model implementation

---

## DATA MODEL — DynamoDB Schema (FINALIZED)

### Table: ReceiptVault (Single Table)
- **PK**: `USER#<userId>` (String)
- **SK**: `RECEIPT#<receiptId>` or `META#CATEGORIES` (String)

### GSIs (6 total)
| GSI | Name | PK | SK | Purpose |
|-----|------|----|----|---------|
| GSI-1 | ByUserDate | USER#userId | purchaseDate | All receipts by date, date range |
| GSI-2 | ByUserCategory | USER#userId | CAT#category | Receipts by category |
| GSI-3 | ByUserStore | USER#userId | STORE#storeName | Receipts by store |
| GSI-4 | ByWarrantyExpiry | USER#userId#ACTIVE | warrantyExpiryDate | Active warranties, expiring soon (sparse) |
| GSI-5 | ByUserStatus | USER#userId | STATUS#status#purchaseDate | Receipts by status |
| GSI-6 | ByUpdatedAt | USER#userId | updatedAt | Delta sync queries (KEYS_ONLY) |

### Conflict Resolution Tiers
- **Tier 1 (Server/LLM wins)**: extracted_merchant_name, extracted_date, extracted_total, ocr_raw_text, llm_confidence
- **Tier 2 (Client/User wins)**: user_notes, user_tags, is_favorite
- **Tier 3 (Client override precedence)**: display_name, category, warranty_months — tracked via user_edited_fields array

---

## FLUTTER PACKAGE STACK (FINALIZED)
| Package | Purpose |
|---------|---------|
| drift + sqlcipher_flutter_libs | Local DB with AES-256 encryption |
| google_mlkit_text_recognition | On-device OCR (Latin/numbers) |
| flutter_tesseract_ocr | On-device OCR (Greek text) |
| amplify_auth_cognito (Gen 2) | Cognito authentication |
| local_auth | Biometric/PIN app lock |
| firebase_messaging | Push notification reception (FCM) |
| flutter_local_notifications | Offline warranty reminders |
| connectivity_plus | Network type detection |
| internet_connection_checker_plus | Actual internet verification |
| workmanager | Background sync tasks |
| dio | HTTP client with retries/interceptors |
| image / flutter_image_compress | Image preprocessing + compression |
| image_cropper | User-guided crop/rotate |
| image_picker | Camera + gallery access |
| uuid | Client-side ID generation |
| flutter_secure_storage | Secure token/key storage |

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
├── Credentials\                      ← AWS keys (GITIGNORED)
├── mockup\
│   └── index.html                    ← Visual mockup (approved)
├── app\                              ← Flutter project (created Sprint 1)
├── .github\workflows\ci.yml          ← GitHub Actions CI
├── docs\
│   ├── 01-project-overview.md
│   ├── 02-user-personas.md
│   ├── 03-feature-specification.md
│   ├── 04-user-flows.md
│   ├── 05-technical-architecture.md
│   ├── 06-data-model.md
│   ├── 07-api-design.md
│   ├── 08-aws-infrastructure.md
│   ├── 09-security-compliance.md
│   ├── 10-offline-sync-architecture.md
│   ├── 11-llm-integration.md
│   ├── 12-deployment-strategy.md
│   ├── 13-testing-strategy.md
│   ├── 14-roadmap.md
│   ├── devlog.md                     ← Development journal (NEW)
│   └── regression-checklist.md       ← Regression checklist (NEW)
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
│       ├── aws-lambda.md            ← Backend Lambda specialist
│       ├── aws-cdk.md               ← Infrastructure specialist
│       ├── sync-engine.md           ← Sync engine specialist
│       └── test-writer.md           ← Testing specialist
```

---

## INFRASTRUCTURE & ACCOUNTS

| Resource | Value |
|----------|-------|
| AWS profile | `warrantyvault` |
| AWS account | `882868333122` |
| AWS user | `awsadmin` |
| AWS region | `eu-west-1` |
| GitHub repo | `https://github.com/necropolis0079/Receipt-and-Warranty-Vault.git` |
| Credentials | `Credentials/` folder (GITIGNORED — never commit) |

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

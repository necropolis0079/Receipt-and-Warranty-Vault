# Development Log — Warranty Vault

> **Chronological journal of every decision, change, and issue during development.**
> **This is the master record. If it's not here, it didn't happen.**

---

## 2026-02-08 — Pre-Implementation Setup

### Session: Project Configuration

**What was done:**
- Created GitHub repo: `necropolis0079/Receipt-and-Warranty-Vault`
- Connected local git repo to GitHub remote (origin)
- Configured AWS CLI profile `warrantyvault` (account 882868333122, user awsadmin, eu-west-1)
- Added `Credentials/` to `.gitignore` to prevent secret leakage
- App identity finalized:
  - Display name: **Warranty Vault**
  - Android package: `com.cronos.warrantyvault`
  - iOS bundle ID: `io.cronos.warrantyvault.app`

**Decisions made:**
- Implementation approach: **Option C** (parallel agents working on isolated features)
- Git strategy: `main` branch = stable, feature branches for each piece of work
- Documentation strategy: 5 layers (devlog, SESSION_STATE, CLAUDE.md, git commits, architecture READMEs)
- Anti-regression strategy: tests per feature, full test suite before merge, CI pipeline, regression checklist, feature isolation for agents

**Files created/modified:**
- `.gitignore` — added `Credentials/` to secrets section
- `CLAUDE.md` — added App Identity, Infrastructure, Workflow, Documentation Strategy, Anti-Regression Strategy sections
- `docs/devlog.md` — this file (created)
- `docs/regression-checklist.md` — created

---

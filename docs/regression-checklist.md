# Regression Checklist — Warranty Vault

> **This checklist grows with each feature. Before any merge to `main`, ALL items must pass.**
> **If a new feature breaks an old check, the merge is BLOCKED until fixed.**

---

## How to Use
1. Run `flutter analyze` — must have zero errors
2. Run `flutter test` — all tests must pass
3. Walk through each section below — all items must be verified
4. If anything fails: fix it, add a specific test for the failure, then re-check

---

## Build & Analyze
- [ ] `flutter analyze` — zero errors, zero warnings
- [ ] `flutter test` — all tests pass
- [ ] `flutter build apk --debug` — builds successfully
- [ ] App launches without crash on Android emulator or device

---

## Navigation (Sprint 1-2)
> *Added when: UI shell is built*

*(Items will be added here as navigation is implemented)*

## Theme (Sprint 1-2)
> *Added when: theme system is built*

*(Items will be added here as theme is implemented)*

## Database (Sprint 1-2)
> *Added when: Drift DB is built*

*(Items will be added here as database is implemented)*

## Localization (Sprint 1-2)
> *Added when: l10n is built*

*(Items will be added here as localization is implemented)*

## Auth (Sprint 1-2)
> *Added when: Cognito auth is built*

*(Items will be added here as auth is implemented)*

---

*Last updated: 2026-02-08*

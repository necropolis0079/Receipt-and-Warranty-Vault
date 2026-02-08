# 01 -- Project Overview

**Document**: Project Overview
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Solution Overview](#solution-overview)
4. [Key Differentiators](#key-differentiators)
5. [Target Audience](#target-audience)
6. [Platform Support](#platform-support)
7. [Language Support](#language-support)
8. [Success Metrics for v1](#success-metrics-for-v1)
9. [High-Level Tech Stack](#high-level-tech-stack)
10. [Revenue Model](#revenue-model)
11. [Design Direction](#design-direction)

---

## Executive Summary

**Receipt & Warranty Vault** is a mobile application that serves as the single, trusted place for every receipt and warranty a person accumulates throughout their daily life. The app transforms the chaotic experience of managing paper receipts, digital invoices, and warranty documents into a clean, searchable, and intelligent personal archive.

The **core promise** is simple: one place for every receipt and warranty -- captured in seconds, organized automatically, and always available when you need it.

The **hero feature** that sets Receipt & Warranty Vault apart from generic document scanners is **warranty expiry tracking with smart reminders**. The app does not merely store warranty information; it actively monitors expiration dates, counts down remaining coverage, and notifies users before their protection lapses. This turns a passive archive into an active financial guardian that saves users real money by ensuring they never miss a warranty claim window.

The app is built for everyday consumers who buy electronics, furniture, appliances, and household goods, and who need a frictionless way to prove purchases, track warranty coverage, and retrieve receipt details at a moment's notice -- whether standing at a returns counter with no cell signal or filing expenses at home.

---

## Problem Statement

Managing receipts and warranties is a universally broken experience. The pain is real, recurring, and costly.

### Receipts Get Lost

Paper receipts fade, crumple, and disappear into junk drawers. Digital receipts scatter across email inboxes, messaging apps, and download folders. When a user needs to prove a purchase -- for a return, an insurance claim, or a tax filing -- the receipt is almost never where they expect it to be. Studies consistently show that consumers lose or discard receipts within days of purchase, often before the return window has even closed.

### Warranties Expire Unnoticed

Most consumers have no system for tracking warranty coverage. A laptop purchased with a two-year warranty sits in a closet, and when it fails at month 23 the owner has no idea the warranty is still active. Extended warranties purchased at additional cost go entirely unused because the expiry date was never recorded anywhere retrievable. The money spent on warranty protection is effectively wasted.

### No Single Source of Truth

Today's consumer interacts with dozens of retailers across physical stores and online platforms. Receipts arrive as thermal paper slips, emailed PDFs, in-app confirmations, and SMS messages. There is no unified system that aggregates all of these into a single searchable archive. Users resort to photographing receipts with their phone camera and leaving them in the camera roll -- mixed in with thousands of personal photos, unsearchable, and unorganized.

### The Greek-Language Gap

For Greek-speaking users, the problem is compounded by a lack of OCR support. Most mainstream OCR solutions are optimized for Latin-script languages. Greek receipts from local retailers, supermarkets, and service providers are effectively invisible to standard scanning tools, forcing manual data entry or abandonment.

### The Offline Reality

Receipt capture most often happens in physical stores -- precisely the environments where network connectivity is unreliable or unavailable. Underground parking garages, large warehouse stores, and rural retailers all present connectivity dead zones. Any solution that requires an internet connection for basic capture fails at the moment of highest need.

---

## Solution Overview

Receipt & Warranty Vault addresses every dimension of the problem through a carefully designed mobile application with the following core capabilities.

### Smart Capture

Users capture receipts through the device camera or import existing images and PDFs from their gallery and file system. The app applies image preprocessing -- auto-crop, rotation correction, and quality optimization -- to ensure the best possible input for text extraction.

### Hybrid OCR with Intelligent Extraction

A two-tier OCR system provides both speed and accuracy. On-device OCR using Google ML Kit (for Latin script and numbers) and Tesseract (for Greek script) delivers instant basic extraction without any network dependency. When connectivity is available, the extracted data is refined through cloud-based LLM processing (AWS Bedrock with Claude Haiku 4.5) that intelligently parses merchant names, dates, line items, totals, and warranty information with high accuracy. This is not simple character recognition -- it is contextual understanding of receipt structure and content.

### Warranty Tracking and Reminders

The hero feature. When warranty information is detected or manually entered, the app creates an active countdown. Users see at a glance how many days remain on each warranty. Configurable push notifications alert users at meaningful intervals before expiry -- for example, 30 days, 7 days, and 1 day before a warranty lapses. Both local notifications (which work offline) and server-pushed notifications ensure reminders are never missed.

### Offline-First Architecture

The app is built from the ground up to function without an internet connection. All data is stored locally in an encrypted SQLite database (Drift with SQLCipher AES-256 encryption). Users can capture, browse, search, and edit their entire receipt vault with zero connectivity. When a connection becomes available, a custom sync engine reconciles local and cloud data using timestamp-based versioning with field-level conflict resolution.

### Organized Vault

Receipts are organized through a combination of automatic categorization (detected from merchant and item data), user-created custom categories, and a set of 10 default category suggestions. Users can filter by store, category, date range, and status. Full-text search powered by FTS5 lets users find receipts by any keyword -- a product name, a store, a price, or a note they added.

### Privacy and User Control

Users choose their storage mode: cloud-plus-device (for sync and backup) or device-only (for maximum privacy). GDPR compliance is applied globally regardless of user location. Users can export their data, delete their account (triggering a full cascade wipe across all services), and control archiving behavior.

---

## Key Differentiators

### 1. Warranty Hero Feature

No mainstream receipt app treats warranty tracking as a first-class feature. Most are document scanners that stop at capture. Receipt & Warranty Vault makes warranty expiry a living, breathing part of the interface -- with countdowns on the home screen, dedicated "Expiring" tabs, and smart notifications. This transforms the app from a passive archive into an active money-saving tool.

### 2. Hybrid OCR with Greek Language Support

The combination of Google ML Kit and Tesseract OCR in a hybrid pipeline is purpose-built to handle the reality of multilingual receipts. Greek-speaking users -- a significant portion of the initial user base -- can capture receipts from local retailers like Sklavenitis, Plaisio, and IKEA Greece with the same accuracy as English-language receipts. This is a gap that no competing consumer receipt app fills.

### 3. Offline-First, Not Offline-Capable

Many apps claim offline support but degrade significantly without connectivity. Receipt & Warranty Vault is architecturally offline-first: the local Drift database is the primary data store, not a cache. Capture, search, editing, and browsing all work identically whether the device is online or in airplane mode. Cloud sync is an enhancement, not a dependency.

### 4. GDPR-First, Not GDPR-Compliant-Later

Privacy is not bolted on as an afterthought. The strictest global privacy standard (GDPR) is applied to all users from day one, regardless of their geographic location. This means encrypted storage at every layer (device, transit, cloud), user-controlled data residency, full data export, cryptographic deletion via KMS key destruction, and zero LLM training on user data (confirmed by AWS Bedrock policy). Users who want no cloud involvement at all can operate in device-only mode.

### 5. LLM-Powered Intelligence, Not Just OCR

The cloud extraction layer is not a traditional OCR pipeline. It uses a large language model (Claude Haiku 4.5 via AWS Bedrock) that contextually understands receipt layouts, infers merchant names from partial text, normalizes dates across formats, and extracts warranty periods from natural-language phrases like "2 year manufacturer warranty included." This produces structured, usable data -- not just raw text.

### 6. Designed for the Capture Moment

The home screen widget for quick capture, the sub-20-second target for the full capture flow, and the bulk import feature at onboarding all reflect a design philosophy centered on reducing friction at the exact moment a receipt enters the user's life. The app meets users where they are: standing at a checkout counter, unpacking a delivery, or clearing out a wallet full of crumpled paper.

---

## Target Audience

### Global Consumer Base

The app is designed for any individual who makes purchases and wants a reliable way to track receipts and warranties. This is a universal need that crosses demographics, but the v1 release focuses deliberately on a narrow, high-value segment.

### Initial Testing Team (5 Testers)

The v1 release targets a hand-picked group of 5 testers who will use the app daily in real-world conditions. These testers are known to the development team, are a mix of iOS and Android users, and represent a range of receipt volumes and purchase patterns. Their feedback will directly shape the v1.5 polish release. The testers include both English-speaking and Greek-speaking users to validate the bilingual experience.

### Daily Consumers

The broader target audience is everyday consumers who:

- Purchase electronics, appliances, furniture, and household goods with warranty coverage.
- Shop at a mix of physical retail stores and online platforms.
- Need to produce receipts for returns, exchanges, insurance claims, or expense reports.
- Currently have no system (or an unreliable system) for receipt management.
- Use either iOS or Android as their primary mobile platform.
- Speak English, Greek, or both.

### Geographic Focus

While the app applies GDPR globally and is architecturally prepared for international use, the initial user base and testing are centered in Greece and English-speaking markets. The Greek language support, local retailer recognition, and EU data residency (eu-west-1) reflect this focus.

---

## Platform Support

| Platform | Support Level | Implementation |
|----------|--------------|----------------|
| **Android** | Full support | Flutter single codebase |
| **iOS** | Full support | Flutter single codebase |
| **Web** | Not planned for v1 | May be considered post-v2 |
| **Desktop** | Not planned | Mobile-first product |

Flutter provides a single Dart codebase that compiles to native ARM code on both iOS and Android. Platform-specific behaviors (camera APIs, biometric authentication, notification permissions, home screen widgets) are handled through Flutter's platform channel system and established plugin packages.

The minimum supported versions will be determined during implementation but will target coverage of at least 95% of active devices on each platform.

---

## Language Support

### v1 Languages

| Language | UI Localization | OCR Support | LLM Extraction |
|----------|----------------|-------------|-----------------|
| **English** | Full | ML Kit (on-device) | Bedrock Claude Haiku 4.5 |
| **Greek** | Full | Tesseract (on-device) | Bedrock Claude Haiku 4.5 |

The app's interface, all user-facing strings, error messages, onboarding flows, and notification text will be fully localized in both English and Greek for the v1 release. The user can switch languages in settings.

OCR handles both scripts through the hybrid ML Kit + Tesseract pipeline. The LLM extraction layer (Bedrock Claude Haiku 4.5) natively supports both English and Greek text comprehension.

### Future Languages (v1.5+)

Additional languages will be added based on user demand and market expansion. The localization architecture will be designed from v1 to support easy addition of new languages without architectural changes.

---

## Success Metrics for v1

The following metrics define a successful v1 release with the 5-person testing team.

### Capture Performance

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| End-to-end capture time | Under 20 seconds | From tapping "Add" to receipt saved with extracted data |
| On-device OCR accuracy | Greater than 85% | Percentage of fields (merchant, date, total) correctly extracted without cloud refinement |
| Cloud LLM extraction accuracy | Greater than 95% | Percentage of fields correctly extracted after Bedrock processing |
| Image compression quality | Preserve OCR readability | JPEG 85% quality, 1-2 MB per receipt |

### User Engagement

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| Active daily testers | 5 out of 5 | All testers using the app at least once per day during testing period |
| Receipts captured per tester per week | At least 5 | Average across testing period |
| Warranty reminders acted on | At least 1 per tester | Tester confirms reminder was useful |
| Sync reliability | 100% data consistency | No data loss or corruption across offline/online transitions |

### Technical Health

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| App crash rate | Below 1% | Crashes per session |
| Sync conflict resolution | Zero data loss | Field-level merge produces correct results |
| Offline functionality | Full feature parity | All core features work without connectivity |
| Cold start time | Under 3 seconds | App launch to interactive home screen |

---

## High-Level Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile Framework** | Flutter + Dart | Cross-platform iOS and Android from single codebase |
| **Local Database** | Drift (SQLite + SQLCipher AES-256) | Encrypted offline-first data storage with FTS5 full-text search |
| **Cloud Database** | DynamoDB (single-table, 6 GSIs, on-demand) | Serverless NoSQL for cloud persistence and sync |
| **Image Storage** | S3 with SSE-KMS encryption + Intelligent-Tiering | Encrypted receipt image storage with cost optimization |
| **Image Delivery** | CloudFront with OAC | Fast, cached image delivery via CDN |
| **Thumbnail Generation** | Lambda (S3 trigger) | Automatic 200x300px thumbnail creation on upload |
| **API Layer** | API Gateway + Lambda | Serverless REST API backend |
| **LLM Extraction** | AWS Bedrock (Claude Haiku 4.5 primary, Sonnet 4.5 fallback) | Intelligent receipt parsing and data extraction |
| **On-Device OCR** | Google ML Kit (Latin) + Tesseract (Greek) | Offline text recognition, hybrid pipeline |
| **Authentication** | Cognito User Pool (Lite tier) + Amplify Flutter Gen 2 | Email, Google Sign-In, Apple Sign-In |
| **App Lock** | local_auth package | Biometric and PIN protection, works offline |
| **Push Notifications** | Local notifications + SNS + FCM | Warranty reminders (offline) and server events (online) |
| **Scheduled Jobs** | EventBridge + Lambda | Daily warranty checks, weekly summary generation |
| **Sync Engine** | Custom (timestamp + version + field-level merge) | Delta sync primary, full reconciliation every 7 days |
| **Background Tasks** | WorkManager + silent push | Background sync on Android and iOS |
| **HTTP Client** | Dio | Network requests with retry logic and interceptors |
| **Secure Storage** | flutter_secure_storage | Encryption keys, auth tokens, sensitive configuration |
| **Region** | AWS eu-west-1 (Ireland) | GDPR-compliant data residency |

### Cost Profile

The architecture is designed for extreme cost efficiency at small scale with graceful scaling.

- **At 5 users (testing)**: Approximately $2 per month total AWS cost.
- **At 1,000 users**: Approximately $88 per month total AWS cost.
- **Cognito**: Free up to 10,000 monthly active users.
- **CloudFront**: Free tier covers 1 TB per month of transfer.
- **Lambda and API Gateway**: Covered by AWS free tier at testing scale.

---

## Revenue Model

**Status: To Be Determined**

The revenue model has been explicitly deferred as a decision that must be finalized before public launch but is not blocking v1 development or the testing phase. The focus for v1 is validating the product experience, OCR accuracy, sync reliability, and warranty tracking value with real users.

Potential revenue approaches under consideration (not yet decided) may include freemium tiers, subscription models, or one-time purchase options. This decision will be informed by tester feedback, usage patterns observed during the testing phase, and competitive market analysis.

The cost structure of the backend (approximately $0.004 per receipt for LLM processing, near-zero database costs at low scale) provides flexibility in pricing strategy. The architecture does not impose a minimum revenue threshold for sustainability at testing scale.

---

## Design Direction

The visual design of Receipt & Warranty Vault has been approved through a mockup review process. The design direction prioritizes warmth, clarity, and a sense of trustworthiness -- reflecting the app's role as a personal financial record keeper.

### Color Palette

| Color | Hex Code | Usage |
|-------|----------|-------|
| **Warm Cream** | #FAF7F2 | Primary background, card surfaces |
| **Forest Green** | #2D5A3D | Primary action buttons, header accents, warranty-active indicators |
| **Amber** | #D4920B | Warning states, warranty-expiring-soon highlights, secondary actions |
| **Red** | #C0392B | Destructive actions, warranty-expired indicators, error states |

### Typography

| Typeface | Role |
|----------|------|
| **DM Serif Display** | Headings, screen titles, hero numbers (e.g., warranty countdown) |
| **Plus Jakarta Sans** | Body text, labels, metadata, input fields |

### Layout Principles

- **Card-based design**: Each receipt is presented as a distinct card with subtle shadow elevation, providing clear visual separation and a tactile, tangible feel that echoes a physical receipt.
- **Clean modern aesthetic**: Generous whitespace, consistent spacing, and restrained use of color create a calm, uncluttered interface even when the vault contains hundreds of receipts.
- **Subtle shadows**: Depth is conveyed through soft drop shadows rather than hard borders, lending a contemporary feel.

### Navigation Structure

The app uses a bottom tab bar with five primary destinations:

| Tab | Icon Context | Purpose |
|-----|-------------|---------|
| **Vault** | Home / archive | Main receipt list, browsing, and filtering |
| **Expiring** | Clock / alert | Warranties approaching expiry, sorted by urgency |
| **+ Add** | Capture | Central prominent button for new receipt capture |
| **Search** | Magnifying glass | Full-text search and advanced filters |
| **Settings** | Gear | Account, storage mode, language, notifications, export, security |

### Approved Mockup Reference

The approved visual mockup is located at:

```
D:\Receipt and Warranty Vault\mockup\index.html
```

All implementation work should reference this mockup for visual fidelity. Deviations from the approved design require explicit approval.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*

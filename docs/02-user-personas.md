# 02 -- User Personas

**Document**: User Personas
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Primary Persona: The Organized Professional](#primary-persona-the-organized-professional)
2. [Secondary Persona: The Family Manager](#secondary-persona-the-family-manager)
3. [Tertiary Persona: The Small Business Owner](#tertiary-persona-the-small-business-owner)
4. [Early Adopter Persona: The Tech-Savvy Tester](#early-adopter-persona-the-tech-savvy-tester)
5. [Non-Personas: Who This App Is NOT For](#non-personas-who-this-app-is-not-for)

---

## Primary Persona: The Organized Professional

### Profile: Nikos

**"I just want to know what's still covered before I waste money replacing something."**

### Demographics

| Attribute | Detail |
|-----------|--------|
| **Name** | Nikos |
| **Age** | 32 |
| **Occupation** | Software engineer at a mid-size company |
| **Location** | Thessaloniki, Greece (works remotely for an Athens-based firm) |
| **Income** | Upper-middle -- comfortable discretionary spending |
| **Devices** | Android phone (primary), iPad (secondary), Windows laptop |
| **Tech savviness** | Moderate to high -- comfortable with apps, dislikes unnecessary complexity |
| **Languages** | Greek (native), English (fluent) |

### Goals

- **Never lose track of a warranty again.** Nikos buys quality electronics, appliances, and furniture and expects to use the full duration of any warranty or extended protection plan he pays for.
- **Find any receipt within seconds.** When he needs to make a return or file a claim, he wants to pull up the receipt immediately -- not spend 20 minutes searching through email or drawers.
- **Reduce mental overhead.** He does not want to think about receipt management. Capture should be fast and forgettable; the app should do the organizing.
- **Maintain control over personal data.** He is privacy-aware and wants to understand where his financial documents are stored and who can access them.

### Frustrations

- **Faded paper receipts.** He has lost warranty claims because the thermal paper receipt was illegible by the time he needed it. A laptop repair that should have been free cost him 180 euros because he could not produce a readable proof of purchase.
- **Receipts scattered everywhere.** Some are in his email, some photographed in his camera roll (buried among 8,000 photos), some in a kitchen drawer. There is no single place to look.
- **No warranty awareness.** He bought a 3-year extended warranty on his washing machine and completely forgot about it. The machine broke at month 34 -- one month after the warranty expired. He is still frustrated about this.
- **Existing apps are overkill or underpowered.** Expense tracking apps want him to set budgets and link bank accounts -- he just wants receipt storage. Document scanners produce PDFs but offer no intelligence about what was scanned.

### Current Behavior (How Nikos Handles Receipts Today)

Nikos has no consistent system. For expensive purchases (over 100 euros), he takes a photo with his phone camera and hopes he can find it later. For everyday purchases, he throws the receipt away immediately. Important warranty cards go into a desk drawer that he cleans out every year or so. He has tried two receipt-scanning apps in the past but abandoned both within a week -- one required too much manual data entry, and the other had no offline support and failed in the Plaisio store where he shops for electronics.

### Feature Priorities (v1 Features That Matter Most to Nikos)

| Priority | Feature | Why It Matters to Nikos |
|----------|---------|------------------------|
| 1 | Warranty tracking with expiry countdown | This is why he would download the app. It solves his most expensive recurring problem. |
| 2 | Push notification reminders | He does not check the app daily; he needs the app to come to him when a warranty is about to expire. |
| 3 | Photo capture with on-device OCR | He needs fast capture at the point of purchase, often with poor connectivity. Greek OCR is essential for local receipts. |
| 4 | Cloud LLM extraction | He wants the app to figure out the merchant, date, and total automatically. Manual entry is a dealbreaker. |
| 5 | Keyword search + filters | When he needs a receipt, he remembers the store name or product, not the date. |
| 6 | Storage mode choice | He wants cloud sync for backup but appreciates having the option of device-only mode. |
| 7 | Biometric lock | His receipts contain purchase history he considers private. Fingerprint unlock adds a layer of comfort. |

### Usage Scenario: A Day in Nikos's Life

It is Saturday afternoon. Nikos is at a Kotsovolos store in Thessaloniki, buying a new robot vacuum cleaner for 420 euros. He also purchases the 2-year extended warranty for an additional 49 euros.

At the checkout counter, Nikos pulls out his phone and opens Receipt & Warranty Vault using the home screen widget. He taps the quick capture button and photographs the receipt. The store has weak WiFi and his mobile data is spotty at this end of the mall, but the app does not care -- on-device OCR extracts the merchant name ("Kotsovolos"), the date, and the total within seconds. Nikos adds the warranty duration (2 years standard + 2 years extended = 4 years) and taps save. The entire interaction takes 15 seconds.

He pockets his phone and leaves the store. As he walks to his car and regains full connectivity, the app silently syncs the receipt to the cloud, triggers the LLM extraction to refine the parsed data, and generates a thumbnail image. Nikos does not notice any of this.

Twenty-three months later, Nikos receives a push notification: "Your warranty on Robot Vacuum (Kotsovolos, 420 euros) expires in 30 days. Tap to view details." The vacuum has been making a grinding noise. Nikos opens the app, finds the receipt instantly, and takes the vacuum in for a warranty repair the next day. He pays nothing. The app just saved him the cost of a replacement.

---

## Secondary Persona: The Family Manager

### Profile: Maria

**"I can never find the receipt when my kids break something or I need to return that IKEA shelf."**

### Demographics

| Attribute | Detail |
|-----------|--------|
| **Name** | Maria |
| **Age** | 41 |
| **Occupation** | Part-time accountant, full-time household manager |
| **Location** | Athens, Greece |
| **Income** | Middle -- budget-conscious, value-oriented shopper |
| **Devices** | iPhone (primary), shared family iPad |
| **Tech savviness** | Moderate -- uses apps daily but prefers simple interfaces over feature-rich complexity |
| **Languages** | Greek (primary), English (conversational) |
| **Family** | Married, two children (ages 8 and 13) |

### Goals

- **Track household purchases for returns and exchanges.** Maria buys clothing, school supplies, household goods, and groceries across multiple stores weekly. She frequently needs to return or exchange items -- children outgrow clothes, wrong sizes get purchased, gifts do not fit.
- **Know what she spent and where.** She keeps a mental budget and wants to occasionally review spending by store or category without using a full accounting app.
- **Handle warranty claims for family electronics.** The household has a tablet, a gaming console, two laptops, and various kitchen appliances. She is the one who deals with repairs and replacements.
- **Use the app in Greek without friction.** Her primary language is Greek, and most of her receipts are from Greek retailers. She does not want to mentally translate an English interface while standing in a checkout line.

### Frustrations

- **Returns without receipts are a constant battle.** She once drove 40 minutes back to IKEA with a defective bookshelf only to be told she needed the original receipt for a refund. She had thrown it away three days earlier. She received store credit instead of a cash refund, which she considered a loss.
- **Paper receipt chaos.** Her purse contains a small folder of receipts that she clears out once a month. By then, most are faded, crumpled, or impossible to match to the item they correspond to.
- **Sklavenitis receipts are long and confusing.** Weekly grocery receipts from Sklavenitis can be 30+ line items long. If she needs to verify a price discrepancy, finding the right line on a faded thermal printout is nearly impossible.
- **Family members lose things.** Her children and husband make purchases and lose receipts within hours. She ends up being the family's receipt manager by default and resents the role.

### Current Behavior (How Maria Handles Receipts Today)

Maria keeps a zippered pouch in her purse for "important" receipts -- anything over about 30 euros or anything she thinks might need to be returned. She throws away grocery receipts immediately unless she suspects a pricing error. For major purchases (furniture, electronics), she takes a photo and sends it to herself via Viber, creating a chaotic chat thread of receipt images with no organization. She has never used a receipt app. She learned about warranty expiry the hard way when her son's tablet screen cracked two weeks after the warranty ended.

### Feature Priorities (v1 Features That Matter Most to Maria)

| Priority | Feature | Why It Matters to Maria |
|----------|---------|------------------------|
| 1 | Greek localization (full UI) | She needs the interface in her primary language. English-only apps feel foreign and slow her down. |
| 2 | Photo capture with Greek OCR | Most of her receipts are in Greek. If the OCR cannot read them, she will not bother with the app. |
| 3 | Keyword search + filters | "Show me everything from IKEA in the last 3 months" -- this is her most common need. |
| 4 | Categories (custom + defaults) | She thinks in terms of "kids' stuff," "household," and "groceries." She needs to organize by her own mental model. |
| 5 | Warranty tracking | Less central than for Nikos, but she manages all family electronics and wants reminders for big-ticket items. |
| 6 | Bulk import from gallery | She has dozens of receipt photos in her camera roll from the past year. Onboarding bulk import means she does not start from zero. |
| 7 | Mark as returned | She returns items frequently and wants a clean record of what has been sent back. |

### Usage Scenario: A Day in Maria's Life

It is Wednesday morning. Maria drops her children at school and heads to Sklavenitis for the weekly grocery run. The cart is full, the total comes to 87.30 euros, and the receipt is 40 lines long. At the register, she opens Receipt & Warranty Vault, photographs the receipt, and the app captures it in Greek -- store name, date, and total are extracted automatically. She assigns it to the "Groceries" category and moves on. Twelve seconds.

After groceries, she stops at IKEA to buy a desk lamp for her daughter's room (34.99 euros) and a set of storage bins (22 euros). She captures both receipts. The lamp receipt gets tagged with a 1-year warranty.

That afternoon, she realizes the storage bins are the wrong size. She opens the app, searches "IKEA," finds the receipt from this morning, and drives back to the store. At the returns desk, she shows the receipt image on her phone screen. The return is processed immediately. She marks the item as "Returned" in the app.

Three weeks later, her son spills juice on the desk lamp. Maria opens the app, finds the IKEA lamp receipt, sees "Warranty: 328 days remaining," and contacts IKEA customer service with the purchase details on screen. The lamp is replaced under warranty.

---

## Tertiary Persona: The Small Business Owner

### Profile: Dimitris

**"Every receipt I lose is a tax deduction I cannot claim. That is real money out of my pocket."**

### Demographics

| Attribute | Detail |
|-----------|--------|
| **Name** | Dimitris |
| **Age** | 38 |
| **Occupation** | Freelance graphic designer with a small studio and two subcontractors |
| **Location** | Heraklion, Crete, Greece |
| **Income** | Variable -- project-based, tracks expenses closely for tax purposes |
| **Devices** | iPhone 15 Pro (primary), MacBook Pro (work), Android tablet (testing designs) |
| **Tech savviness** | High -- uses professional creative tools daily, appreciates well-designed software |
| **Languages** | Greek (native), English (professional fluency) |

### Goals

- **Capture every business expense receipt reliably.** Dimitris deducts office supplies, equipment, software subscriptions, client meeting meals, and travel from his taxable income. Every lost receipt is a lost deduction.
- **Export receipts in bulk for his accountant.** At the end of each quarter, he sends his accountant a package of all business-related receipts organized by date. Today this is a painful manual process.
- **Separate business and personal purchases.** He uses one wallet and one set of cards for everything. He needs a way to tag and filter business versus personal expenses.
- **Prove equipment purchases for tax depreciation.** Greek tax law requires proof of purchase for equipment depreciation claims. He needs to retain receipts for up to 5 years for certain categories.

### Frustrations

- **High volume of receipts.** Dimitris generates 15-25 business-related receipts per week. Paper management at this volume is unsustainable. He has tried keeping them in envelopes labeled by month, but compliance at tax time is still stressful.
- **Quarterly export is a nightmare.** His accountant wants receipts organized by date with amounts visible. Dimitris currently spends 2-3 hours per quarter photographing, sorting, and emailing receipt images. The process is error-prone and he has missed deductions.
- **Mixed-language receipts.** He buys from both Greek vendors (office supplies, local printing) and international vendors (Adobe, Figma, Amazon). His receipt collection is a mix of Greek and English, and no single OCR tool handles both well.
- **Long-term storage concerns.** He needs receipts accessible for up to 5 years but does not trust his phone's storage alone. He wants cloud backup but is wary of services that might not exist in 5 years.

### Current Behavior (How Dimitris Handles Receipts Today)

Dimitris is more organized than most but still struggles. He has a "Receipts" album in his iPhone Photos app where he saves pictures of every business receipt. At the end of each month, he exports the album to a folder on his MacBook labeled by month. At quarter's end, he manually creates a spreadsheet listing each receipt's date, vendor, amount, and category, then emails the spreadsheet and a ZIP of images to his accountant. The process takes 2-3 hours per quarter. He occasionally misses receipts that he photographed but forgot to move to the album.

### Feature Priorities (v1 Features That Matter Most to Dimitris)

| Priority | Feature | Why It Matters to Dimitris |
|----------|---------|---------------------------|
| 1 | Batch export by date range | This directly replaces his 2-3 hour quarterly export process. It is the single feature that would make him adopt the app permanently. |
| 2 | Cloud LLM extraction (high accuracy) | At 15-25 receipts per week, manual data entry is not viable. He needs automatic extraction of merchant, date, and total with greater than 95% accuracy. |
| 3 | Custom categories | He needs "Business - Office Supplies," "Business - Software," "Business - Travel," and "Personal" at minimum. The 10 defaults are a starting point but not sufficient. |
| 4 | Cloud + device storage mode | He needs cloud backup for long-term retention and access from multiple contexts. Device-only is not an option for him. |
| 5 | Photo capture + import | He captures physical receipts at point of purchase and imports digital invoices (PDFs from Adobe, Figma) from his email. |
| 6 | Keyword search + FTS5 | "Show me all Adobe purchases from 2025" -- this is the type of query he runs when reconciling with bank statements. |
| 7 | Stats display | "X receipts, Y euros in active warranties" helps him gauge his monthly business spending at a glance. |

### Usage Scenario: A Day in Dimitris's Life

It is a typical Tuesday. Dimitris starts his morning at a cafe near his studio, where he meets a client over coffee. The bill is 14.80 euros. He photographs the receipt, the app extracts "Cafe Veneto, 14.80 EUR, 2026-02-10" automatically, and he tags it as "Business - Client Meeting." Five seconds at the table.

Back at the studio, he receives an email from Adobe with his monthly Creative Cloud invoice (54.99 euros). He saves the PDF to his phone and imports it into Receipt & Warranty Vault. The LLM extraction identifies it as "Adobe Inc., Creative Cloud subscription, 54.99 EUR" and auto-categorizes it as software. He adjusts the category to "Business - Software" and saves.

At lunch, he picks up printer paper and ink cartridges from Plaisio (42.60 euros, receipt in Greek). The in-store capture takes 12 seconds. Greek OCR reads the receipt correctly.

At the end of the quarter, Dimitris opens the app, navigates to export, selects "January 1 - March 31, 2026," filters by his "Business" categories, and exports the batch. He emails the export file to his accountant. The entire quarterly process that used to take 2-3 hours is done in under 5 minutes.

---

## Early Adopter Persona: The Tech-Savvy Tester

### Profile: Elena

**"I want to push this app to its limits and tell you exactly what breaks."**

### Demographics

| Attribute | Detail |
|-----------|--------|
| **Name** | Elena |
| **Age** | 27 |
| **Occupation** | Junior DevOps engineer at a tech startup |
| **Location** | Athens, Greece |
| **Income** | Entry-level professional -- moderate spending, value-conscious |
| **Devices** | Google Pixel 8 (Android, primary), older iPhone SE (secondary, for testing) |
| **Tech savviness** | Very high -- understands app architecture, knows what "offline-first" means, reads changelogs |
| **Languages** | Greek (native), English (daily professional use) |

### Goals

- **Help build a product she genuinely wants to use.** Elena is not testing out of obligation; she has the exact pain point the app addresses and wants to see it solved well.
- **Provide high-quality, actionable feedback.** She understands the difference between "this feels slow" and "the OCR extraction screen takes 4 seconds to render after camera capture on my Pixel 8 with 6GB of available RAM." She wants to give feedback at the level the development team can act on.
- **Stress-test edge cases.** She will intentionally photograph crumpled receipts, faded thermal printouts, receipts in dim lighting, receipts in mixed Greek/English, and extremely long supermarket receipts. She will toggle airplane mode mid-sync. She will fill up local storage and see what happens.
- **Use the app as her actual receipt system.** She does not want to use it as a toy alongside her real system. She wants to go all-in, making it her primary receipt management tool, because that is the only way to find real problems.

### Frustrations

- **Beta apps that waste her time.** She has participated in app betas before where bugs she reported were ignored for months, feedback channels were one-directional, and she felt like free QA labor with no influence on the product. She is selective about which betas she joins.
- **Apps that claim offline support but break.** She commutes on the Athens Metro where connectivity is intermittent. She has been burned by apps that show spinners, lose data, or crash when toggling between online and offline states. She is deeply skeptical of offline claims until she tests them personally.
- **Greek text handling as an afterthought.** She has seen too many apps where Greek localization is a machine-translated wrapper over an English-first design -- truncated labels, broken date formats, misaligned text. She expects Greek to be a first-class citizen, not a translation layer.
- **Poor camera capture UX.** She knows that receipt capture in real-world conditions (bad lighting, uneven surfaces, crumpled paper) is the hardest part of the app. She is frustrated by apps that work perfectly on flat, well-lit receipts in demos but fail on the kitchen counter.

### Current Behavior (How Elena Handles Receipts Today)

Elena does not manage receipts systematically. She photographs high-value purchases (over 50 euros) and leaves them in Google Photos, relying on Google's search to find them later by approximate text matching. For everything else, she keeps receipts for a few days and discards them. She has never tracked a warranty intentionally. She is aware that she has lost money on expired warranties but considers the effort of manual tracking to exceed the expected savings -- an equation she believes this app could change.

### Feature Priorities (v1 Features That Matter Most to Elena)

| Priority | Feature | Why It Matters to Elena |
|----------|---------|------------------------|
| 1 | Offline-first architecture | This is the claim she will test most aggressively. If it works as promised, she becomes a vocal advocate. If it fails, she will find every failure mode. |
| 2 | Custom sync engine reliability | She will test airplane mode toggles, mid-upload interruptions, conflict scenarios (editing the same receipt on two devices), and full reconciliation. |
| 3 | On-device OCR (hybrid pipeline) | She wants to see ML Kit and Tesseract working together seamlessly on mixed-language receipts. She will test Greek-only, English-only, and mixed receipts. |
| 4 | Home screen widget | She is a widget power user. Quick capture from the home screen is how she wants to interact with the app 80% of the time. |
| 5 | Warranty tracking + reminders | She is genuinely interested in this feature for her own electronics. She will test notification timing, timezone handling, and edge cases like leap years. |
| 6 | Biometric lock | She will test biometric fallback behavior, what happens when biometrics fail, and whether the PIN fallback is accessible. |
| 7 | Bulk import from gallery | She has approximately 30 receipt photos in Google Photos. She wants to see how the onboarding import handles them -- correctly identified, no false positives on non-receipt images. |

### Usage Scenario: A Day in Elena's Life

It is Monday morning. Elena is on the Athens Metro heading to work. She remembers she bought a new mechanical keyboard online over the weekend and never captured the receipt. She opens Receipt & Warranty Vault -- the metro has no signal, but the app opens instantly from local storage. She imports the order confirmation screenshot from her gallery. On-device OCR extracts the merchant and total. She adds a 2-year warranty manually. Saved. The train pulls into Syntagma station and she pockets her phone.

At lunch, she grabs a gyro and a coffee. Total: 6.50 euros. She photographs the receipt using the home screen widget. The receipt is in Greek, slightly crumpled. She watches the OCR -- Tesseract correctly reads the Greek merchant name, ML Kit picks up the numbers. She notes that the total was extracted correctly but the date format defaulted to US format (MM/DD) instead of European (DD/MM). She screenshots the issue and adds it to her feedback notes with the exact receipt image attached.

After work, she deliberately turns on airplane mode and spends 15 minutes browsing her vault, searching for receipts, editing a category, and adding a note to an old receipt. Everything works. She turns connectivity back on and watches the sync indicator. She verifies that her offline edits propagated correctly to the cloud by checking the "last synced" timestamp.

Before bed, she writes a detailed feedback message covering three items: the date format issue, a suggestion for the search results layout, and a compliment on the sync speed. She includes device specs, OS version, and steps to reproduce the date bug.

---

## Non-Personas: Who This App Is NOT For

Understanding who the app does not serve is as important as understanding who it does. The following profiles describe users whose needs fall outside the scope of Receipt & Warranty Vault. Attempting to serve these users would dilute the product's focus, introduce unnecessary complexity, and delay delivery.

---

### The Professional Accountant Needing Double-Entry Bookkeeping

**Profile**: A certified accountant or bookkeeper managing financial records for clients or a company. Requires journal entries, ledgers, account reconciliation, tax code mapping, multi-currency handling, and audit trails that conform to accounting standards (IFRS, GAAP, Greek NPDD).

**Why they are not served**: Receipt & Warranty Vault captures and stores receipts. It does not perform accounting. There is no chart of accounts, no debit/credit ledger, no bank reconciliation, and no tax filing integration. An accountant who tries to use this app as a bookkeeping tool will find it fundamentally inadequate. The app may be useful to an accountant's clients for collecting receipts before handing them off, but it is not the accountant's tool.

**What they should use instead**: Dedicated accounting software such as QuickBooks, Xero, or local Greek solutions like Epsilon Net or SoftOne.

---

### The Business Needing Invoice and Accounts Receivable Management

**Profile**: A company (small, medium, or large) that issues invoices to clients, tracks accounts receivable, manages payment terms, sends payment reminders, and needs integration with ERP or CRM systems.

**Why they are not served**: Receipt & Warranty Vault handles incoming receipts (proof of purchase), not outgoing invoices. It has no concept of customers, payment terms, aging reports, or revenue tracking. A business trying to manage its invoicing workflow with this app will find no relevant functionality.

**What they should use instead**: Invoicing platforms such as FreshBooks, Wave, or integrated ERP systems.

---

### The Person Who Never Keeps Receipts

**Profile**: A consumer who intentionally discards all receipts immediately after purchase, never makes returns, does not track warranties, and has no interest in maintaining purchase records. This person's philosophy is "if it breaks, I buy a new one."

**Why they are not served**: The entire value proposition of Receipt & Warranty Vault depends on the user caring about receipt retention and warranty awareness. A user with zero interest in these activities will not download the app, and if they do, they will not form the capture habit necessary for the app to provide value. No amount of UX optimization can create a need that does not exist.

**What they should use instead**: Nothing. Their current system (discarding everything) works for them.

---

### The Enterprise Procurement Team

**Profile**: A procurement department managing purchase orders, vendor relationships, approval workflows, budget allocation, and compliance documentation for a large organization.

**Why they are not served**: Receipt & Warranty Vault is a personal, individual-user tool. It has no multi-user permissions, no approval workflows, no purchase order matching, no vendor management, and no integration with enterprise procurement systems (SAP Ariba, Coupa, Oracle). The v2 shared vault feature (household-level sharing) is orders of magnitude simpler than enterprise procurement needs.

**What they should use instead**: Enterprise procurement platforms appropriate to their organization's scale and industry.

---

### The Tax Professional Needing Compliance Automation

**Profile**: A tax advisor or compliance officer who needs automated VAT calculation, tax code assignment, regulatory reporting, and integration with government tax portals (e.g., AADE in Greece, HMRC in the UK).

**Why they are not served**: Receipt & Warranty Vault stores receipt data but does not interpret it through a tax compliance lens. It does not calculate VAT, assign tax codes, generate tax returns, or interface with government systems. While the batch export feature may provide raw data that a tax professional can use as input, the app itself performs no tax-specific processing.

**What they should use instead**: Tax compliance software specific to their jurisdiction, such as TaxDome, Avalara, or local solutions.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*

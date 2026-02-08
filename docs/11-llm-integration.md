# 11 -- LLM Integration

**Document**: LLM Integration and OCR Pipeline
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Overview](#overview)
2. [Stage 1: On-Device OCR (Immediate, Offline)](#stage-1-on-device-ocr-immediate-offline)
3. [Stage 2: Cloud LLM Refinement (Online, High Accuracy)](#stage-2-cloud-llm-refinement-online-high-accuracy)
4. [Cost Management](#cost-management)
5. [Data Privacy](#data-privacy)
6. [Future: LLM Natural Language Search (v1.5)](#future-llm-natural-language-search-v15)

---

## Overview

### Purpose

The LLM integration layer is the intelligence engine that transforms Receipt & Warranty Vault from a simple photo album into a structured, searchable personal financial archive. Its purpose is to extract structured receipt data from photographs with high accuracy, minimal user intervention, and maximum speed. Without this layer, users would need to manually enter every merchant name, purchase date, total amount, and warranty period -- a friction-heavy experience that would kill adoption.

### Two-Stage Pipeline

Receipt data extraction follows a two-stage pipeline designed to balance immediacy with accuracy.

**Stage 1: On-Device OCR** runs immediately when the user captures a receipt photo, with no internet connection required. It uses Google ML Kit Text Recognition v2 for Latin-script text and numbers, and Tesseract OCR for Greek-script text. This stage delivers basic field extraction within seconds of capture, giving the user instant feedback and a usable receipt record even in completely offline environments.

**Stage 2: Cloud LLM Refinement** runs when the device has internet connectivity. It sends the receipt image and the raw OCR text to AWS Bedrock, where Claude Haiku 4.5 (or Sonnet 4.5 as a fallback) applies contextual understanding to produce highly accurate structured data. This stage can interpret receipt layouts, normalize dates and currencies, identify merchant names from partial or ambiguous text, and distinguish subtotals from totals from tax lines -- tasks that raw OCR alone cannot perform reliably.

### Performance Goals

| Metric | Target |
|--------|--------|
| End-to-end capture experience | Under 20 seconds from tapping "Add" to seeing extracted data |
| On-device OCR accuracy (Latin) | Greater than 85% for merchant, date, and total fields |
| On-device OCR accuracy (Greek) | 60-75% for merchant and product description fields |
| Cloud LLM extraction accuracy | Greater than 95% for all primary fields |
| On-device OCR latency | Under 5 seconds on modern devices |
| Cloud LLM latency | Sub-1 second typical (Haiku), 1-3 seconds (Sonnet fallback) |

The two-stage design means the user never waits for cloud processing. They see on-device results immediately, can correct any errors, and later receive a silent update when cloud refinement completes. This architecture ensures the app remains fully functional in offline environments -- stores, underground parking garages, warehouses -- where receipt capture most commonly occurs.

---

## Stage 1: On-Device OCR (Immediate, Offline)

Stage 1 runs entirely on the user's device, requires no internet connection, and produces results within seconds. It combines two complementary OCR engines to handle the bilingual reality of receipts encountered by the app's target users.

### ML Kit Text Recognition v2 (Latin and Numbers)

**Purpose**: Extract store names, monetary amounts, dates, product names, and any other text rendered in Latin script or numeric characters.

**Technology**: Google ML Kit Text Recognition v2, accessed through the `google_mlkit_text_recognition` Flutter package. ML Kit is Google's on-device machine learning SDK and runs inference locally using the device's CPU and, where available, hardware acceleration through the device's neural processing unit.

**Execution Environment**: Fully on-device. No data is sent to Google's servers. The ML Kit model is bundled with the app or downloaded on first use (depending on platform), and all inference runs locally.

**Supported Scripts**: ML Kit Text Recognition v2 supports Latin, Chinese, Devanagari, Japanese, and Korean scripts. It does not support Greek script, which is the specific gap that necessitates the hybrid pipeline with Tesseract.

**Performance Characteristics**:
- Latency: approximately 1-3 seconds on modern devices (devices from 2020 onward with mid-range or better processors).
- The processing time scales with image resolution and text density but remains under 3 seconds for typical receipt images at the app's target compression (JPEG 85% quality, 1-2 MB).

**Output Format**: ML Kit returns structured text blocks, each containing:
- The recognized text string.
- Bounding box coordinates that describe the spatial position of the text block within the image.
- Confidence scores (0.0 to 1.0) indicating the engine's certainty in the recognition result.
- Hierarchical structure: blocks contain lines, lines contain elements (individual words or character groups).

This spatial and hierarchical information is critical for the merging step, where ML Kit results and Tesseract results are combined by position to reconstruct the full receipt text.

### Tesseract OCR (Greek Script)

**Purpose**: Extract Greek-language text from receipts, including store names, product descriptions, addresses, and any textual content rendered in the Greek alphabet. This fills the gap left by ML Kit's lack of Greek script support.

**Technology**: Tesseract OCR engine, accessed through the `flutter_tesseract_ocr` Flutter package. Tesseract is an open-source OCR engine originally developed by Hewlett-Packard and currently maintained by Google. It uses LSTM-based neural network models for text recognition.

**Execution Environment**: Fully on-device. No data is sent to any external server.

**Language Data**: Tesseract requires a trained data file for each supported language. The Greek language pack (identified as "ell" in Tesseract's language code system) must be bundled with the application. This trained data file is approximately 15 MB in size and is included in the app's assets at build time, ensuring it is available immediately without any runtime download.

**Performance Characteristics**:
- Latency: approximately 2-5 seconds on modern devices, somewhat slower than ML Kit due to Tesseract's heavier processing model.
- Greek text recognition accuracy is inherently lower than ML Kit's Latin recognition, typically achieving 60-75% accuracy depending on receipt print quality, font type, and image conditions. Thermal receipt paper, which fades quickly and often produces low-contrast text, is a particular challenge for Greek OCR.

**Output Format**: Tesseract returns:
- Raw recognized text as a string.
- Confidence scores for the recognition result.
- Unlike ML Kit, Tesseract's bounding box information requires additional processing to align with ML Kit's coordinate system, which is handled in the merging step.

### Hybrid Pipeline

The hybrid pipeline orchestrates both OCR engines and produces a unified set of extracted fields from their combined output. The pipeline runs entirely on-device and completes within seconds of image capture.

**Step 1: Image Capture**

The user captures a receipt photograph using the device camera (via the `image_picker` package) or imports an existing image from their gallery or file system. The image enters the pipeline as a raw photograph.

**Step 2: Image Preprocessing**

Before OCR processing, the captured image undergoes preprocessing to maximize recognition accuracy. This preprocessing is performed on-device using the `image` Dart package and includes:

- **Auto-crop**: Detect the receipt boundaries within the photograph and crop to remove background elements (desk surface, hand, wallet). This focuses the OCR engines on the receipt content only.
- **Deskew**: Detect and correct rotational skew. Receipts photographed at an angle produce significantly worse OCR results. Deskewing rotates the image so that text lines are horizontal.
- **Contrast enhancement**: Adjust brightness and contrast to improve text visibility, particularly for faded thermal receipts or images captured in low-light conditions.

The preprocessing step does not compress the image. Compression to JPEG 85% quality for storage occurs separately, after the preprocessed image has been used for OCR.

**Step 3: ML Kit Processing**

The preprocessed image is passed to ML Kit Text Recognition v2. ML Kit scans the image and returns all detected Latin-script text blocks with their bounding boxes and confidence scores. This step typically completes in 1-3 seconds.

**Step 4: Tesseract Processing**

The same preprocessed image is passed to Tesseract OCR configured with the Greek (ell) language pack. Tesseract scans the image and returns all detected Greek-script text with confidence scores. This step typically completes in 2-5 seconds. Steps 3 and 4 can run concurrently on separate isolates (Dart's concurrency mechanism) to minimize total pipeline latency.

**Step 5: Result Merging**

The outputs from ML Kit and Tesseract are merged into a unified text representation. The merging process:

- Combines text blocks from both engines, using bounding box positions to determine the spatial ordering of text on the receipt (top to bottom, left to right).
- Resolves overlaps: where both engines detected text in the same region (for example, a line containing both Latin and Greek characters), the higher-confidence result is preferred, or both are retained if they represent complementary content.
- Produces a single ordered text representation of the full receipt content in both scripts.

**Step 6: Basic Field Extraction (Regex-Based)**

With the merged text available, the app applies pattern-matching rules to extract key fields. This is not intelligent parsing -- it is simple regular expression matching that looks for known patterns:

- **Date patterns**: The app searches for date-like strings in common formats including DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, and variations with two-digit years. Greek receipts typically use DD/MM/YYYY format. The first valid date found is used as the purchase date candidate.
- **Currency patterns**: The app searches for monetary amount patterns including euro sign followed by digits (such as a euro sign, digits, a decimal separator, and two decimal digits), digits followed by a euro sign, and comma-as-decimal patterns common in European formatting (such as digits, a comma, and two decimal digits followed by a euro sign). The largest monetary value found is typically the total, though this heuristic can be incorrect when subtotals or multi-item receipts are involved.
- **Store name heuristic**: The merchant name is typically the largest text block at the top of the receipt. The app uses a combination of position (topmost text blocks) and font size (largest bounding boxes) to identify the store name candidate.

**Step 7: Immediate Display**

The extracted fields -- store name, purchase date, and total amount -- are displayed to the user within 5 seconds of capture. The user sees these fields populated in the receipt editing form and can immediately verify and correct any errors. This immediate feedback is essential to the sub-20-second capture experience target.

**Step 8: User Correction**

All extracted fields are editable. The user can correct any field that the on-device OCR got wrong. User corrections are tracked in the `user_edited_fields` array, which is critical for the conflict resolution system: fields the user has manually edited will not be overwritten by subsequent cloud LLM refinement (Tier 3 conflict resolution rules).

**Step 9: Queue for Cloud Refinement**

Once the receipt is saved locally, the raw OCR text output and the receipt image are queued for cloud LLM refinement. This queue persists across app restarts and is processed when the device has internet connectivity. The queuing mechanism ensures that no receipt is lost if the user captures a receipt in an offline environment and does not regain connectivity for hours or days.

### Limitations of On-Device OCR

The on-device stage is designed for speed and offline availability, not for high accuracy. Its limitations are well understood and explicitly accepted as the cost of instant, offline extraction.

**Accuracy ceiling of 70-85%**: Depending on receipt quality (print clarity, paper condition, lighting during capture), the on-device stage correctly extracts the merchant name, date, and total amount in approximately 70-85% of cases for Latin-script receipts. This means roughly 1 in 5 to 1 in 3 receipts will have at least one incorrectly extracted field that requires user correction or cloud refinement.

**No structural understanding**: Raw OCR produces a sequence of text blocks but has no understanding of what those blocks mean in the context of a receipt. It cannot distinguish a subtotal from a total from a tax line. It cannot identify which numbers are prices versus quantities versus receipt reference numbers. This contextual understanding is what the cloud LLM provides.

**No handwritten note handling**: Handwritten text -- such as notes added by a cashier, warranty start dates written on a box, or annotations -- is not reliably recognized by either ML Kit or Tesseract. Handwritten content requires manual entry by the user.

**No line item extraction in v1**: Extracting individual product line items (product name, quantity, unit price) from receipts requires understanding tabular layout and column alignment, which is beyond the capability of the regex-based field extraction in v1. Line item extraction is a potential v1.5 or v2 feature that would rely on cloud LLM processing.

**Lower Greek accuracy**: Tesseract's Greek recognition accuracy (60-75%) is notably lower than ML Kit's Latin recognition accuracy (85%+). Greek receipts are therefore more likely to require user correction or cloud refinement. This is an inherent limitation of the available on-device Greek OCR technology and is the primary motivation for the cloud refinement stage.

---

## Stage 2: Cloud LLM Refinement (Online, High Accuracy)

Stage 2 runs on the server side when the device has internet connectivity. It takes the receipt image and raw OCR text produced by Stage 1 and applies a large language model to extract highly accurate, structured data. This stage transforms raw text into a clean, normalized receipt record.

### Amazon Bedrock -- Claude Haiku 4.5 (Primary)

**Service**: Amazon Bedrock, AWS's managed service for foundation model inference. Bedrock provides API access to foundation models without requiring the application to manage model hosting, scaling, or infrastructure.

**Model**: Claude Haiku 4.5 by Anthropic.
- Model ID: `anthropic.claude-haiku-4-5-v1`
- Haiku 4.5 is selected as the primary model because it offers the best combination of cost, speed, and accuracy for the receipt extraction task. Receipts are relatively simple documents with predictable structure, and Haiku 4.5's capabilities are more than sufficient for this use case.

**Input**: Each invocation receives two inputs:
- The receipt image, encoded in base64 format. Providing the image directly allows the model to use its vision capabilities to interpret the receipt layout, read text that OCR may have missed, and understand spatial relationships between elements.
- The raw OCR text extracted during Stage 1. Providing both the image and the OCR text gives the model redundant information sources. If the image is partially obscured or low quality, the OCR text may fill gaps; if the OCR text is garbled, the model can fall back to its own visual interpretation of the image.

**Output**: The model returns a structured JSON response containing the extracted receipt fields (described in detail under LLM Prompt Design below).

**Cost**: Approximately $0.004 per receipt invocation. This is calculated based on Haiku 4.5's pricing of approximately $0.80 per 1,000 input tokens and $4.00 per 1,000 output tokens. A typical receipt image plus OCR text consumes roughly 1,000-2,000 input tokens, and the structured JSON output consumes approximately 200-400 output tokens.

**Latency**: Sub-1 second typical response time. Haiku 4.5 is designed for fast inference, and the receipt extraction task produces a relatively small output, keeping latency low.

**Region**: eu-west-1 (Ireland). All Bedrock invocations are made in the same AWS region as the rest of the backend infrastructure, maintaining data residency within the EU. Model availability in eu-west-1 should be verified before implementation, as Bedrock model availability can vary by region.

### Claude Sonnet 4.5 (Fallback)

**Model**: Claude Sonnet 4.5 by Anthropic.
- Model ID: `anthropic.claude-sonnet-4-5-v1`
- Sonnet 4.5 is a more capable (and more expensive) model that serves as the fallback when Haiku does not produce sufficiently confident results.

**When Sonnet is used**: The fallback to Sonnet is triggered in specific circumstances:
- When Haiku returns a confidence score below 70% on any required field (store name, purchase date, or total amount). A low-confidence extraction suggests the receipt is unusually difficult -- poor print quality, unusual layout, mixed languages, or damaged paper.
- When the receipt image quality is assessed as poor (blurry, heavily skewed, very low contrast) and Haiku's output is incomplete.
- When Haiku's API endpoint is throttled or temporarily unavailable due to capacity constraints.

**Cost**: Approximately $0.015 per receipt invocation, which is 3-4 times the cost of Haiku. This higher cost is acceptable because Sonnet is invoked for only an estimated 5-10% of receipts -- those that genuinely require a more capable model.

**Latency**: 1-3 seconds typical response time, somewhat slower than Haiku but well within acceptable bounds given that this is an asynchronous background process.

### LLM Prompt Design

The prompt sent to the LLM is designed to produce consistent, structured, and machine-parseable output. The following describes the approach and output format, not the literal prompt text (which will be refined during implementation).

**System prompt**: The model is instructed that it is a receipt data extraction assistant. Its sole task is to examine the provided receipt image and OCR text and extract structured data fields. It is instructed to focus on accuracy, to handle both Greek and English text, and to return null for any field it cannot confidently extract rather than guessing.

**Input composition**: The prompt includes both the base64-encoded receipt image and the raw OCR text from Stage 1. Including both provides redundancy: the model can cross-reference its own visual reading of the image against the OCR text, correcting errors in either source. The OCR text also provides a textual anchor that can improve the model's reading of low-quality image regions.

**Requested output format**: The model is instructed to return a JSON object with the following fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| storeName | String | Yes | The merchant or store name as displayed on the receipt |
| purchaseDate | String (ISO 8601) | Yes | The purchase date in YYYY-MM-DD format, normalized from whatever format appears on the receipt |
| totalAmount | Number | Yes | The total amount paid, as a decimal number (e.g., 42.50) |
| currency | String (ISO 4217) | Yes | The currency code (e.g., EUR, USD, GBP) |
| lineItems | Array of objects | No (optional in v1) | Individual product entries, each with name, quantity, and unit price |
| taxAmount | Number | No | The tax amount if separately listed on the receipt |
| paymentMethod | String | No | The payment method if listed (e.g., CARD, CASH, VISA) |
| receiptNumber | String | No | The receipt or transaction reference number if present |

**Confidence scoring**: The model is instructed to include a confidence score (integer, 0-100) for each extracted field. A confidence of 100 means the model is certain of the extraction. A confidence of 0 means the model could not extract the field at all (the field value is returned as null). Intermediate values indicate partial certainty -- for example, a date might be extracted with confidence 60 if the year is legible but the day is smudged.

**Language handling**: The prompt explicitly instructs the model to handle receipts containing Greek text, English text, or a mixture of both. For store names that appear only in Greek, the model extracts the Greek name as-is (in Greek characters). The model is also instructed to transliterate store names to Latin characters as a secondary field if the store name is exclusively in Greek, enabling search in both scripts.

**Error handling**: If the model cannot extract a field -- because the information is not present on the receipt, is illegible, or is ambiguous -- it returns null for that field with a confidence of 0. The model does not hallucinate or fabricate data. This is a critical instruction: a null extraction with confidence 0 is always preferred over a plausible but incorrect guess.

### Refinement Flow

The refinement flow describes the end-to-end process by which a receipt captured on the device is enhanced with cloud LLM extraction. This flow is asynchronous and does not block the user's interaction with the app.

**Step 1: Client syncs receipt to server.** When the device has internet connectivity, the sync engine uploads the receipt metadata (including raw OCR text) to DynamoDB and the receipt image to S3. The image is uploaded to S3 using a pre-signed URL generated by the server, with a 10-minute expiry and content-type/size restrictions.

**Step 2: Refinement triggered.** The refinement process can be triggered in one of two ways: the client can call `POST /receipts/{id}/refine` to explicitly request refinement, or the server can trigger refinement automatically when a new receipt image is uploaded to S3 (via an S3 event notification or as part of the sync processing logic). Automatic triggering is the default behavior.

**Step 3: Lambda retrieves image.** The `ocr_refine` Lambda function is invoked. It retrieves the receipt image from S3 and the receipt metadata (including `ocrRawText`) from DynamoDB.

**Step 4: Lambda calls Bedrock Haiku 4.5.** The Lambda function constructs the prompt with the base64-encoded image and OCR text, then invokes the Bedrock API with the Haiku 4.5 model. It parses the structured JSON response and evaluates the confidence scores.

**Step 5: Confidence check and Sonnet fallback.** If any required field (storeName, purchaseDate, totalAmount) has a confidence score below 70%, the Lambda function retries the extraction using the Sonnet 4.5 model. The Sonnet response replaces the Haiku response entirely -- there is no merging of results from both models.

**Step 6: DynamoDB update.** The Lambda function writes the refined extraction results to DynamoDB. The fields updated are the Tier 1 (server-owned) fields as defined by the conflict resolution system:
- `extractedMerchantName`: the store name as extracted by the LLM.
- `extractedDate`: the purchase date as extracted by the LLM.
- `extractedTotal`: the total amount as extracted by the LLM.
- `ocrRawText`: preserved from Stage 1 (not overwritten).
- `llmConfidence`: the overall confidence score from the LLM extraction.

The receipt's `version` field is incremented to signal that the record has been updated.

**Step 7: Client receives updated data on next sync.** During the next delta sync cycle, the client detects the incremented version number and downloads the updated receipt record. The sync engine applies field-level conflict resolution:
- Tier 1 fields (LLM-extracted data) are updated with the server values, as the server is the authority for these fields.
- Tier 2 fields (user notes, tags, favorites) remain unchanged, as the client is the authority for these fields.
- Tier 3 fields (display name, category, warranty months) follow a conditional rule: if the user has manually edited these fields (tracked in the `user_edited_fields` array), the user's values are preserved. If the user has not edited them, they are auto-updated with the LLM's suggestions.

**Step 8: User notification.** After the refined data is synced to the device, a push notification is sent to the user informing them that the receipt has been updated with improved data. The notification includes the store name for context, following the format: "Receipt from [StoreName] updated with improved data." This notification uses the server push notification system (SNS to FCM/APNs) and is delivered as an informational notification that does not require user action.

---

## Cost Management

The LLM processing cost is the single largest variable cost in the Receipt & Warranty Vault infrastructure. Cost management is therefore a critical design concern, and the architecture incorporates several strategies to minimize expenditure without sacrificing accuracy.

### Haiku-First Strategy

The primary cost management lever is the model selection hierarchy. Claude Haiku 4.5 is used for all initial extraction attempts. Based on typical receipt quality and the task's moderate complexity, an estimated 90% or more of receipts will be fully handled by Haiku at approximately $0.004 per receipt. Only the 5-10% of receipts that produce low-confidence results are escalated to Sonnet 4.5 at approximately $0.015 per receipt.

This tiered approach means the blended average cost per receipt is approximately $0.005, rather than the $0.015 it would cost if Sonnet were used for all receipts.

### Cost Projections

| Scale | Receipts per Month | Haiku Cost (90%) | Sonnet Cost (10%) | Total LLM Cost |
|-------|-------------------|-------------------|-------------------|----------------|
| 5 users (testing) | ~100 | ~$0.36 | ~$0.04 | ~$0.40 |
| 100 users | ~2,000 | ~$7.20 | ~$0.80 | ~$8.00 |
| 1,000 users | ~20,000 | ~$72.00 | ~$8.00 | ~$80.00 |
| 10,000 users | ~200,000 | ~$720.00 | ~$80.00 | ~$800.00 |

These projections assume an average of 20 receipts per user per month, which is the estimated usage pattern for active users.

### Caching and Deduplication

LLM extraction results are persisted in DynamoDB and are never recomputed unless the receipt image itself changes. If a user re-syncs a receipt without modifying the image, the existing LLM extraction is retained. This prevents unnecessary API calls from the sync engine.

Specifically:
- The `llmConfidence` field is checked before triggering refinement. If a receipt already has a high-confidence LLM extraction (confidence 70% or above on all required fields), refinement is not re-triggered.
- If a user replaces the receipt image (re-captures or uploads a better photo), the refinement is triggered again with the new image, and the previous LLM results are overwritten.

### No Batch Processing in v1

At the scale targeted by v1 (5 testers, approximately 100 receipts per month), batch processing offers no meaningful cost benefit. Each receipt is processed individually in real-time as it is synced. Batch processing may be considered in future versions if scale demands it, but at v1 volumes the overhead of a batching system would exceed its savings.

### No Speculative Processing

The system does not speculatively process receipts that the user has not explicitly captured. For example, during bulk import (scanning the gallery for receipt-like images at onboarding), images are identified as potential receipts using on-device heuristics, but cloud LLM processing is only triggered for images that the user confirms and saves. This prevents unnecessary Bedrock invocations on false positives from the gallery scan.

---

## Data Privacy

The LLM integration handles sensitive financial data -- purchase histories, spending amounts, store preferences, and receipt images that may contain payment card information, loyalty account numbers, or personal addresses. Privacy protections are therefore a foundational design requirement, not an afterthought.

### AWS Bedrock Data Policy

Amazon Bedrock provides a contractual guarantee that input data (images and text sent to the Bedrock API) and output data (model responses) are not stored by AWS beyond the duration of the API request, and are not used to train or improve any foundation model. This guarantee is documented in the AWS Bedrock service terms and applies to all models accessed through Bedrock, including the Anthropic Claude models used by this application.

This means:
- Receipt images sent to Bedrock for LLM extraction are processed in memory during the API call and are not written to any persistent storage by AWS.
- Raw OCR text included in the prompt is similarly not retained.
- Model responses containing extracted receipt data are returned to the calling Lambda function and are not stored by Bedrock.
- No user data flows into any model training pipeline.

### Data Residency

All Bedrock API calls are made to the eu-west-1 (Ireland) region. Receipt images and text are processed within the EU, consistent with the application's GDPR data residency commitment. The data does not leave the EU region at any point during LLM processing.

### User Opt-Out: Device-Only Storage Mode

Users who select "Device-Only" storage mode at onboarding (or change to it in settings) will not have their receipt data sent to any cloud service, including Bedrock. For these users:
- Stage 1 (on-device OCR) operates normally.
- Stage 2 (cloud LLM refinement) is entirely skipped.
- Receipt data remains exclusively on the user's device.
- The user accepts the lower accuracy of on-device OCR as the tradeoff for maximum privacy.

This opt-out is a core GDPR user autonomy feature. The app clearly communicates the accuracy tradeoff when the user selects device-only mode, but respects their choice without degrading other functionality.

### Image Handling

Receipt images uploaded to S3 for cloud processing are encrypted at rest using SSE-KMS with a customer-managed key. Pre-signed URLs used for upload have a 10-minute expiry and are restricted by content type and size. Images are accessible only to the specific Lambda functions that require them for processing, through tightly scoped IAM policies. No image is ever made publicly accessible.

### Personally Identifiable Information

Receipt images and extracted data may contain personally identifiable information (PII) including names, addresses, partial payment card numbers, and loyalty program identifiers. The application does not perform PII detection or redaction on receipt images before sending them to Bedrock, as doing so would degrade extraction accuracy. Instead, the privacy protection relies on:
- Bedrock's no-storage, no-training guarantee.
- Encryption at rest and in transit for all stored data.
- User-controlled data deletion (account deletion triggers a full cascade wipe across Cognito, DynamoDB, and S3).
- KMS key-based crypto-shredding as the ultimate deletion mechanism.

---

## Future: LLM Natural Language Search (v1.5)

A natural language search capability is planned for the v1.5 release but is explicitly not implemented in v1.0. This section describes the intended approach for planning purposes.

### Concept

The v1.0 search experience is keyword-based: users type store names, product descriptions, or amounts into the search bar, and the app performs full-text search (FTS5) and filter-based queries against the local Drift database and, when online, against DynamoDB.

In v1.5, the search bar will gain natural language understanding. Users will be able to type or speak queries in conversational language, such as:
- "How much did I spend at IKEA last month?"
- "Show me all electronics purchases over 100 euros this year."
- "When does my laptop warranty expire?"
- "Find the receipt for the coffee machine I bought in December."

### Approach

The natural language search will use Bedrock to interpret the user's query and translate it into a structured filter that the app can execute against its data stores.

The flow:
1. User enters a natural language query in the search bar.
2. The app sends the query text to a dedicated API endpoint (e.g., `POST /search/interpret`).
3. A Lambda function sends the query to Bedrock (Haiku 4.5 is likely sufficient for query interpretation).
4. The LLM interprets the query and returns a structured filter object containing parameters such as store name, date range, amount range, category, and sort order.
5. The Lambda function validates the structured filter and either executes it against DynamoDB (returning results directly) or returns the filter to the client for local execution against the Drift database.
6. Results are displayed to the user.

This approach keeps the LLM role narrow and well-defined: it translates natural language into structured queries. The actual data retrieval is performed by the existing database query infrastructure, ensuring consistency, performance, and security (the LLM never directly accesses the database).

### Why Deferred to v1.5

Natural language search adds meaningful complexity to the API surface, requires careful prompt engineering to handle diverse query phrasings, and introduces a cloud dependency for a search feature that currently works fully offline. The v1.0 focus is on perfecting the core capture, sync, and warranty tracking experience. Natural language search is a polish feature that enhances an already-functional search system, making it a natural candidate for the v1.5 release.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*

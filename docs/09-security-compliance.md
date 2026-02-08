# 09 -- Security & Compliance

**Document**: Security Architecture and GDPR Compliance
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Security Architecture Overview](#security-architecture-overview)
2. [Authentication and Authorization](#authentication-and-authorization)
3. [Data Encryption](#data-encryption)
4. [Image Security](#image-security)
5. [GDPR Compliance](#gdpr-compliance)
6. [Account Deletion Cascade](#account-deletion-cascade)
7. [S3 Bucket Security Configuration](#s3-bucket-security-configuration)
8. [Security Monitoring](#security-monitoring)
9. [Privacy Policy Requirements](#privacy-policy-requirements)
10. [Threat Model](#threat-model)

---

## Security Architecture Overview

Receipt & Warranty Vault handles sensitive financial data -- purchase amounts, merchant names, warranty terms, and photographic evidence of transactions. The security architecture is designed to protect this data at every layer, from the moment it enters the app to its eventual deletion.

### Defense in Depth

The security posture is built on the principle of defense in depth: no single layer is trusted to provide complete protection. Instead, multiple overlapping layers of security ensure that the compromise of any one layer does not expose user data.

At the outermost layer, network security enforces encrypted transport for every byte of data that leaves the device. Inside the network perimeter, authentication gates verify the identity of every request before it reaches any backend resource. Behind authentication, authorization logic ensures that each user can only access their own data -- never another user's receipts, images, or account details. At the storage layer, encryption at rest renders data unreadable even if the underlying storage medium is compromised. On the device itself, an encrypted local database and secure credential storage protect data even if the physical device is lost or stolen.

Each layer operates independently. A breach at the network layer (for example, a compromised TLS certificate) does not grant access to user data because the authentication layer still stands. A compromised authentication token does not expose other users' data because the authorization layer enforces strict per-user isolation. A stolen device does not reveal stored data because the local database is encrypted with AES-256 and the encryption key is stored in the platform's secure enclave.

### Zero-Trust Approach

The architecture follows a zero-trust model: every request is authenticated and authorized, regardless of its origin. There are no trusted internal networks, no pre-authorized service accounts with broad access, and no implicit trust between components.

Every API call to the backend passes through an API Gateway Cognito authorizer that validates the JWT token attached to the request. The userId is extracted from the token's claims on the server side -- it is never accepted from the client request body, query parameters, or headers. This eliminates an entire class of authorization bypass vulnerabilities where a malicious client could attempt to access another user's data by spoofing a userId.

The DynamoDB table's partition key structure (PK = USER#{userId}) creates a natural tenant boundary. Combined with server-side userId extraction from the authenticated token, it is architecturally impossible for one user's API call to read or modify another user's data.

### Encryption Everywhere

Data is encrypted both in transit and at rest, with no exceptions.

**In transit**, all communication between the mobile app and AWS services is conducted over HTTPS using TLS 1.2 or higher. This includes API Gateway calls, S3 image uploads and downloads, and Cognito authentication flows. The S3 bucket policy explicitly denies any request that does not use HTTPS, ensuring that even misconfigured clients cannot transmit data in plaintext.

**At rest**, three distinct encryption mechanisms protect stored data:

- The local Drift database on the device uses SQLCipher with AES-256 encryption, rendering the SQLite file unreadable without the decryption key.
- S3 image storage uses server-side encryption with AWS KMS (SSE-KMS) using a Customer-Managed Key (CMK), providing both encryption and a cryptographic deletion capability.
- DynamoDB uses AWS-owned encryption (the default AES-256 encryption that AWS manages transparently), protecting receipt metadata at rest.

---

## Authentication and Authorization

### Cognito User Pool

User authentication is handled by AWS Cognito User Pool, configured on the Lite tier (free for up to 10,000 monthly active users). Cognito provides a managed, battle-tested authentication service that eliminates the need to build, maintain, and secure a custom identity system.

Three sign-in methods are supported in v1:

- **Email and password**: The standard credential-based flow. Cognito enforces password complexity requirements and handles secure password storage (bcrypt hashing) entirely on the server side.
- **Google Sign-In**: Federated identity through Google's OAuth 2.0 provider, allowing users to authenticate with their existing Google account without creating a new password.
- **Apple Sign-In**: Federated identity through Apple's authentication service. This is mandatory for any iOS app that offers third-party social login (per Apple App Store policy).

All three methods converge to the same Cognito User Pool, producing identical JWT tokens regardless of the sign-in method used. The app does not need to differentiate between authentication providers after the initial sign-in flow.

### JWT Token Lifecycle

Cognito issues three tokens upon successful authentication:

| Token | Purpose | Lifetime |
|-------|---------|----------|
| **Access Token** | Authorizes API calls to the backend | 1 hour |
| **ID Token** | Contains user profile claims (userId, email) | 1 hour |
| **Refresh Token** | Obtains new access and ID tokens without re-authentication | 30 to 90 days (configurable) |

The Amplify Flutter Gen 2 SDK manages the entire token lifecycle transparently. When the access token expires (after 1 hour), Amplify automatically uses the refresh token to obtain a new access token without any user interaction or app-level logic. The user is only prompted to re-authenticate when the refresh token itself expires (after 30 to 90 days, depending on configuration) or when it is explicitly revoked.

This transparent refresh mechanism is critical for the offline-first architecture. A user who captures receipts offline for several hours will have valid tokens waiting when connectivity is restored, because Amplify handles the refresh seamlessly in the background.

### API Gateway Authorization

Every API endpoint is protected by an API Gateway Cognito authorizer. This authorizer validates the JWT access token attached to each request before the request reaches the Lambda function. Invalid, expired, or missing tokens result in an immediate 401 Unauthorized response -- the Lambda function is never invoked, and no backend resources are consumed.

The critical security property of this design is that the userId is extracted from the validated token's claims on the server side. The Lambda function reads the userId from the authorizer context (event.requestContext.authorizer.claims.sub), not from any client-provided field. This means:

- A client cannot impersonate another user by sending a different userId in the request body.
- A client cannot escalate access by modifying request parameters.
- The only way to access a user's data is to possess a valid, unexpired token issued by Cognito for that specific user.

### Strict Tenant Isolation

There are no shared resources between users. Every piece of data in the system is scoped to a single user through the DynamoDB partition key (PK = USER#{userId}) and the S3 object key prefix (users/{userId}/). This is not a filter applied at the application layer -- it is a structural property of the data model itself.

A query for receipts always includes the userId in the partition key. There is no API endpoint, no DynamoDB query pattern, and no S3 access path that returns data across multiple users. The single-table DynamoDB design with user-scoped partition keys makes cross-tenant data access architecturally impossible through normal query operations.

### Optional App Lock

Separate from Cognito authentication, the app offers an optional biometric or PIN lock via the local_auth Flutter package. This app lock is prompted during onboarding but is not mandatory.

The app lock serves a different security purpose than Cognito authentication. While Cognito protects cloud resources and API access, the app lock protects the device-local experience. If a user's phone is unlocked and someone else picks it up, the app lock prevents casual access to the receipt vault without requiring a full Cognito re-authentication.

Key properties of the app lock:

- It works entirely offline (no network required for biometric or PIN verification).
- It does not replace Cognito authentication -- both systems operate independently.
- It protects access to the app's local encrypted database and cached images.
- It uses the device's native biometric capabilities (Face ID, Touch ID, fingerprint sensor, or device PIN/pattern).
- It is separate from the SQLCipher database encryption key -- the app lock gates access to the app interface, while SQLCipher gates access to the data file itself.

---

## Data Encryption

### Encryption at Rest

#### Local Database: Drift + SQLCipher (AES-256)

The local database on each user's device is a SQLite file encrypted with SQLCipher using AES-256 encryption. SQLCipher is a widely audited, open-source extension to SQLite that provides transparent, full-database encryption. Every page of the database file is encrypted, including the schema, indices, and all data content.

The encryption key is derived from the user's credentials and stored in flutter_secure_storage, which maps to platform-specific secure storage mechanisms:

- **iOS**: The key is stored in the Keychain, which is hardware-backed by the Secure Enclave on devices that support it. Keychain items are encrypted with a key derived from the device passcode and the device's unique hardware key.
- **Android**: The key is stored in EncryptedSharedPreferences, which uses the Android Keystore system. The Keystore is backed by hardware security modules (Trusted Execution Environment or StrongBox) on supported devices.

This means that even if someone extracts the SQLite file from the device's file system (for example, from an unencrypted device backup), the file is unreadable without the encryption key, which is stored in a hardware-backed secure enclave that cannot be extracted through software means.

#### S3 Images: SSE-KMS with Customer-Managed Key

All receipt images stored in S3 are encrypted using server-side encryption with AWS Key Management Service (SSE-KMS). A Customer-Managed Key (CMK) is used rather than the default AWS-managed key, providing two critical capabilities:

- **Key policy control**: The CMK's key policy restricts which IAM roles and services can use the key for encryption and decryption. Only the application's Lambda functions and the S3 service itself have permission to use the key.
- **Crypto-shredding**: The CMK can be scheduled for deletion, which renders all data encrypted with that key permanently unreadable. This provides an ultimate GDPR erasure guarantee (discussed in the GDPR section below).

**Bucket Keys** are enabled to reduce the number of KMS API calls. Without Bucket Keys, every S3 PUT and GET operation would make a separate KMS API call, incurring both latency and cost. With Bucket Keys, S3 generates a bucket-level key from the CMK and uses it for a time-limited period, dramatically reducing KMS API calls while maintaining the same security properties.

**Automatic annual key rotation** is enabled on the CMK. AWS automatically creates a new key version each year and uses it for new encryption operations, while retaining all previous key versions to decrypt data encrypted with older versions. This rotation is transparent -- no application changes are required, and no data re-encryption is needed.

#### DynamoDB: AWS-Owned Encryption

DynamoDB tables are encrypted at rest by default using AWS-owned keys. This is AES-256 encryption managed entirely by AWS, with no customer configuration required. While this does not provide the same crypto-shredding capability as a CMK (because the key is shared across AWS customers), it does protect against physical storage media theft or unauthorized access to the underlying storage infrastructure.

For the receipt metadata stored in DynamoDB, AWS-owned encryption is sufficient because the account deletion cascade (described below) performs explicit item-by-item deletion from DynamoDB, making crypto-shredding unnecessary for this data store.

### Encryption in Transit

All data in transit is encrypted using TLS 1.2 or higher. This applies to every network communication path in the system:

- **API calls**: All requests from the mobile app to API Gateway are over HTTPS. API Gateway does not expose an HTTP endpoint -- only HTTPS is available.
- **S3 uploads and downloads**: The S3 bucket policy includes an explicit deny statement for any request where aws:SecureTransport is false, ensuring that even if a pre-signed URL were somehow generated without HTTPS, the request would be rejected by S3.
- **Pre-signed URLs**: All pre-signed URLs generated by the backend use the HTTPS protocol. These URLs are time-limited (10-minute expiry) and cannot be modified to use HTTP without invalidating the signature.
- **CloudFront distribution**: The CloudFront distribution for thumbnail delivery is configured to enforce HTTPS for both viewer-facing connections (between the user's device and CloudFront) and origin connections (between CloudFront and S3).

---

## Image Security

Receipt images are the most sensitive data the app handles -- they contain merchant names, purchase amounts, dates, potentially partial payment card numbers, and in some cases personally identifiable information. The image security model addresses privacy, access control, and attack surface reduction.

### GPS EXIF Data Stripping

Before any image is uploaded to the cloud, the app strips GPS EXIF metadata from the image file. Receipt photos taken with a phone camera embed the device's GPS coordinates in the image's EXIF data, which would reveal the exact location where the receipt was captured -- typically a store, a home, or a workplace. This is a significant privacy risk that serves no functional purpose for receipt management.

The stripping occurs on-device before upload, ensuring that GPS data never leaves the user's device. Other non-sensitive EXIF data (such as image dimensions and orientation) may be retained if it aids in image processing.

### Pre-Signed URL Security

Direct access to S3 is never granted to the mobile app. Instead, the backend generates pre-signed URLs with strict constraints:

- **10-minute expiry**: Each pre-signed URL is valid for only 10 minutes from generation. After expiry, the URL returns an access denied error. This limits the window of opportunity if a URL is intercepted or leaked.
- **Content-type restriction**: Upload pre-signed URLs specify the expected content type (image/jpeg), preventing a malicious client from uploading non-image files (executables, scripts, or other potentially harmful content) through a valid pre-signed URL.
- **Size restriction**: Upload pre-signed URLs include a content-length condition that limits the maximum file size, preventing abuse through excessively large uploads that could consume storage quota or incur unexpected costs.
- **HTTPS only**: All pre-signed URLs use the HTTPS protocol, and the S3 bucket policy rejects non-HTTPS requests regardless.

### S3 Bucket Access Controls

The S3 bucket that stores receipt images is configured with the strictest access controls:

- **Block All Public Access**: All four public access block settings are enabled (BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets). This is a hard guardrail that prevents any configuration change from accidentally making the bucket or its objects publicly accessible.
- **No static website hosting**: The bucket is not configured for static website hosting, eliminating an access path that could bypass standard S3 access controls.
- **Bucket policy**: The bucket policy uses explicit deny statements to enforce TLS and KMS encryption requirements, and uses allow statements restricted to specific IAM roles (the Lambda execution role and the CloudFront OAC role).

### CloudFront with Origin Access Control

Thumbnail images are served through a CloudFront distribution configured with Origin Access Control (OAC). OAC is AWS's recommended method for restricting S3 access to CloudFront, replacing the older Origin Access Identity (OAI) approach.

With OAC configured, the S3 bucket does not need to be publicly accessible -- CloudFront authenticates to S3 using a service-level credential that is managed by AWS. Users receive thumbnails through CloudFront's edge locations, benefiting from caching and low latency, while the S3 bucket remains completely private.

### Image Compression and OCR Preservation

Receipt images are compressed to JPEG at 85% quality before upload. This compression level was chosen specifically to balance two competing requirements:

- **Storage efficiency**: Compression reduces each receipt image from a typical 4-8 MB camera output to approximately 1-2 MB, reducing S3 storage costs and upload bandwidth.
- **OCR readability**: The 85% JPEG quality level preserves enough detail for both on-device OCR (ML Kit and Tesseract) and cloud LLM extraction (Bedrock Claude Haiku 4.5) to accurately read text from the compressed image. Lower quality levels risk introducing compression artifacts that degrade OCR accuracy, particularly for small text and low-contrast receipts.

---

## GDPR Compliance

Receipt & Warranty Vault applies the General Data Protection Regulation (GDPR) as its global privacy standard. This is not limited to EU users -- every user, regardless of geographic location, receives the full protection of GDPR principles and rights. This decision simplifies the compliance architecture (one standard applied everywhere) and ensures that the app meets the strictest consumer privacy requirements globally, which also covers the essential requirements of other regulations such as CCPA and LGPD.

### GDPR Principles Applied

#### Lawful Basis: Consent

The lawful basis for processing user data is explicit consent, obtained during the sign-up flow. Users are presented with a clear, non-legalese explanation of what data the app collects, why it collects it, and how it is processed. Consent is freely given (the user can choose device-only mode to avoid cloud processing entirely), specific (limited to receipt and warranty management), informed (the processing purposes are explained), and unambiguous (requires an affirmative action).

#### Purpose Limitation

Data is collected and processed exclusively for receipt and warranty management. User data is never used for advertising, profiling, analytics beyond basic app functionality, or any purpose unrelated to the core product. The LLM processing through AWS Bedrock is explicitly covered by AWS's contractual guarantee that user data is not used for model training.

#### Data Minimization

The app collects only the data necessary for its stated purpose. Receipt images are compressed and GPS EXIF data is stripped before upload -- the GPS coordinates serve no purpose for receipt management and are therefore not collected. The app does not access the user's contacts, calendar, browsing history, or any other device data beyond camera access (for capture) and gallery access (for import).

#### Storage Limitation

Data is not retained indefinitely after deletion. Soft-deleted receipts are recoverable for 30 days (via S3 versioning with NoncurrentVersionExpiration), after which they are permanently removed. When a user deletes their account, a hard cascade wipe removes all data immediately -- there is no retention period for account deletion.

#### Accuracy

Users can edit all receipt fields at any time. If the OCR or LLM extraction produces an incorrect merchant name, date, total, or warranty period, the user can correct it immediately. The system tracks which fields the user has manually edited (via the userEditedFields array) and respects those corrections in future sync operations, ensuring that user-provided accurate data is never overwritten by automated processing.

#### Integrity and Confidentiality

As described in the Data Encryption section, all user data is encrypted at rest (SQLCipher AES-256 on device, SSE-KMS in S3, AWS-owned encryption in DynamoDB) and in transit (TLS 1.2+ everywhere). Access controls enforce strict per-user isolation, and the zero-trust architecture ensures that every request is authenticated and authorized.

### User Rights Implementation

GDPR grants users specific rights over their personal data. The following describes how each right is implemented in Receipt & Warranty Vault.

#### Right to Access (Article 15)

Users can request a complete export of all their data through the **GET /user/export** API endpoint. This endpoint triggers a process that:

- Retrieves all receipt metadata from DynamoDB for the authenticated user.
- Retrieves all receipt images from S3 for the authenticated user.
- Packages the data into a downloadable ZIP file containing structured data (JSON and CSV formats) alongside the original receipt images.

The export is comprehensive: it includes every receipt, every field, every image, and all user preferences and settings associated with the account.

#### Right to Rectification (Article 16)

Users can edit any receipt field at any time through the standard receipt editing interface. There are no locked or read-only fields -- even LLM-extracted data can be overridden by the user. The userEditedFields tracking mechanism ensures that user corrections are preserved across sync operations and are not overwritten by subsequent LLM processing.

#### Right to Erasure (Article 17)

Users can delete their account through the **DELETE /user/account** endpoint, which triggers the full Account Deletion Cascade described in the next section. This is a hard wipe -- all user data is permanently removed from Cognito, DynamoDB, and S3 (including all object versions). There is no recovery after account deletion.

Individual receipts can also be deleted. Soft deletion moves the receipt to a 30-day recovery window (implemented via S3 versioning). After 30 days, the noncurrent version expires automatically and the data is permanently removed.

#### Right to Data Portability (Article 20)

The data export endpoint provides data in standard, machine-readable formats:

- **JSON**: Structured receipt data with all fields, suitable for import into other systems.
- **CSV**: Tabular receipt data, openable in any spreadsheet application.
- **Images**: Original receipt images in their stored format (JPEG).

These formats are interoperable and not locked to any proprietary system.

#### Right to Restrict Processing (Article 18)

Users can switch their storage mode to **"Device Only"** at any time. In device-only mode, no data is transmitted to the cloud for processing. Receipts are stored exclusively in the local encrypted database, images remain on the device's file system, and the sync engine is disabled. This effectively restricts all server-side processing while preserving full app functionality offline.

#### Right to Object (Article 21)

Users can object to cloud LLM processing by operating in device-only mode. In this mode, receipt extraction relies solely on on-device OCR (ML Kit and Tesseract) without any cloud LLM refinement through Bedrock. The user retains full control over whether their receipt data is processed by cloud-based artificial intelligence.

### Data Processing and Residency

#### AWS Bedrock

The LLM processing of receipt images through AWS Bedrock (Claude Haiku 4.5 and Sonnet 4.5) operates under AWS's contractual guarantee that:

- User data sent to Bedrock for inference is **not stored** by AWS after the response is returned.
- User data is **not used for model training** or improvement.
- Processing occurs within the specified AWS region (eu-west-1).

This guarantee is part of AWS's service terms for Bedrock and is a critical element of the GDPR compliance posture. Receipt images and extracted text are transient inputs to the model -- they are processed, the structured output is returned, and the input data is discarded.

#### Data Residency

All persistent data storage is located in the **eu-west-1 (Ireland)** AWS region:

- **S3**: Receipt images and thumbnails are stored in an S3 bucket in eu-west-1.
- **DynamoDB**: Receipt metadata is stored in a DynamoDB table in eu-west-1.
- **Cognito**: User identity data is managed by a Cognito User Pool in eu-west-1.

There is **no cross-region data replication** in v1. All data remains within the EU, satisfying GDPR data residency requirements without the need for Standard Contractual Clauses or other cross-border transfer mechanisms.

#### Cross-Region Considerations

Multi-region deployment is deferred to v2.0. When implemented, it will require additional GDPR analysis for data transfers between regions, potentially including the use of AWS inter-region data transfer agreements and updated privacy notices.

### Crypto-Shredding

Crypto-shredding is the practice of rendering encrypted data permanently unreadable by destroying the encryption key rather than the data itself. Receipt & Warranty Vault's use of SSE-KMS with a Customer-Managed Key (CMK) enables this capability.

If the CMK is scheduled for deletion in KMS, all data encrypted with that key in S3 becomes permanently unreadable after the mandatory 7-to-30-day waiting period. This includes all receipt images and thumbnails for all users. Crypto-shredding serves as the ultimate GDPR erasure guarantee -- even if some S3 objects were missed during a normal deletion cascade, the destruction of the encryption key ensures that the data is cryptographically irretrievable.

In normal operations, crypto-shredding is not used for individual user deletions (the account deletion cascade handles that through explicit data deletion). Crypto-shredding is reserved as a last-resort mechanism for scenarios such as a complete service shutdown or a regulatory order requiring irrecoverable data destruction.

---

## Account Deletion Cascade

When a user requests account deletion, a comprehensive cascade process ensures that all user data is permanently removed from every service in the system. This process is irreversible.

### Step 1: Deletion Request and Confirmation

The user initiates account deletion through the app's settings interface. A confirmation token is required to proceed, preventing accidental deletions. The confirmation flow requires the user to explicitly acknowledge that deletion is permanent and cannot be undone.

### Step 2: Lambda Trigger

The confirmed deletion request triggers a dedicated Lambda function that orchestrates the cascade. This Lambda function runs with an IAM role that has the specific permissions needed to delete data from each service.

### Step 3: Cognito User Deletion

The user's record is deleted from the Cognito User Pool. This immediately invalidates all existing tokens (access, ID, and refresh) for that user. From this moment forward, the user cannot authenticate or make any API calls. Any in-flight requests that were already past the API Gateway authorizer will still complete, but no new requests can be initiated.

### Step 4: DynamoDB Data Deletion

All items in the DynamoDB table with the partition key PK = USER#{userId} are deleted in a batch operation. This includes all receipt metadata, category configurations, and any other user-scoped data. The deletion is performed using BatchWriteItem operations, processing up to 25 items per batch until all items are removed.

### Step 5: S3 Object Deletion

All objects stored under the S3 key prefix users/{userId}/ are deleted, including all object versions. This is critical because S3 versioning is enabled for soft delete support -- a simple delete operation would only create a delete marker without removing the underlying data. The cascade explicitly deletes all versions of all objects, ensuring no receipt images or thumbnails remain in any version state.

### Step 6: KMS Key Handling

No per-user KMS key deletion is needed because the CMK is shared across all users. The user's encrypted data has already been removed from S3 in Step 5. The shared CMK continues to serve other users' encryption needs.

### Step 7: SNS Cleanup

All SNS endpoints (push notification subscriptions) associated with the user's devices are unsubscribed. This prevents any future push notifications from being sent to devices previously associated with the deleted account.

### Step 8: CloudWatch Log Retention

CloudWatch logs that contain the user's userId in log entries are retained for 30 days for audit purposes and then automatically expire based on the log group's retention policy. This 30-day retention is necessary for operational monitoring (detecting and diagnosing any issues with the deletion process itself) and is permissible under GDPR's legitimate interest basis for security logging.

---

## S3 Bucket Security Configuration

The S3 bucket that stores receipt images and thumbnails is configured with the following security controls:

### Block All Public Access

All four public access block settings are enabled:

- **BlockPublicAcls**: Rejects any PUT request that includes a public ACL.
- **IgnorePublicAcls**: Ignores any existing public ACLs on the bucket or its objects.
- **BlockPublicPolicy**: Rejects any bucket policy that grants public access.
- **RestrictPublicBuckets**: Restricts access to the bucket to only AWS service principals and authorized users, even if a public policy exists.

These settings are account-level guardrails. Even if a misconfigured IAM policy or an errant deployment script attempts to make the bucket public, these blocks prevent it.

### Bucket Policy

The bucket policy enforces three critical security requirements:

1. **TLS enforcement**: An explicit deny statement rejects any request where the condition aws:SecureTransport is false, ensuring all communication is encrypted in transit.
2. **KMS encryption enforcement**: An explicit deny statement rejects any PUT request that does not specify SSE-KMS encryption with the designated CMK, ensuring all objects are encrypted at rest with the correct key.
3. **IAM role restriction**: Allow statements are scoped to specific IAM roles -- the Lambda execution role (for generating pre-signed URLs and processing images) and the CloudFront OAC service principal (for serving thumbnails). No other principals can access the bucket.

### Versioning

S3 versioning is enabled on the bucket to support the 30-day soft delete recovery feature. When a receipt is soft-deleted, the image is "deleted" by creating a delete marker in S3, but the previous version remains accessible for recovery. This provides a safety net against accidental deletion without requiring a separate backup system.

### Lifecycle Rules

A lifecycle policy is configured with **NoncurrentVersionExpiration** set to 30 days. After a receipt image is soft-deleted and 30 days have passed, the noncurrent version is automatically and permanently removed by S3. This ensures that soft-deleted data does not persist indefinitely, aligning with the GDPR storage limitation principle.

### Access Logging

S3 access logging is enabled, with logs delivered to a separate logging bucket. These logs record every access request to the receipt image bucket, including the requester's identity, the operation performed, the object accessed, and the response status. Access logs are essential for security auditing, incident investigation, and compliance verification.

### Object Lock

Object Lock is not enabled on this bucket. Versioning provides sufficient protection for the soft delete use case, and Object Lock's immutability guarantees are not required for receipt images. Object Lock would also complicate the account deletion cascade, which needs to delete all object versions immediately.

---

## Security Monitoring

### CloudTrail

AWS CloudTrail is enabled for all API calls across the AWS account. Every management event (IAM changes, S3 bucket configuration changes, KMS key policy modifications) and data event (S3 object access, Lambda invocations) relevant to the receipt vault is logged. CloudTrail logs are stored in a dedicated S3 bucket with integrity validation enabled, ensuring that logs cannot be tampered with without detection.

### CloudWatch Alarms

CloudWatch alarms are configured to detect and alert on anomalous activity:

- **Unusual API patterns**: Alerts when the number of API Gateway requests from a single user exceeds expected thresholds, which could indicate credential abuse or automated scraping.
- **High error rates**: Alerts when the percentage of 4xx or 5xx responses from API Gateway or Lambda exceeds normal levels, which could indicate an attack or a system malfunction.
- **Throttling events**: Alerts when DynamoDB or Lambda throttling occurs, which could indicate a denial-of-service attempt or a need to adjust capacity settings.
- **Authentication failures**: Alerts when Cognito reports an unusually high number of failed authentication attempts, which could indicate a credential stuffing or brute force attack.

### KMS Key Usage Monitoring

CloudTrail logs all KMS API calls, including Encrypt, Decrypt, and GenerateDataKey operations. Monitoring these logs allows detection of unusual key usage patterns -- for example, a sudden spike in decrypt operations could indicate unauthorized data access attempts.

### S3 Access Log Analysis

S3 access logs are periodically analyzed (manually in v1, with potential automation in v1.5) to identify unusual access patterns such as:

- Requests from unexpected IP addresses or geographic regions.
- High-volume downloads that could indicate data exfiltration.
- Access to objects belonging to users who have been deleted (which should not exist).
- Requests using expired or invalid pre-signed URLs (which should be rejected but may indicate URL leakage).

---

## Privacy Policy Requirements

A comprehensive privacy policy must be created and published before the app's public launch. While not required for the 5-person testing phase (where testers are known team members), the privacy policy is a legal prerequisite for App Store and Google Play Store submissions and for GDPR compliance.

### Required Content

The privacy policy must clearly and accessibly cover the following topics:

- **Data collected**: Enumerate all categories of personal data processed by the app -- email address, receipt images, purchase data (merchant, date, total, items), warranty information, device identifiers for push notifications, and usage analytics (if any).
- **Processing purposes**: Explain why each category of data is collected and how it is used -- receipt management, warranty tracking, OCR and LLM extraction, push notifications, and sync.
- **Third parties**: Disclose all third-party services that process user data, specifically AWS (Bedrock, S3, DynamoDB, Cognito, Lambda) and any analytics providers. Include AWS's data processing guarantees (no storage, no training for Bedrock).
- **Retention periods**: Specify how long data is retained -- active account data for the lifetime of the account, soft-deleted data for 30 days, CloudWatch logs for 30 days, and immediate hard deletion on account deletion.
- **User rights**: Describe how users can exercise their GDPR rights (access, rectification, erasure, portability, restriction, objection) and provide step-by-step instructions for each.
- **Contact information**: Provide a contact email address or form for privacy inquiries and data subject access requests.

### Language Availability

The privacy policy must be available in both **English** and **Greek**, matching the app's v1 language support. Both language versions must be legally equivalent and equally comprehensive.

### Accessibility within the App

The privacy policy must be accessible from two locations:

- **Sign-up flow**: Presented to new users during account creation, linked directly from the consent checkbox.
- **App settings**: Available at any time from the Settings tab, allowing users to review the policy after sign-up.

---

## Threat Model

The following threat model identifies the key risks to user data and the mitigations in place for each.

### Threat 1: Stolen or Lost Device

**Risk**: An attacker gains physical access to the user's device and attempts to access stored receipt data.

**Mitigations**:

- **App lock (biometric/PIN)**: If enabled, the app requires biometric authentication or a PIN before displaying any content. The attacker would need the user's fingerprint, face, or PIN to access the app.
- **SQLCipher encryption**: Even if the attacker bypasses the app lock (for example, by extracting the SQLite file from the file system), the database is encrypted with AES-256. The encryption key is not stored in the database file.
- **flutter_secure_storage**: The database encryption key is stored in the platform's secure storage (Keychain on iOS, EncryptedSharedPreferences on Android), which is backed by hardware security modules. Extracting the key requires either the device passcode or a hardware-level attack.
- **Token security**: Cognito tokens are stored in flutter_secure_storage, not in plaintext files. A stolen device does not grant easy access to the user's cloud account.

**Residual risk**: If the device passcode is known to the attacker and the app lock is not enabled, the attacker has access to the app. Enabling app lock is recommended but not mandatory.

### Threat 2: Credential Compromise

**Risk**: An attacker obtains the user's email and password (through phishing, password reuse from a breached service, or social engineering) and uses them to access the user's account.

**Mitigations**:

- **Cognito security features**: Cognito provides built-in protections against credential-based attacks, including advanced security features (adaptive authentication, compromised credential detection) that can be enabled.
- **Refresh token rotation**: Cognito can be configured to rotate refresh tokens on use, invalidating the previous refresh token. This limits the window of access for a stolen refresh token.
- **Optional MFA**: Multi-factor authentication can be offered as an additional security layer (considered for v1.5), requiring a second factor beyond the password.
- **Social login**: Users who sign in with Google or Apple benefit from those providers' security features (Google's account security, Apple's privacy-focused authentication) without exposing a password to the receipt vault app.

**Residual risk**: Without MFA, a compromised password grants full account access. MFA support should be prioritized for the v1.5 release.

### Threat 3: Man-in-the-Middle Attack

**Risk**: An attacker intercepts network communication between the app and AWS services, potentially reading or modifying data in transit.

**Mitigations**:

- **TLS everywhere**: All network communication uses TLS 1.2 or higher. The attacker would need to compromise the TLS session, which requires either a forged certificate accepted by the device's trust store or a break in the TLS protocol itself.
- **Certificate pinning (considered for v1.5)**: Pinning the expected server certificate or public key in the app would prevent even a compromised certificate authority from enabling a man-in-the-middle attack. This is not implemented in v1 due to the operational complexity of certificate rotation but is under consideration for v1.5.

**Residual risk**: Without certificate pinning, an attacker who can install a rogue root certificate on the user's device (for example, through a compromised enterprise MDM profile) could intercept traffic. Certificate pinning would mitigate this.

### Threat 4: Malicious Image Upload

**Risk**: An attacker uploads a crafted file (disguised as an image) through the receipt capture flow, attempting to exploit vulnerabilities in the image processing pipeline.

**Mitigations**:

- **Content-type validation**: Pre-signed upload URLs specify the expected content type (image/jpeg). S3 rejects uploads that do not match the specified content type.
- **Size limits**: Pre-signed URLs include content-length conditions that reject uploads exceeding the maximum expected size for a receipt image.
- **Lambda processing sandbox**: Image processing (thumbnail generation, LLM extraction) runs in Lambda functions, which execute in isolated, ephemeral containers. Even if a malicious file triggered a vulnerability in an image processing library, the impact would be contained to a single Lambda invocation with limited IAM permissions and no persistent state.
- **Input validation**: The Lambda function validates the uploaded file's magic bytes and image headers before processing, rejecting files that are not valid JPEG images despite having the correct content-type header.

**Residual risk**: Zero-day vulnerabilities in image processing libraries (such as libjpeg or Pillow) could potentially be exploited. Keeping Lambda dependencies updated and monitoring for security advisories mitigates this risk.

### Threat 5: Token Theft

**Risk**: An attacker obtains a valid access token or refresh token, gaining the ability to make API calls as the user.

**Mitigations**:

- **Short-lived access tokens (1 hour)**: Access tokens expire after 1 hour, limiting the window of access for a stolen access token.
- **Secure storage**: Tokens are stored in flutter_secure_storage (Keychain/EncryptedSharedPreferences), not in plaintext or in easily accessible locations like SharedPreferences or local storage.
- **Refresh token rotation**: When enabled, using a refresh token to obtain new access tokens invalidates the previous refresh token. An attacker who steals a refresh token can use it only once before it becomes invalid.
- **Token revocation on account deletion**: Deleting the Cognito user immediately invalidates all tokens, including any that may have been stolen.

**Residual risk**: A token stolen within its validity window (up to 1 hour for access tokens) can be used to access the user's data. The short lifetime limits the impact.

### Threat 6: Data Breach (S3)

**Risk**: An attacker gains unauthorized access to the S3 bucket containing receipt images, either through a misconfigured bucket policy, a compromised IAM credential, or an AWS-level vulnerability.

**Mitigations**:

- **SSE-KMS encryption**: All objects are encrypted with a CMK. Even if the attacker accesses the raw S3 objects, they cannot read the data without access to the KMS key.
- **Bucket policy**: The bucket policy restricts access to specific IAM roles and enforces TLS and KMS encryption. There are no wildcard principals or overly permissive statements.
- **Block All Public Access**: The four public access block settings prevent any accidental or intentional public exposure of the bucket.
- **No public access paths**: The bucket does not have static website hosting, public ACLs, or any configuration that would allow unauthenticated access.
- **Crypto-shredding capability**: In the worst case, the CMK can be scheduled for deletion, rendering all S3 data permanently unreadable. This is the nuclear option but provides an irrecoverable erasure guarantee.

**Residual risk**: A compromised IAM role with both S3 and KMS permissions could decrypt and read data. Minimizing IAM permissions (least privilege) and monitoring CloudTrail for unusual role assumptions mitigate this risk.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*

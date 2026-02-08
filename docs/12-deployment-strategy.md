# 12 -- Deployment Strategy

**Document**: Deployment Strategy
**Version**: 1.0
**Status**: Pre-Implementation (Documentation Phase)
**Last Updated**: 2026-02-08

---

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Repository Structure (Monorepo)](#repository-structure-monorepo)
3. [Branching Strategy](#branching-strategy)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [Environments](#environments)
6. [Flutter Build and Release](#flutter-build-and-release)
7. [Infrastructure Deployment (CDK)](#infrastructure-deployment-cdk)
8. [Database Migrations](#database-migrations)
9. [Rollback Strategy](#rollback-strategy)
10. [Monitoring and Alerting (Post-Deploy)](#monitoring-and-alerting-post-deploy)

---

## Development Environment Setup

Every developer working on Receipt & Warranty Vault needs the following tools installed and configured on their workstation. The project spans a Flutter mobile application, a Python-based AWS Lambda backend, and AWS CDK infrastructure-as-code, so the toolchain reflects all three domains.

### Flutter and Dart

**Flutter SDK (stable channel)**: The primary development framework. Flutter must be installed from the stable channel to ensure production-ready tooling and libraries. The specific Flutter version will be pinned in the repository (via `.fvmrc` or equivalent) to ensure all developers and CI systems use the same SDK version.

**Dart SDK**: Bundled with Flutter. No separate installation is required. The Dart SDK version is determined by the Flutter SDK version and should not be independently upgraded.

### Mobile Platform Tooling

**Android Studio**: Required for Android development, even if the developer's primary editor is VS Code or another IDE. Android Studio provides the Android SDK, Android Emulator, and Gradle build system that Flutter depends on for Android compilation. The Android SDK must include platform tools for the minimum and target API levels defined during implementation.

**Xcode (macOS only)**: Required for iOS development. Xcode provides the iOS SDK, Simulator, and code signing infrastructure. Only developers on macOS can build and test iOS targets. Xcode Command Line Tools must be installed. CocoaPods is required for Flutter's iOS dependency management.

### AWS Tooling

**AWS CLI v2**: The command-line interface for interacting with AWS services. Must be configured with credentials that have access to the project's AWS account. Developers should use named profiles (e.g., `receipt-vault-dev`) to avoid conflicts with other AWS projects. Multi-factor authentication (MFA) is recommended for the AWS account.

**AWS CDK CLI**: The Cloud Development Kit command-line tool, used to synthesize, diff, and deploy infrastructure stacks. CDK is installed globally via npm (`npm install -g aws-cdk`). The CDK version should match the version specified in the infrastructure project's `requirements.txt` or `package.json`.

**SAM CLI (optional alternative)**: The AWS Serverless Application Model CLI can be used as an alternative for local Lambda development and testing. SAM provides `sam local invoke` and `sam local start-api` commands that allow developers to test Lambda functions locally against a simulated API Gateway. SAM is not required if the team uses CDK exclusively for deployment, but it is useful for rapid Lambda iteration.

### Language Runtimes

**Python 3.12**: The runtime for all Lambda functions. Python 3.12 must be installed locally for development, testing, and dependency management. Virtual environments (venv or virtualenv) should be used to isolate project dependencies. The specific Python patch version should match the Lambda runtime version configured in the CDK stacks.

**Node.js**: Required as the runtime for the AWS CDK CLI. CDK is a Node.js application even when CDK stacks are written in Python. The LTS version of Node.js is recommended. Node.js is also needed for any JavaScript-based build tooling or scripts.

### Version Control

**Git**: The version control system for the project. All code, infrastructure definitions, documentation, and configuration are tracked in a single Git repository (monorepo). Developers should have Git configured with their name, email, and preferred merge strategy.

---

## Repository Structure (Monorepo)

The project uses a monorepo architecture: a single Git repository containing the Flutter application, the backend Lambda functions, the infrastructure-as-code definitions, and all documentation. This structure ensures that changes spanning multiple layers (for example, a new API endpoint that requires a Lambda function, a CDK resource, and a Flutter API client update) can be committed, reviewed, and deployed atomically.

```
receipt-vault/
├── app/                              # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart                 # Application entry point
│   │   ├── core/                     # Shared utilities, constants, theme definition, error handling
│   │   ├── data/                     # Data layer: repositories, data sources, API clients, DTOs
│   │   ├── domain/                   # Domain layer: entities, use cases, business logic
│   │   ├── presentation/            # UI layer: screens, widgets, BLoC state management
│   │   └── l10n/                     # Localization files (English + Greek ARB files)
│   ├── test/                         # Unit tests and widget tests
│   ├── integration_test/            # Integration tests (full-flow device/emulator tests)
│   ├── android/                      # Android platform project (Gradle, manifests, icons)
│   ├── ios/                          # iOS platform project (Xcode, Info.plist, icons)
│   └── pubspec.yaml                  # Flutter dependencies and project metadata
├── backend/
│   ├── lambdas/                      # Lambda function source code (Python)
│   │   ├── receipt_crud/             # Create, read, update, delete receipt records
│   │   ├── ocr_refine/              # Cloud LLM refinement (Bedrock integration)
│   │   ├── sync_handler/            # Delta sync and full reconciliation logic
│   │   ├── thumbnail_generator/     # S3-triggered thumbnail creation (200x300px)
│   │   ├── warranty_checker/        # Daily warranty expiry check (EventBridge-triggered)
│   │   ├── weekly_summary/          # Weekly usage summary generation
│   │   ├── user_deletion/           # GDPR account deletion cascade
│   │   ├── export_handler/          # Single and batch receipt export
│   │   ├── category_handler/        # Custom category CRUD and default seeding
│   │   └── presigned_url_generator/ # S3 pre-signed URL generation for image upload/download
│   ├── layers/                       # Shared Lambda layers
│   │   └── common/                   # Shared utilities: Bedrock client wrapper, DynamoDB helpers,
│   │                                 #   response formatting, error handling, logging configuration
│   └── tests/                        # Backend unit tests (pytest)
├── infrastructure/
│   ├── cdk/                          # AWS CDK infrastructure-as-code (Python)
│   │   ├── app.py                    # CDK app entry point, instantiates all stacks
│   │   ├── stacks/
│   │   │   ├── auth_stack.py         # Cognito User Pool, identity providers, app client
│   │   │   ├── api_stack.py          # API Gateway REST API, routes, authorizers
│   │   │   ├── storage_stack.py      # DynamoDB table + GSIs, S3 buckets, KMS keys, CloudFront
│   │   │   ├── compute_stack.py      # Lambda functions, layers, EventBridge rules, SNS topics
│   │   │   └── monitoring_stack.py   # CloudWatch dashboards, alarms, metrics, budget alerts
│   │   └── requirements.txt         # Python dependencies for CDK stacks
│   └── scripts/                      # Deployment helper scripts (shell scripts for common operations)
├── docs/                             # Project documentation (this folder)
├── mockup/                           # Visual mockups (approved HTML mockup)
├── CLAUDE.md                         # Project memory and decision log
└── README.md                         # Repository overview and quickstart
```

### Layer Architecture (Flutter App)

The Flutter application follows Clean Architecture principles with three distinct layers:

**Core**: Contains shared utilities, constants, the theme definition (colors, typography, spacing), error types, and cross-cutting concerns that do not belong to any specific feature. This layer has no dependencies on domain or data layers.

**Domain**: Contains entities (pure Dart objects representing business concepts like Receipt, Warranty, Category), use cases (single-responsibility classes encapsulating business logic), and repository interfaces (abstract classes defining data contracts). The domain layer has no dependencies on Flutter, external packages, or infrastructure details.

**Data**: Contains repository implementations, data sources (local Drift database, remote API client via Dio, S3 image storage), data transfer objects (DTOs for JSON serialization), and mappers that convert between DTOs and domain entities. This layer implements the interfaces defined in the domain layer.

**Presentation**: Contains screens (full-page views), widgets (reusable UI components), and BLoC classes (state management). The presentation layer depends on the domain layer for entities and use cases, but never directly accesses the data layer.

### Lambda Function Organization

Each Lambda function is organized as an independent Python module within the `lambdas/` directory. Each function directory contains:
- A handler module with the Lambda entry point.
- A requirements file for function-specific dependencies (if any beyond the shared layer).
- Unit tests in the `backend/tests/` directory.

Shared code (Bedrock client wrapper, DynamoDB table access helpers, standardized response formatting, logging setup) is packaged as a Lambda layer in `layers/common/` and is attached to all functions that need it. This prevents code duplication while keeping each function's deployment package small.

---

## Branching Strategy

The project follows a Git Flow-inspired branching model adapted for the team's size and release cadence. The strategy provides clear separation between in-progress work, integration testing, and production-ready code.

### Branch Types

**main**: The production branch. Code on `main` is always in a deployable, release-ready state. Direct commits to `main` are prohibited; all changes reach `main` through merge from a `release/*` branch. This branch is protected with required pull request reviews and passing CI checks.

**develop**: The integration branch. Feature branches are merged into `develop` after code review and passing CI. `develop` represents the latest state of all completed work and is deployed to the staging environment. This branch is the base for all feature branches.

**feature/***: Feature branches, created from `develop`. Each feature branch corresponds to a single feature, user story, or logical unit of work. Naming convention: `feature/warranty-reminders`, `feature/ocr-pipeline`, `feature/sync-engine`. Feature branches are short-lived and are deleted after merging to `develop`.

**bugfix/***: Bug fix branches, created from `develop` (for non-urgent fixes) or from `main` (for hotfixes that must reach production immediately). Naming convention: `bugfix/date-parsing-error`, `bugfix/sync-conflict-crash`.

**release/***: Release candidate branches, created from `develop` when the team decides to prepare a release. Naming convention: `release/1.0.0`, `release/1.1.0`. Only bug fixes, documentation updates, and version number changes are committed to release branches. When the release is approved, the release branch is merged to both `main` (for production deployment) and back to `develop` (to incorporate any fixes made during the release process).

### Flow

The standard development flow proceeds as follows:

1. Developer creates `feature/my-feature` from `develop`.
2. Developer works on the feature, making commits to the feature branch.
3. Developer opens a pull request from `feature/my-feature` to `develop`.
4. CI runs automated checks (lint, test, CDK synth).
5. Code review is performed by at least one other team member.
6. PR is merged to `develop`. Feature branch is deleted.
7. When enough features are accumulated for a release, a `release/X.Y.Z` branch is created from `develop`.
8. Final testing and bug fixes are applied to the release branch.
9. Release branch is merged to `main` and tagged with the version number.
10. Release branch is merged back to `develop`.
11. Production deployment is triggered by the merge to `main`.

---

## CI/CD Pipeline

The CI/CD pipeline automates code quality checks, testing, building, and deployment. GitHub Actions is the recommended CI/CD platform, chosen for its native integration with GitHub repositories, generous free tier for private repositories, and support for both Linux and macOS runners (needed for iOS builds).

### On Pull Request to develop

When a pull request is opened or updated targeting the `develop` branch, the following checks run automatically. All checks must pass before the PR can be merged.

**Flutter Analyze (Lint)**: Runs `flutter analyze` on the app codebase to detect static analysis warnings and errors. This catches type errors, unused imports, deprecated API usage, and violations of the project's analysis options (defined in `analysis_options.yaml`). Any analysis issue causes the check to fail.

**Flutter Test (Unit and Widget Tests)**: Runs `flutter test` to execute all unit tests and widget tests in the `app/test/` directory. Tests must achieve the minimum code coverage threshold defined by the team (recommended: 80% for business logic, 60% for UI). Test failures cause the check to fail.

**Backend Python Tests (pytest)**: Runs `pytest` against the `backend/tests/` directory to execute all Lambda function unit tests. Tests validate handler logic, input parsing, error handling, and integration with AWS service mocks (using moto or unittest.mock). Test failures cause the check to fail.

**CDK Synth (Infrastructure Validation)**: Runs `cdk synth` to synthesize the CDK stacks into CloudFormation templates without deploying. This validates that the infrastructure definition is syntactically correct, all required parameters are provided, and resource configurations are valid. Synthesis failures cause the check to fail. This step catches infrastructure bugs before they reach any environment.

### On Merge to develop

When a PR is merged to `develop`, the pipeline runs all PR checks plus additional steps.

**All PR Checks**: Flutter analyze, Flutter test, Python tests, and CDK synth are repeated to ensure nothing was broken by the merge.

**Build Flutter APK (Debug)**: The pipeline builds a debug APK for Android to verify the build process succeeds with the merged code. This catches build-time issues (missing assets, incompatible dependencies, manifest errors) that are not detected by analysis or unit tests. The debug APK is published as a CI artifact for manual testing if needed.

**Deploy Backend to Staging**: The pipeline runs `cdk deploy` targeting the staging environment. This deploys all backend infrastructure (Lambda functions, API Gateway, DynamoDB table, S3 buckets, etc.) to a dedicated staging AWS environment that mirrors production configuration at lower scale. The staging deployment uses a separate CloudFormation stack name prefix (e.g., `ReceiptVaultStaging-`) to isolate it from production resources.

### On Merge to main (Release)

When a release branch is merged to `main`, the full release pipeline executes.

**All Checks**: Every check from the PR and develop pipelines runs first.

**Build Flutter APK (Release)**: A release-mode APK (or AAB for Google Play) is built with production signing credentials. The release build enables code minification (R8/ProGuard for Android), tree shaking, and AOT compilation for maximum performance. The signed artifact is published as a CI artifact and is ready for upload to Google Play.

**Build Flutter IPA (Release)**: A release-mode IPA is built for iOS using a macOS runner. The build uses the production provisioning profile and distribution certificate. The signed IPA is ready for upload to App Store Connect. This step requires a macOS CI runner (GitHub Actions provides macOS runners).

**CDK Deploy to Production**: The pipeline runs `cdk deploy` targeting the production environment in eu-west-1. Production deployment uses stricter approval settings (see Infrastructure Deployment section below).

**Tag Release**: The pipeline creates a Git tag with the semantic version number (e.g., `v1.0.0`) on the merge commit to `main`. This tag serves as an immutable reference point for the release.

---

## Environments

The project maintains three distinct environments, each serving a specific purpose in the development and release lifecycle.

### Local (Developer Machine)

**Purpose**: Day-to-day development, rapid iteration, and unit testing.

**Flutter App**: Runs on Android Emulator, iOS Simulator, or a physical device connected via USB. The app is configured to use local or mock backends.

**Local Database**: Drift (SQLite) runs natively on the emulator/simulator/device. No setup required beyond running the app.

**Backend Services (Mocked)**: For backend development and testing without deploying to AWS, developers use local substitutes:
- **DynamoDB Local**: A downloadable version of DynamoDB that runs on the developer's machine. It provides the same API as cloud DynamoDB but stores data locally. Installed via Docker or standalone JAR.
- **LocalStack**: An open-source tool that emulates AWS services (S3, Lambda, SNS, SQS, and others) on the developer's machine. Used for testing S3 interactions (image upload, thumbnail generation) and other service integrations without incurring AWS costs.
- Lambda functions can be tested using SAM CLI's `sam local invoke` command, which runs the function in a Docker container simulating the Lambda execution environment.

**Configuration**: The app uses environment-specific configuration files or build flavors to point to local endpoints (e.g., `http://localhost:8000` for DynamoDB Local, `http://localhost:4566` for LocalStack).

### Staging

**Purpose**: Integration testing, end-to-end testing, and pre-release validation in a real AWS environment.

**Infrastructure**: A full AWS deployment in eu-west-1, using the same CDK stacks as production but with a separate stack name prefix (`ReceiptVaultStaging-`). All resources (DynamoDB table, S3 buckets, Lambda functions, API Gateway, Cognito User Pool) are fully independent from production.

**Configuration Differences from Production**:
- DynamoDB: on-demand capacity (same as production at this scale).
- S3: Standard storage class (no Intelligent-Tiering optimization needed at staging volume).
- Lambda: Lower memory allocation where appropriate, to reduce cost.
- Cognito: Separate user pool with test accounts.
- Monitoring: Basic CloudWatch logging enabled, but no PagerDuty/alert integration.
- Budget: Separate AWS Budget alert at lower thresholds.

**Access**: The staging API endpoint is accessible only to the development team. It is not exposed to external testers.

**Data**: Staging uses synthetic test data. Real receipt images from production are never copied to staging.

### Production

**Purpose**: Serving real users (initially 5 testers, scaling to broader audience).

**Infrastructure**: Full AWS deployment in eu-west-1 with production-grade configuration.

**Configuration**:
- DynamoDB: on-demand capacity, all 6 GSIs active, point-in-time recovery enabled.
- S3: Intelligent-Tiering enabled, versioning enabled (30-day noncurrent version expiration for soft delete), SSE-KMS encryption with customer-managed key, bucket key optimization enabled.
- Lambda: Production memory allocations, provisioned concurrency for latency-sensitive functions if needed.
- API Gateway: Custom domain name (if configured), throttling limits, WAF integration (if applicable).
- Cognito: Production user pool with Google and Apple social login configured.
- CloudFront: OAC configured, caching enabled for image delivery.
- Monitoring: Full CloudWatch dashboards, alarms, and alerting (see Monitoring section).
- KMS: Customer-managed key for S3 encryption, with key rotation enabled.

**Data Residency**: All production data resides in eu-west-1 (Ireland). No data replication to other regions.

---

## Flutter Build and Release

### Android

**Debug Builds**: Generated with `flutter build apk --debug`. Used for development and CI verification. Not signed with production credentials.

**Release Builds**: Generated with `flutter build appbundle --release` (AAB format preferred for Google Play) or `flutter build apk --release` (APK for direct distribution). Release builds include:
- R8 code shrinking and obfuscation (configured in `android/app/build.gradle`).
- AOT (Ahead-of-Time) compilation for maximum runtime performance.
- Production API endpoints and configuration.
- Production signing with the release keystore.

**Signing**: Android apps are signed with a keystore file containing the release key. The keystore file and its passwords are stored securely:
- In CI: stored as GitHub Actions encrypted secrets, injected as environment variables during the build step.
- Locally: stored in a secure location on the developer's machine, referenced by `android/key.properties` (which is git-ignored).
- The keystore must never be committed to the repository.

**Distribution**: Release AABs are uploaded to Google Play Console. The release process follows Google Play's staged rollout:
1. **Internal testing track**: Immediate distribution to the development team for smoke testing.
2. **Closed beta track**: Distribution to the 5-person tester group for real-world validation.
3. **Production track**: Full public availability (when ready, post-v1 testing phase).

### iOS

**Debug Builds**: Built and run via Xcode or `flutter run` on an iOS Simulator or connected device. Requires a valid Apple Developer account and development provisioning profile.

**Release Builds**: Generated with `flutter build ipa --release`. The output is an IPA file suitable for upload to App Store Connect. Release builds include:
- Bitcode compilation (if required by Apple at the time of submission).
- AOT compilation.
- Production configuration.
- Signing with the distribution certificate and provisioning profile.

**Signing**: iOS code signing uses Apple's certificate and provisioning profile system:
- **Development**: A development certificate and development provisioning profile, used for device testing.
- **Distribution**: A distribution certificate and App Store provisioning profile, used for release builds submitted to App Store Connect.
- In CI: certificates and profiles are stored as GitHub Actions encrypted secrets and installed into the macOS keychain during the build step using tools such as `fastlane match` or manual keychain import scripts.
- Locally: managed through Xcode's automatic signing or manually configured profiles.

**Distribution**: Release IPAs are uploaded to App Store Connect. The release process follows Apple's staged rollout:
1. **TestFlight (internal)**: Immediate distribution to the development team.
2. **TestFlight (external)**: Distribution to the 5-person tester group (requires Apple's brief review).
3. **App Store**: Full public availability (when ready, requires full App Store review).

### Versioning

The app follows semantic versioning: `MAJOR.MINOR.PATCH`.

| Component | When Incremented | Example |
|-----------|-----------------|---------|
| MAJOR | Breaking changes, major feature overhauls | 1.0.0 to 2.0.0 |
| MINOR | New features, non-breaking enhancements | 1.0.0 to 1.1.0 |
| PATCH | Bug fixes, minor improvements | 1.0.0 to 1.0.1 |

The version is maintained in `pubspec.yaml` under the `version` field (e.g., `version: 1.0.0+1`). The build number (the `+1` suffix) is incremented with every build submitted to the app stores, even if the semantic version does not change. The build number must be strictly increasing for both Google Play and App Store Connect.

---

## Infrastructure Deployment (CDK)

All AWS infrastructure is defined as code using the AWS Cloud Development Kit (CDK) with Python. CDK synthesizes the infrastructure definition into CloudFormation templates and deploys them as CloudFormation stacks.

### Stack Organization

The infrastructure is organized into five CDK stacks, each responsible for a logical group of resources. Splitting into multiple stacks provides clear separation of concerns, enables independent updates, and limits the blast radius of any single deployment.

| Stack | Resources | Dependencies |
|-------|-----------|--------------|
| **AuthStack** | Cognito User Pool, User Pool Client, Identity Providers (Google, Apple), User Pool Domain | None |
| **StorageStack** | DynamoDB table (with 6 GSIs), S3 buckets (images, thumbnails), KMS customer-managed key, CloudFront distribution | AuthStack (for user pool ARN in policies) |
| **ComputeStack** | All Lambda functions, Lambda layers, EventBridge rules (daily warranty check, weekly summary), SNS topics | StorageStack (for table name, bucket names, KMS key ARN) |
| **APIStack** | API Gateway REST API, routes, methods, Cognito authorizer, stage configuration | AuthStack (for authorizer), ComputeStack (for Lambda function ARNs) |
| **MonitoringStack** | CloudWatch dashboards, metric alarms, AWS Budget alerts | All other stacks (for resource ARNs to monitor) |

### Deployment Order

The stacks must be deployed in a specific order due to cross-stack references:

1. **AuthStack** -- deployed first, as it has no dependencies on other stacks.
2. **StorageStack** -- deployed second, depends on AuthStack.
3. **ComputeStack** -- deployed third, depends on StorageStack.
4. **APIStack** -- deployed fourth, depends on AuthStack and ComputeStack.
5. **MonitoringStack** -- deployed last, depends on all other stacks.

CDK handles cross-stack references through CloudFormation exports and imports. When deploying all stacks together (`cdk deploy --all`), CDK resolves the dependency graph automatically and deploys in the correct order.

### Deployment Commands

**Preview changes**: Before deploying, always run `cdk diff` to review the changes that will be applied. This command compares the locally synthesized template with the currently deployed stack and displays additions, modifications, and deletions.

```
cdk diff --all
```

**Deploy to staging**: Deploy all stacks to the staging environment. The `--require-approval never` flag is used in CI to allow automated deployment without manual confirmation.

```
cdk deploy --all --context env=staging --require-approval never
```

**Deploy to production**: Deploy all stacks to production. The `--require-approval broadening` flag requires manual confirmation whenever the deployment would broaden IAM permissions or security group rules, providing an additional safety check for production changes.

```
cdk deploy --all --context env=production --require-approval broadening
```

**Deploy a single stack**: For targeted updates that affect only one stack (for example, updating a single Lambda function), deploy only that stack to minimize deployment time and risk.

```
cdk deploy ReceiptVaultProduction-ComputeStack --require-approval broadening
```

---

## Database Migrations

### DynamoDB (Cloud)

DynamoDB is a schema-less NoSQL database. Adding new attributes to items does not require a migration -- new attributes can be written to items immediately, and old items that lack the new attribute simply return null for that field. This schema flexibility means that most data model changes require no migration process at all.

**GSI Additions**: Adding a new Global Secondary Index (GSI) is the one DynamoDB operation that requires careful planning. DynamoDB limits the number of concurrent GSI creation operations and must backfill the new index with existing data. The backfill process can take minutes to hours depending on table size and consumes read capacity from the base table. GSI additions should be:
- Planned in advance and included in the CDK stack definition.
- Deployed during low-traffic periods.
- Monitored via CloudWatch for backfill progress and throttling.

The current schema uses 6 GSIs, which is within DynamoDB's default limit of 20 GSIs per table. Adding GSIs beyond the initial 6 requires no quota increase but does require CDK stack updates and backfill time.

**GSI Removals**: Removing a GSI is faster than adding one (no backfill needed) but should be done only after confirming that no application code queries the index. GSI removal is a non-reversible operation -- re-adding the index requires a full backfill.

### Drift (Local SQLite Database)

Drift provides a built-in schema migration system that handles local database upgrades when the app is updated to a new version. Each schema version is assigned an integer version number, and Drift executes migration steps sequentially to bring the database from any older version to the current version.

**Migration Approach**:
- Each time the local database schema changes (new table, new column, index addition, column type change), the schema version number in the Drift database definition is incremented.
- A migration step is written that describes how to transform the database from the previous version to the new version. Migration steps can include `CREATE TABLE`, `ALTER TABLE ADD COLUMN`, `CREATE INDEX`, data transformation queries, and other SQL operations.
- Drift executes all pending migration steps in order when the app launches and detects that the local database is at an older schema version.

**Testing Migrations**: Schema migrations must be tested across all supported schema versions. A migration test creates a database at each historical schema version, runs the migration steps, and verifies that the resulting schema matches the expected current-version schema. This prevents migration bugs that could cause data loss or crashes on app update.

**Destructive Changes**: Schema changes that remove columns or tables require special care. Data in removed columns must be migrated to a new location before the column is dropped. Drift's migration system supports multi-step migrations that can copy data, create new structures, and then drop old ones in a controlled sequence.

---

## Rollback Strategy

Deployment failures and regressions are inevitable in any software project. The rollback strategy defines how to revert each component to a known-good state with minimal downtime and data impact.

### Lambda Functions

**Mechanism**: Each Lambda function is published as a numbered version on every deployment. A function alias (e.g., `live`) points to the currently active version. API Gateway invokes the alias, not the version number directly.

**Rollback Procedure**: To roll back a Lambda function, update the alias to point to the previous version number. This takes effect immediately (within seconds) and does not require a new deployment. The rollback can be performed via the AWS CLI:

```
aws lambda update-alias --function-name receipt-crud --name live --function-version 42
```

Where `42` is the previously known-good version number. This approach means that even if a bad deployment is made, the previous function code is still available and can be restored instantly.

### API Gateway

**Mechanism**: API Gateway uses stage deployments. Each deployment creates an immutable snapshot of the API configuration (routes, integrations, authorizers, throttling settings). The production stage points to the current deployment.

**Rollback Procedure**: To roll back the API, redeploy the previous deployment ID to the production stage. Previous deployment IDs are logged during the deployment process and can be retrieved from the API Gateway deployment history.

### CDK / CloudFormation

**Mechanism**: CDK deployments are executed through CloudFormation, which tracks the state of all resources in each stack. CloudFormation provides automatic rollback on deployment failure: if any resource update fails during a stack update, CloudFormation automatically rolls back all changes in that update to restore the stack to its previous state.

**Automatic Rollback**: If a `cdk deploy` operation fails partway through (for example, a Lambda function fails to create because of a packaging error, or an IAM policy is invalid), CloudFormation automatically rolls back all resources in the stack to their pre-deployment state. No manual intervention is needed for failed deployments.

**Manual Rollback**: If a deployment succeeds but introduces a regression (the deployment completed without errors, but the new code behaves incorrectly), the team can roll back by deploying the previous Git commit's CDK code. Since all infrastructure is defined in code and version-controlled, checking out the previous commit and running `cdk deploy` restores the previous infrastructure state.

### Mobile App

**Fundamental Constraint**: Mobile apps installed on user devices cannot be force-rolled back. Once a user has updated to a new app version, the old version cannot be restored remotely. This fundamental constraint shapes the mobile rollback strategy.

**Feature Flags**: Risky features are gated behind feature flags that can be toggled server-side without requiring an app update. If a new feature causes problems, the feature flag is disabled, and the app reverts to the previous behavior. Feature flags are stored in the API response headers or in a lightweight configuration endpoint that the app checks on launch.

**Minimum App Version Enforcement**: The API can enforce a minimum app version by including a `X-Min-App-Version` header in responses. If the app's version is below the minimum, the app displays a message directing the user to update. This mechanism can be used to force users off a buggy version by releasing a fix and then setting the minimum version to the fixed release.

**Staged Rollout**: Both Google Play and the App Store support staged rollouts (percentage-based release). New versions can be released to a small percentage of users first, monitored for crash rates and errors, and then expanded to all users. If problems are detected during the staged rollout, the rollout can be halted and the percentage reset to 0%.

---

## Monitoring and Alerting (Post-Deploy)

Monitoring is not an optional enhancement -- it is a required component of every production deployment. The monitoring strategy ensures that issues are detected, diagnosed, and resolved before they impact user experience.

### CloudWatch Dashboards

A centralized CloudWatch dashboard provides a real-time view of system health. The dashboard includes:

**Lambda Function Metrics**: For each Lambda function (receipt_crud, ocr_refine, sync_handler, thumbnail_generator, warranty_checker, weekly_summary, user_deletion, export_handler, category_handler, presigned_url_generator):
- Invocation count (total calls per period).
- Error count and error rate (percentage of invocations that resulted in an error).
- Duration (p50, p95, p99 latency in milliseconds).
- Throttle count (invocations throttled due to concurrency limits).
- Cold start count (invocations that required a cold start).

**API Gateway Metrics**:
- Request count by endpoint and HTTP method.
- 4xx error rate (client errors: bad requests, unauthorized, not found).
- 5xx error rate (server errors: internal failures).
- Latency (p50, p95, p99 end-to-end request duration).
- Integration latency (time spent in the Lambda function, excluding API Gateway overhead).

**DynamoDB Metrics**:
- Read capacity consumed and write capacity consumed (for on-demand, this tracks the actual usage).
- Throttled request count (should be zero under normal operation with on-demand capacity).
- System errors.
- GSI read and write consumption.

**S3 Metrics**:
- Bucket size (total storage consumed).
- Number of objects.
- Request counts (GET, PUT).

### Alerting

Alarms are configured to notify the team when metrics exceed acceptable thresholds. Alerts are delivered via email (for all severity levels) and optionally via PagerDuty or an equivalent service (for critical alerts that require immediate attention).

**Error Rate Alarm**: Triggers when the error rate for any Lambda function exceeds 5% over a 5-minute period. This threshold is set low enough to catch genuine issues but high enough to avoid false alarms from occasional transient errors.

**API Latency Alarm**: Triggers when the p99 API Gateway latency exceeds 5 seconds over a 5-minute period. This catches slow responses that degrade the user experience, whether caused by Lambda cold starts, DynamoDB throttling, or Bedrock API delays.

**DynamoDB Throttle Alarm**: Triggers when any throttled request is detected. With on-demand capacity mode, throttling should never occur under normal operation. A throttle event suggests either a partition hot key issue or an unexpectedly large traffic spike.

**Lambda Error Alarm**: Triggers when any individual Lambda function records more than 10 errors in a 5-minute period. This catches function-specific issues (code bugs, dependency failures, configuration errors) that might not be visible in the overall error rate.

### Custom Metrics

In addition to the built-in AWS metrics, the application emits custom CloudWatch metrics to track business-level health:

| Custom Metric | Description | Unit |
|--------------|-------------|------|
| ReceiptsCreated | Number of new receipts created (via API) | Count |
| OCRRefinementsProcessed | Number of receipts processed by Bedrock LLM | Count |
| OCRRefinementsFailed | Number of Bedrock invocations that failed | Count |
| SyncOperationsCompleted | Number of successful sync operations | Count |
| SyncConflictsDetected | Number of field-level conflicts resolved during sync | Count |
| WarrantyRemindersTriggered | Number of warranty expiry notifications sent | Count |
| UserDeletionsProcessed | Number of GDPR account deletion cascades completed | Count |

These metrics provide visibility into the application's core workflows beyond raw infrastructure health. A spike in `OCRRefinementsFailed` might indicate a Bedrock API issue or a change in receipt image quality. A drop in `ReceiptsCreated` might indicate an app-side bug preventing capture.

### Cost Monitoring

AWS Budgets is configured with tiered alerts to prevent unexpected cost overruns.

| Budget Threshold | Action |
|-----------------|--------|
| $10 per month | Email notification to the development team. This is expected to be exceeded only as the user base grows beyond the initial 5 testers. At 5 testers, the total monthly cost is approximately $2. |
| $50 per month | Email notification with increased urgency. Indicates significant usage growth or a potential cost anomaly (runaway Lambda invocations, excessive Bedrock calls, or S3 storage accumulation). |
| $100 per month | Email and alert escalation. At the projected cost of approximately $88/month for 1,000 users, this threshold serves as an early warning for cost growth beyond projections. Requires investigation and potential cost optimization action. |

Budget alerts are a safety net, not a replacement for architectural cost controls. The primary cost controls are the Haiku-first LLM strategy (documented in the LLM Integration document), the S3 Intelligent-Tiering storage class, the DynamoDB on-demand capacity mode, and the Lambda free tier utilization.

---

*This document is part of the Receipt & Warranty Vault documentation suite. For related documents, see the [docs directory listing](../CLAUDE.md#documentation-files).*

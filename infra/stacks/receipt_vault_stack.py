"""Receipt & Warranty Vault — CDK Stack.

Single stack defining all AWS infrastructure for the Receipt & Warranty Vault
serverless backend, deployed to eu-west-1.
"""

import os

from aws_cdk import (
    Stack,
    Duration,
    RemovalPolicy,
    CfnOutput,
    Tags,
    aws_dynamodb as dynamodb,
    aws_s3 as s3,
    aws_s3_notifications as s3n,
    aws_kms as kms,
    aws_lambda as lambda_,
    aws_apigateway as apigw,
    aws_cognito as cognito,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as origins,
    aws_sns as sns,
    aws_sns_subscriptions as subscriptions,
    aws_events as events,
    aws_events_targets as targets,
    aws_cloudwatch as cloudwatch,
    aws_cloudwatch_actions as cw_actions,
    aws_iam as iam,
    aws_logs as logs,
)
from constructs import Construct


class ReceiptVaultStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # ── Section 1: KMS ──────────────────────────────────────────────

        cmk = kms.Key(
            self,
            "S3CMK",
            alias="alias/receiptvault-s3-cmk",
            description="CMK for Receipt Vault S3 image encryption",
            enable_key_rotation=True,
        )

        # ── Section 2: DynamoDB ─────────────────────────────────────────

        table = dynamodb.Table(
            self,
            "ReceiptVaultTable",
            table_name="ReceiptVault",
            partition_key=dynamodb.Attribute(
                name="PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="SK", type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            point_in_time_recovery=True,
            time_to_live_attribute="ttl",
            deletion_protection=True,
            removal_policy=RemovalPolicy.RETAIN,
        )

        # GSI-1: ByUserDate — All receipts by date, date range queries
        table.add_global_secondary_index(
            index_name="ByUserDate",
            partition_key=dynamodb.Attribute(
                name="GSI1PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI1SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # GSI-2: ByUserCategory — Receipts by category
        table.add_global_secondary_index(
            index_name="ByUserCategory",
            partition_key=dynamodb.Attribute(
                name="GSI2PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI2SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # GSI-3: ByUserStore — Receipts by store
        table.add_global_secondary_index(
            index_name="ByUserStore",
            partition_key=dynamodb.Attribute(
                name="GSI3PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI3SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # GSI-4: ByWarrantyExpiry — Active warranties, expiring soon (sparse)
        table.add_global_secondary_index(
            index_name="ByWarrantyExpiry",
            partition_key=dynamodb.Attribute(
                name="GSI4PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="warrantyExpiryDate", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # GSI-5: ByUserStatus — Receipts by status
        table.add_global_secondary_index(
            index_name="ByUserStatus",
            partition_key=dynamodb.Attribute(
                name="GSI5PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI5SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        # GSI-6: ByUpdatedAt — Delta sync queries (KEYS_ONLY for efficiency)
        table.add_global_secondary_index(
            index_name="ByUpdatedAt",
            partition_key=dynamodb.Attribute(
                name="GSI6PK", type=dynamodb.AttributeType.STRING
            ),
            sort_key=dynamodb.Attribute(
                name="GSI6SK", type=dynamodb.AttributeType.STRING
            ),
            projection_type=dynamodb.ProjectionType.KEYS_ONLY,
        )

        # ── Section 3: S3 Buckets ──────────────────────────────────────

        # Access logs bucket — must be created before image bucket
        access_logs_bucket = s3.Bucket(
            self,
            "AccessLogsBucket",
            bucket_name="receiptvault-access-logs-prod-eu-west-1",
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            versioned=False,
            auto_delete_objects=True,
            removal_policy=RemovalPolicy.DESTROY,
            lifecycle_rules=[
                s3.LifecycleRule(expiration=Duration.days(90)),
            ],
        )

        # Image bucket — primary storage for receipt images
        image_bucket = s3.Bucket(
            self,
            "ImageBucket",
            bucket_name="receiptvault-images-prod-eu-west-1",
            versioned=True,
            encryption=s3.BucketEncryption.KMS,
            encryption_key=cmk,
            bucket_key_enabled=True,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            auto_delete_objects=False,
            removal_policy=RemovalPolicy.RETAIN,
            server_access_logs_bucket=access_logs_bucket,
            server_access_logs_prefix="image-bucket/",
            lifecycle_rules=[
                s3.LifecycleRule(
                    noncurrent_version_expiration=Duration.days(30),
                    transitions=[
                        s3.Transition(
                            storage_class=s3.StorageClass.INTELLIGENT_TIERING,
                            transition_after=Duration.days(0),
                        ),
                    ],
                ),
            ],
        )

        # Export bucket — transient exports (auto-expire after 7 days)
        export_bucket = s3.Bucket(
            self,
            "ExportBucket",
            bucket_name="receiptvault-exports-prod-eu-west-1",
            encryption=s3.BucketEncryption.KMS,
            encryption_key=cmk,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            auto_delete_objects=True,
            removal_policy=RemovalPolicy.DESTROY,
            lifecycle_rules=[
                s3.LifecycleRule(expiration=Duration.days(7)),
            ],
        )

        # ── Section 4: Cognito ──────────────────────────────────────────

        user_pool = cognito.UserPool(
            self,
            "UserPool",
            user_pool_name="receiptvault-user-pool-prod",
            self_sign_up_enabled=True,
            sign_in_aliases=cognito.SignInAliases(email=True),
            auto_verify=cognito.AutoVerifiedAttrs(email=True),
            password_policy=cognito.PasswordPolicy(
                min_length=8,
                require_uppercase=True,
                require_lowercase=True,
                require_digits=True,
                require_symbols=True,
                temp_password_validity=Duration.days(7),
            ),
            account_recovery=cognito.AccountRecovery.EMAIL_ONLY,
            mfa=cognito.Mfa.OPTIONAL,
            mfa_second_factor=cognito.MfaSecondFactor(otp=True, sms=False),
            standard_attributes=cognito.StandardAttributes(
                email=cognito.StandardAttribute(required=True, mutable=True),
            ),
            removal_policy=RemovalPolicy.RETAIN,
        )

        # TODO: Add Google and Apple identity providers once client IDs are obtained
        # google_provider = cognito.UserPoolIdentityProviderGoogle(...)
        # apple_provider = cognito.UserPoolIdentityProviderApple(...)

        app_client = user_pool.add_client(
            "AppClient",
            user_pool_client_name="receiptvault-app-client",
            auth_flows=cognito.AuthFlow(
                user_srp=True,
                custom=True,
            ),
            access_token_validity=Duration.hours(1),
            id_token_validity=Duration.hours(1),
            refresh_token_validity=Duration.days(30),
            generate_secret=False,
            o_auth=cognito.OAuthSettings(
                flows=cognito.OAuthFlows(authorization_code_grant=True),
                callback_urls=["warrantyvault://callback"],
                scopes=[
                    cognito.OAuthScope.OPENID,
                    cognito.OAuthScope.EMAIL,
                    cognito.OAuthScope.PROFILE,
                ],
            ),
            prevent_user_existence_errors=True,
        )

        # ── Section 5: Lambda Layer ─────────────────────────────────────

        shared_layer = lambda_.LayerVersion(
            self,
            "SharedLayer",
            code=lambda_.Code.from_asset("lambda_layer"),
            compatible_runtimes=[lambda_.Runtime.PYTHON_3_12],
            compatible_architectures=[lambda_.Architecture.ARM_64],
            description="Shared utilities for Receipt Vault Lambdas",
        )

        # ── Section 6: Lambda Functions ─────────────────────────────────

        # Common environment variables
        common_env = {
            "TABLE_NAME": table.table_name,
            "REGION": "eu-west-1",
        }

        # receipt-crud: CRUD operations on receipts, warranties, user profile/settings
        receipt_crud_fn = lambda_.Function(
            self,
            "ReceiptCrudFn",
            function_name="receiptvault-receipt-crud-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join("lambdas", "receipt_crud")),
            memory_size=256,
            timeout=Duration.seconds(10),
            environment={
                **common_env,
            },
            layers=[shared_layer],
            description="CRUD operations for receipts, warranties, user profile and settings",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # ocr-refine: LLM-powered OCR refinement via Bedrock
        ocr_refine_fn = lambda_.Function(
            self,
            "OcrRefineFn",
            function_name="receiptvault-ocr-refine-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join("lambdas", "ocr_refine")),
            memory_size=512,
            timeout=Duration.seconds(30),
            environment={
                **common_env,
                "BEDROCK_MODEL_ID": "anthropic.claude-haiku-4-5-v1",
                "BEDROCK_FALLBACK_MODEL_ID": "anthropic.claude-sonnet-4-5-v1",
                "S3_BUCKET": image_bucket.bucket_name,
                "CONFIDENCE_THRESHOLD": "0.70",
            },
            layers=[shared_layer],
            description="LLM-powered OCR refinement using Bedrock Claude",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # sync-handler: Delta sync, full reconciliation, push sync
        sync_handler_fn = lambda_.Function(
            self,
            "SyncHandlerFn",
            function_name="receiptvault-sync-handler-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join("lambdas", "sync_handler")),
            memory_size=512,
            timeout=Duration.seconds(30),
            environment={
                **common_env,
                "MAX_BATCH_SIZE": "25",
            },
            layers=[shared_layer],
            description="Sync engine: delta pull, push, and full reconciliation",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # thumbnail-generator: Auto-generate thumbnails on S3 upload
        thumbnail_generator_fn = lambda_.Function(
            self,
            "ThumbnailGeneratorFn",
            function_name="receiptvault-thumbnail-generator-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(
                os.path.join("lambdas", "thumbnail_generator")
            ),
            memory_size=512,
            timeout=Duration.seconds(30),
            environment={
                "S3_BUCKET": image_bucket.bucket_name,
                "THUMBNAIL_WIDTH": "200",
                "THUMBNAIL_HEIGHT": "300",
                "THUMBNAIL_QUALITY": "70",
            },
            layers=[shared_layer],
            description="Auto-generate receipt image thumbnails on S3 upload",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # warranty-checker: Daily scheduled check for expiring warranties
        warranty_checker_fn = lambda_.Function(
            self,
            "WarrantyCheckerFn",
            function_name="receiptvault-warranty-checker-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(
                os.path.join("lambdas", "warranty_checker")
            ),
            memory_size=256,
            timeout=Duration.seconds(60),
            environment={
                **common_env,
                "SNS_TOPIC_ARN": "",  # Set after SNS topic creation
            },
            layers=[shared_layer],
            description="Daily check for expiring warranties and send notifications",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # weekly-summary: Weekly digest of warranty and receipt stats
        weekly_summary_fn = lambda_.Function(
            self,
            "WeeklySummaryFn",
            function_name="receiptvault-weekly-summary-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join("lambdas", "weekly_summary")),
            memory_size=256,
            timeout=Duration.seconds(60),
            environment={
                **common_env,
                "SNS_TOPIC_ARN": "",  # Set after SNS topic creation
            },
            layers=[shared_layer],
            description="Weekly summary digest of warranties and receipts",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # user-deletion: GDPR cascade delete (Cognito -> DynamoDB -> S3)
        user_deletion_fn = lambda_.Function(
            self,
            "UserDeletionFn",
            function_name="receiptvault-user-deletion-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join("lambdas", "user_deletion")),
            memory_size=256,
            timeout=Duration.seconds(120),
            environment={
                **common_env,
                "S3_BUCKET": image_bucket.bucket_name,
                "USER_POOL_ID": user_pool.user_pool_id,
            },
            layers=[shared_layer],
            description="GDPR cascade delete: Cognito, DynamoDB, and S3 user data",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # export-handler: Batch export receipts by date range
        export_handler_fn = lambda_.Function(
            self,
            "ExportHandlerFn",
            function_name="receiptvault-export-handler-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(os.path.join("lambdas", "export_handler")),
            memory_size=1024,
            timeout=Duration.seconds(300),
            environment={
                **common_env,
                "S3_BUCKET": image_bucket.bucket_name,
                "EXPORT_BUCKET": export_bucket.bucket_name,
                "EXPORT_TTL_DAYS": "7",
                "SNS_TOPIC_ARN": "",  # Set after SNS topic creation
            },
            layers=[shared_layer],
            description="Batch export receipts to ZIP with images",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # category-handler: Custom category management
        category_handler_fn = lambda_.Function(
            self,
            "CategoryHandlerFn",
            function_name="receiptvault-category-handler-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(
                os.path.join("lambdas", "category_handler")
            ),
            memory_size=256,
            timeout=Duration.seconds(10),
            environment={
                **common_env,
            },
            layers=[shared_layer],
            description="Custom category CRUD operations",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # presigned-url-generator: Generate pre-signed S3 URLs for upload/download
        presigned_url_fn = lambda_.Function(
            self,
            "PresignedUrlFn",
            function_name="receiptvault-presigned-url-generator-prod",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="handler.handler",
            code=lambda_.Code.from_asset(
                os.path.join("lambdas", "presigned_url_generator")
            ),
            memory_size=128,
            timeout=Duration.seconds(5),
            environment={
                "S3_BUCKET": image_bucket.bucket_name,
                "REGION": "eu-west-1",
                "KMS_KEY_ID": cmk.key_arn,
                "URL_EXPIRY_SECONDS": "600",
                "MAX_FILE_SIZE": "10485760",
            },
            layers=[shared_layer],
            description="Generate pre-signed S3 URLs for image upload and download",
            log_retention=logs.RetentionDays.ONE_MONTH,
        )

        # ── Section 7: API Gateway ──────────────────────────────────────

        api = apigw.RestApi(
            self,
            "Api",
            rest_api_name="receiptvault-api-prod",
            description="Receipt & Warranty Vault API",
            deploy_options=apigw.StageOptions(stage_name="prod"),
            default_cors_preflight_options=apigw.CorsOptions(
                allow_origins=apigw.Cors.ALL_ORIGINS,
                allow_methods=[
                    "GET",
                    "POST",
                    "PUT",
                    "PATCH",
                    "DELETE",
                    "OPTIONS",
                ],
                allow_headers=[
                    "Content-Type",
                    "Authorization",
                    "X-Amz-Date",
                    "X-Api-Key",
                    "X-Amz-Security-Token",
                ],
                max_age=Duration.seconds(3600),
            ),
        )

        # Cognito authorizer
        authorizer = apigw.CognitoUserPoolsAuthorizer(
            self,
            "CognitoAuthorizer",
            cognito_user_pools=[user_pool],
            authorizer_name="receiptvault-cognito-authorizer",
        )

        auth_method_opts = {
            "authorizer": authorizer,
            "authorization_type": apigw.AuthorizationType.COGNITO,
        }

        # --- /receipts ---
        receipts_resource = api.root.add_resource("receipts")
        receipts_resource.add_method(
            "GET",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )
        receipts_resource.add_method(
            "POST",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /receipts/{receiptId} ---
        receipt_resource = receipts_resource.add_resource("{receiptId}")
        receipt_resource.add_method(
            "GET",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )
        receipt_resource.add_method(
            "PUT",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )
        receipt_resource.add_method(
            "DELETE",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /receipts/{receiptId}/restore ---
        restore_resource = receipt_resource.add_resource("restore")
        restore_resource.add_method(
            "POST",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /receipts/{receiptId}/status ---
        status_resource = receipt_resource.add_resource("status")
        status_resource.add_method(
            "PATCH",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /receipts/{receiptId}/refine ---
        refine_resource = receipt_resource.add_resource("refine")
        refine_resource.add_method(
            "POST",
            apigw.LambdaIntegration(ocr_refine_fn),
            **auth_method_opts,
        )

        # --- /receipts/{receiptId}/images/upload-url ---
        images_resource = receipt_resource.add_resource("images")
        upload_url_resource = images_resource.add_resource("upload-url")
        upload_url_resource.add_method(
            "POST",
            apigw.LambdaIntegration(presigned_url_fn),
            **auth_method_opts,
        )

        # --- /receipts/{receiptId}/images/{imageKey}/download-url ---
        image_key_resource = images_resource.add_resource("{imageKey}")
        download_url_resource = image_key_resource.add_resource("download-url")
        download_url_resource.add_method(
            "GET",
            apigw.LambdaIntegration(presigned_url_fn),
            **auth_method_opts,
        )

        # --- /sync/pull ---
        sync_resource = api.root.add_resource("sync")
        sync_pull_resource = sync_resource.add_resource("pull")
        sync_pull_resource.add_method(
            "POST",
            apigw.LambdaIntegration(sync_handler_fn),
            **auth_method_opts,
        )

        # --- /sync/push ---
        sync_push_resource = sync_resource.add_resource("push")
        sync_push_resource.add_method(
            "POST",
            apigw.LambdaIntegration(sync_handler_fn),
            **auth_method_opts,
        )

        # --- /sync/full ---
        sync_full_resource = sync_resource.add_resource("full")
        sync_full_resource.add_method(
            "POST",
            apigw.LambdaIntegration(sync_handler_fn),
            **auth_method_opts,
        )

        # --- /categories ---
        categories_resource = api.root.add_resource("categories")
        categories_resource.add_method(
            "GET",
            apigw.LambdaIntegration(category_handler_fn),
            **auth_method_opts,
        )
        categories_resource.add_method(
            "PUT",
            apigw.LambdaIntegration(category_handler_fn),
            **auth_method_opts,
        )

        # --- /warranties/expiring ---
        warranties_resource = api.root.add_resource("warranties")
        expiring_resource = warranties_resource.add_resource("expiring")
        expiring_resource.add_method(
            "GET",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /user/profile ---
        user_resource = api.root.add_resource("user")
        profile_resource = user_resource.add_resource("profile")
        profile_resource.add_method(
            "GET",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )
        profile_resource.add_method(
            "PUT",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /user/settings ---
        settings_resource = user_resource.add_resource("settings")
        settings_resource.add_method(
            "GET",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )
        settings_resource.add_method(
            "PUT",
            apigw.LambdaIntegration(receipt_crud_fn),
            **auth_method_opts,
        )

        # --- /user/account ---
        account_resource = user_resource.add_resource("account")
        account_resource.add_method(
            "DELETE",
            apigw.LambdaIntegration(user_deletion_fn),
            **auth_method_opts,
        )

        # --- /user/export ---
        export_resource = user_resource.add_resource("export")
        export_resource.add_method(
            "POST",
            apigw.LambdaIntegration(export_handler_fn),
            **auth_method_opts,
        )

        # ── Section 8: CloudFront ───────────────────────────────────────

        oac = cloudfront.S3OriginAccessControl(
            self,
            "ImageBucketOAC",
            description="OAC for Receipt Vault image bucket",
        )

        thumbnail_cache_policy = cloudfront.CachePolicy(
            self,
            "ThumbnailCachePolicy",
            cache_policy_name="receiptvault-thumbnail-cache",
            default_ttl=Duration.hours(24),
            max_ttl=Duration.hours(24),
            min_ttl=Duration.hours(1),
        )

        distribution = cloudfront.Distribution(
            self,
            "ImageCDN",
            default_behavior=cloudfront.BehaviorOptions(
                origin=origins.S3BucketOrigin.with_origin_access_control(
                    image_bucket, origin_access_control=oac
                ),
                viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                cache_policy=cloudfront.CachePolicy.CACHING_DISABLED,
            ),
            additional_behaviors={
                "users/*/receipts/*/thumbnail/*": cloudfront.BehaviorOptions(
                    origin=origins.S3BucketOrigin.with_origin_access_control(
                        image_bucket, origin_access_control=oac
                    ),
                    viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                    cache_policy=thumbnail_cache_policy,
                ),
            },
            price_class=cloudfront.PriceClass.PRICE_CLASS_100,
            http_version=cloudfront.HttpVersion.HTTP2,
            enable_ipv6=True,
        )

        # Grant CloudFront decrypt permission on CMK
        cmk.grant_decrypt(iam.ServicePrincipal("cloudfront.amazonaws.com"))

        # ── Section 9: SNS Topics ───────────────────────────────────────

        warranty_topic = sns.Topic(
            self,
            "WarrantyExpiringTopic",
            topic_name="receiptvault-warranty-expiring-prod",
        )

        export_topic = sns.Topic(
            self,
            "ExportReadyTopic",
            topic_name="receiptvault-export-ready-prod",
        )

        ops_topic = sns.Topic(
            self,
            "OpsAlertsTopic",
            topic_name="receiptvault-ops-alerts-prod",
        )

        # TODO: Add email subscription to ops_topic for operational alerts
        # ops_topic.add_subscription(subscriptions.EmailSubscription("ops@example.com"))

        # Update Lambda environment variables with SNS topic ARNs
        warranty_checker_fn.add_environment(
            "SNS_TOPIC_ARN", warranty_topic.topic_arn
        )
        weekly_summary_fn.add_environment(
            "SNS_TOPIC_ARN", warranty_topic.topic_arn
        )
        export_handler_fn.add_environment(
            "SNS_TOPIC_ARN", export_topic.topic_arn
        )

        # ── Section 10: EventBridge Rules ───────────────────────────────

        # Daily warranty check at 8 AM UTC
        events.Rule(
            self,
            "DailyWarrantyCheck",
            rule_name="receiptvault-daily-warranty-check",
            schedule=events.Schedule.cron(
                minute="0",
                hour="8",
                month="*",
                week_day="*",
                year="*",
            ),
            targets=[
                targets.LambdaFunction(warranty_checker_fn, retry_attempts=2)
            ],
        )

        # Weekly summary on Monday at 9 AM UTC
        events.Rule(
            self,
            "WeeklySummary",
            rule_name="receiptvault-weekly-summary",
            schedule=events.Schedule.cron(
                minute="0",
                hour="9",
                week_day="MON",
                month="*",
                year="*",
            ),
            targets=[
                targets.LambdaFunction(weekly_summary_fn, retry_attempts=2)
            ],
        )

        # ── Section 11: CloudWatch Alarms ───────────────────────────────

        # Alarm: High aggregate Lambda error rate
        high_error_alarm = cloudwatch.Alarm(
            self,
            "HighLambdaErrorRate",
            alarm_name="receiptvault-high-lambda-error-rate",
            metric=cloudwatch.Metric(
                namespace="AWS/Lambda",
                metric_name="Errors",
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=5,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
        high_error_alarm.add_alarm_action(cw_actions.SnsAction(ops_topic))

        # Alarm: User deletion Lambda failures
        user_deletion_error_alarm = cloudwatch.Alarm(
            self,
            "UserDeletionFailure",
            alarm_name="receiptvault-user-deletion-failure",
            metric=user_deletion_fn.metric_errors(
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=0,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
        user_deletion_error_alarm.add_alarm_action(
            cw_actions.SnsAction(ops_topic)
        )

        # Alarm: Bedrock throttling on OCR refine
        bedrock_throttle_alarm = cloudwatch.Alarm(
            self,
            "BedrockThrottling",
            alarm_name="receiptvault-bedrock-throttling",
            metric=cloudwatch.Metric(
                namespace="ReceiptVault",
                metric_name="BedrockThrottleCount",
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=3,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
        bedrock_throttle_alarm.add_alarm_action(cw_actions.SnsAction(ops_topic))

        # Alarm: High OCR latency
        high_latency_ocr_alarm = cloudwatch.Alarm(
            self,
            "HighLatencyOCR",
            alarm_name="receiptvault-high-latency-ocr",
            metric=cloudwatch.Metric(
                namespace="ReceiptVault",
                metric_name="OcrLatencyMs",
                statistic="p99",
                period=Duration.minutes(5),
            ),
            threshold=10000,
            evaluation_periods=2,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
        high_latency_ocr_alarm.add_alarm_action(
            cw_actions.SnsAction(ops_topic)
        )

        # Alarm: Sync handler failures
        sync_failure_alarm = cloudwatch.Alarm(
            self,
            "SyncFailures",
            alarm_name="receiptvault-sync-failures",
            metric=cloudwatch.Metric(
                namespace="ReceiptVault",
                metric_name="SyncFailureCount",
                statistic="Sum",
                period=Duration.minutes(5),
            ),
            threshold=3,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
        sync_failure_alarm.add_alarm_action(cw_actions.SnsAction(ops_topic))

        # ── Section 12: S3 Event Notifications ──────────────────────────

        # Trigger thumbnail generation on new image uploads
        # Key pattern: users/{userId}/receipts/{receiptId}/original/{filename}
        # S3 filters only support prefix — Lambda handler checks for '/original/'
        image_bucket.add_event_notification(
            s3.EventType.OBJECT_CREATED,
            s3n.LambdaDestination(thumbnail_generator_fn),
            s3.NotificationKeyFilter(prefix="users/"),
        )

        # ── Section 13: IAM Grants ─────────────────────────────────────

        # receipt-crud: DynamoDB full access
        table.grant_read_write_data(receipt_crud_fn)

        # ocr-refine: DynamoDB read+write, S3 read, KMS decrypt, Bedrock invoke
        table.grant_read_write_data(ocr_refine_fn)
        image_bucket.grant_read(ocr_refine_fn)
        cmk.grant_decrypt(ocr_refine_fn)
        ocr_refine_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=["bedrock:InvokeModel"],
                resources=[
                    "arn:aws:bedrock:eu-west-1::foundation-model/anthropic.claude-haiku-4-5-v1",
                    "arn:aws:bedrock:eu-west-1::foundation-model/anthropic.claude-sonnet-4-5-v1",
                ],
            )
        )

        # sync-handler: DynamoDB full access
        table.grant_read_write_data(sync_handler_fn)

        # thumbnail-generator: S3 read+write, KMS encrypt+decrypt
        image_bucket.grant_read_write(thumbnail_generator_fn)
        cmk.grant_encrypt_decrypt(thumbnail_generator_fn)

        # warranty-checker: DynamoDB read+write, SNS publish
        table.grant_read_write_data(warranty_checker_fn)
        warranty_topic.grant_publish(warranty_checker_fn)

        # weekly-summary: DynamoDB read, SNS publish
        table.grant_read_data(weekly_summary_fn)
        warranty_topic.grant_publish(weekly_summary_fn)

        # user-deletion: Cognito admin, DynamoDB read+write, S3 read+delete, KMS decrypt
        table.grant_read_write_data(user_deletion_fn)
        image_bucket.grant_read(user_deletion_fn)
        image_bucket.grant_delete(user_deletion_fn)
        cmk.grant_decrypt(user_deletion_fn)
        user_deletion_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=["cognito-idp:AdminDeleteUser"],
                resources=[user_pool.user_pool_arn],
            )
        )
        # Versioned object cleanup for GDPR hard delete
        user_deletion_fn.add_to_role_policy(
            iam.PolicyStatement(
                actions=["s3:ListBucketVersions", "s3:DeleteObjectVersion"],
                resources=[
                    image_bucket.bucket_arn,
                    f"{image_bucket.bucket_arn}/*",
                ],
            )
        )

        # export-handler: DynamoDB read, S3 image read, S3 export write, KMS, SNS
        table.grant_read_data(export_handler_fn)
        image_bucket.grant_read(export_handler_fn)
        export_bucket.grant_write(export_handler_fn)
        cmk.grant_encrypt_decrypt(export_handler_fn)
        export_topic.grant_publish(export_handler_fn)

        # category-handler: DynamoDB read+write
        table.grant_read_write_data(category_handler_fn)

        # presigned-url-generator: DynamoDB read, S3 read+write, KMS encrypt+decrypt
        table.grant_read_data(presigned_url_fn)
        image_bucket.grant_read_write(presigned_url_fn)
        cmk.grant_encrypt_decrypt(presigned_url_fn)

        # ── Section 14: Tags ────────────────────────────────────────────

        Tags.of(self).add("Project", "WarrantyVault")
        Tags.of(self).add("Environment", "prod")
        Tags.of(self).add("Owner", "necropolis0079")
        Tags.of(self).add("ManagedBy", "CDK")

        # ── Section 15: Outputs ─────────────────────────────────────────

        CfnOutput(
            self,
            "ApiUrl",
            value=api.url,
            description="API Gateway URL",
        )
        CfnOutput(
            self,
            "UserPoolId",
            value=user_pool.user_pool_id,
            description="Cognito User Pool ID",
        )
        CfnOutput(
            self,
            "AppClientId",
            value=app_client.user_pool_client_id,
            description="Cognito App Client ID",
        )
        CfnOutput(
            self,
            "ImageBucketName",
            value=image_bucket.bucket_name,
            description="S3 Image Bucket",
        )
        CfnOutput(
            self,
            "CloudFrontDomain",
            value=distribution.distribution_domain_name,
            description="CloudFront Domain",
        )
        CfnOutput(
            self,
            "DynamoTableName",
            value=table.table_name,
            description="DynamoDB Table Name",
        )
        CfnOutput(
            self,
            "ExportBucketName",
            value=export_bucket.bucket_name,
            description="S3 Export Bucket",
        )

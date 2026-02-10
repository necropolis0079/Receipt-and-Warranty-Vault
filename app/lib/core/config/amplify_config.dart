import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// CDK-deployed Cognito User Pool configuration constants.
///
/// Update these values after running `cdk deploy`. They come from the
/// ReceiptVaultStack CfnOutputs: `UserPoolId` and `AppClientId`.
abstract final class AmplifyConstants {
  static const String userPoolId = 'eu-west-1_8vZ07CiUc';
  static const String appClientId = '3mlh4a83p6c9c3e1bcftf3obbd';
  static const String region = 'eu-west-1';
}

/// Configures Amplify with Cognito User Pool settings.
///
/// Since the backend is deployed via AWS CDK (not the Amplify CLI),
/// we provide the configuration manually using the JSON config format
/// understood by `awsCognitoAuthPlugin`.
///
/// Call this once from `main()` before any Amplify operations:
/// ```dart
/// await configureAmplify();
/// runApp(const WarrantyVaultApp());
/// ```
///
/// Safe to call multiple times -- returns immediately if already configured.
/// Swallows errors during hot-restart (Amplify throws when re-configured).
Future<void> configureAmplify() async {
  try {
    if (Amplify.isConfigured) return;

    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugin(authPlugin);

    const userPoolId = AmplifyConstants.userPoolId;
    const appClientId = AmplifyConstants.appClientId;
    const region = AmplifyConstants.region;

    // Manual Amplify config for CDK-deployed Cognito (no amplify_outputs.dart).
    // Uses string interpolation to embed the constants above.
    final amplifyConfig = '''{
      "auth": {
        "plugins": {
          "awsCognitoAuthPlugin": {
            "UserAgent": "aws-amplify-cli/0.1.0",
            "Version": "0.1.0",
            "IdentityManager": {
              "Default": {}
            },
            "CognitoUserPool": {
              "Default": {
                "PoolId": "$userPoolId",
                "AppClientId": "$appClientId",
                "Region": "$region"
              }
            },
            "Auth": {
              "Default": {
                "authenticationFlowType": "USER_SRP_AUTH",
                "socialProviders": ["GOOGLE", "APPLE"],
                "usernameAttributes": ["EMAIL"],
                "signupAttributes": ["EMAIL"],
                "passwordProtectionSettings": {
                  "passwordPolicyMinLength": 8,
                  "passwordPolicyCharacters": [
                    "REQUIRES_LOWERCASE",
                    "REQUIRES_UPPERCASE",
                    "REQUIRES_NUMBERS"
                  ]
                },
                "mfaConfiguration": "OFF",
                "mfaTypes": [],
                "verificationMechanisms": ["EMAIL"]
              }
            }
          }
        }
      }
    }''';

    await Amplify.configure(amplifyConfig);

    safePrint('Amplify configured successfully.');
  } on AmplifyAlreadyConfiguredException {
    // Expected during hot-restart in development.
    safePrint('Amplify was already configured.');
  } catch (e) {
    safePrint('Amplify configuration error: $e');
  }
}

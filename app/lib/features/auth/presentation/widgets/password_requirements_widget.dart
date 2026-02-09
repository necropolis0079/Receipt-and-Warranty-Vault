import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class PasswordRequirementsWidget extends StatelessWidget {
  const PasswordRequirementsWidget({
    super.key,
    required this.password,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    final requirements = [
      _Requirement('At least 8 characters', password.length >= 8),
      _Requirement('Uppercase letter', password.contains(RegExp('[A-Z]'))),
      _Requirement('Lowercase letter', password.contains(RegExp('[a-z]'))),
      _Requirement('Number', password.contains(RegExp('[0-9]'))),
      _Requirement(
          'Special character', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements
          .map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    req.met ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: req.met
                        ? AppColors.primaryGreen
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    req.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: req.met
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Requirement {
  const _Requirement(this.label, this.met);
  final String label;
  final bool met;
}

import 'package:flutter/material.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';

class PolyclinicFilter extends StatelessWidget {
  const PolyclinicFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;

          return ChoiceChip(
            selected: isSelected,
            label: Text(option),
            avatar: Icon(
              option == 'Semua'
                  ? Icons.dashboard_customize_outlined
                  : Icons.medical_services_outlined,
              size: 17,
              color: isSelected ? Colors.white : AppColors.primaryDark,
            ),
            onSelected: (_) => onSelected(option),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            selectedColor: AppColors.primaryDark,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: isSelected ? AppColors.primaryDark : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }
}

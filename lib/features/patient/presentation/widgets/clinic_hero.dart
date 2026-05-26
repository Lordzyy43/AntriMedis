import 'package:flutter/material.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';

class ClinicHero extends StatelessWidget {
  const ClinicHero({super.key, required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.primaryDark,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            const Positioned(
              right: -24,
              bottom: -26,
              child: Icon(
                Icons.local_hospital_outlined,
                size: 150,
                color: Color(0x1FFFFFFF),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppBadge(
                        label: 'Cabang Utama',
                        icon: Icons.apartment_outlined,
                        color: AppColors.primaryDark,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppBadge(
                        label: 'Buka 08.00-20.00',
                        icon: Icons.schedule_outlined,
                        color: AppColors.success,
                        backgroundColor: AppColors.successSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Klinik Sehat Sentosa',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Ambil nomor antrean poli dan pantau estimasi waktu tunggu secara real-time.',
                    style: TextStyle(
                      color: Color(0xDFFFFFFF),
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            email ?? 'Akun pasien',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

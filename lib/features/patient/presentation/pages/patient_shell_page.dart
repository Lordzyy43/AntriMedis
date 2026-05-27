import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../clinic/providers/clinic_provider.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../profile/presentation/profile_completion_page.dart';
import '../../../queue/providers/queue_provider.dart';
import 'notifications_page.dart';
import 'patient_home_page.dart';
import 'patient_queues_page.dart';

class PatientShellPage extends StatefulWidget {
  const PatientShellPage({super.key});

  @override
  State<PatientShellPage> createState() => _PatientShellPageState();
}

class _PatientShellPageState extends State<PatientShellPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicProvider>().load();
      context.read<QueueProvider>().loadHome();
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            PatientHomePage(),
            PatientQueuesPage(),
            NotificationsPage(),
            ProfileCompletionPage(isEditing: true),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: _FloatingPatientNav(
          selectedIndex: _selectedIndex,
          unreadCount: unreadCount,
          onSelected: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) context.read<QueueProvider>().refreshTickets();
            if (index == 2) context.read<NotificationProvider>().load();
          },
        ),
      ),
    );
  }
}

class _FloatingPatientNav extends StatelessWidget {
  const _FloatingPatientNav({
    required this.selectedIndex,
    required this.unreadCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      const _NavItemData(
        icon: Icons.confirmation_number_outlined,
        activeIcon: Icons.confirmation_number,
        label: 'Antrean',
      ),
      _NavItemData(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: 'Notif',
        badgeCount: unreadCount,
      ),
      const _NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Akun',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _FloatingNavItem(
                  data: items[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: data.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 58,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? data.activeIcon : data.icon,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    size: 22,
                  ),
                  if (data.badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          data.badgeCount > 9 ? '9+' : '${data.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

import 'package:flutter/material.dart';

import '../../core/navigation/nav_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/buttons.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        'AI-powered care,\nmedicine safety,\nand learning.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Check interactions, manage reminders, scan prescriptions, and learn medical topics in one calm workspace.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const _MedicalHeroArt(),
                      const Spacer(),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Continue',
                        onPressed: () =>
                            context.replaceWith(const LoginScreen()),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.replaceWith(const LoginScreen()),
                          child: const Text('Skip for now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MedicalHeroArt extends StatelessWidget {
  const _MedicalHeroArt();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF7F5), Color(0xFFF7FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 28,
              right: 34,
              child: _FloatingIcon(icon: Icons.add, color: AppColors.sky),
            ),
            const Positioned(
              left: 28,
              bottom: 46,
              child: _FloatingIcon(
                icon: Icons.monitor_heart_outlined,
                color: AppColors.coral,
              ),
            ),
            Center(
              child: Container(
                width: 184,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x180A3B44),
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.ocean.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: AppColors.ocean,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _MiniLine(width: 126),
                    const SizedBox(height: 9),
                    const _MiniLine(width: 102),
                    const SizedBox(height: 9),
                    const _MiniLine(width: 132),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _MiniLine extends StatelessWidget {
  const _MiniLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

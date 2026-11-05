import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../core/widgets/backdrop.dart';
import '../core/widgets/logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstellationBackdrop(
        nodes: 34,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PulsingLogo(size: 104),
              const SizedBox(height: 26),
              const EpayWordmark(height: 46),
              const SizedBox(height: 12),
              Text(
                AppConfig.tagline,
                style: TextStyle(
                  color: AppColors.subText.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 44),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Enhancement 3: Moved the dark/light mode switch into the settings page.
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: SwitchListTile(
          title: CustomText(
            text: 'Dark Mode',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
          value: themeProvider.isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
        ),
      ),
    );
  }
}

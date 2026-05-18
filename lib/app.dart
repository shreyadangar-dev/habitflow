import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'providers/providers.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';

class HabitFlowApp extends ConsumerWidget {
  const HabitFlowApp({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final s=ref.watch(settingsProv);
    return MaterialApp(
      title:'HabitFlow',
      debugShowCheckedModeBanner:false,
      theme:AT.light(),
      darkTheme:AT.dark(),
      themeMode:s.dark?ThemeMode.dark:ThemeMode.light,
      home:s.onboarded?const HomeScreen():const OnboardingScreen(),
    );
  }
}

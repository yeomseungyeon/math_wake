import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/alarm_list/alarm_list_screen.dart';
import 'features/alarm_ring/alarm_ring_screen.dart';
import 'features/settings/settings_screen.dart';

/// 전역 NavigatorKey — 알림 탭 시 알람 울림 화면으로 이동할 때 사용
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MathWakeApp extends StatelessWidget {
  const MathWakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'MathWake',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const AlarmListScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
        // 알람 울림 화면은 alarmId 인자가 필요해 onGenerateRoute로 처리
        onGenerateRoute: (settings) {
          if (settings.name == '/alarm-ring') {
            final alarmId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => AlarmRingScreen(alarmId: alarmId),
              fullscreenDialog: true,
            );
          }
          return null;
        },
      ),
    );
  }
}

/// 알림 탭 → 알람 울림 화면으로 이동 (어디서든 호출 가능)
void navigateToAlarmRing(String alarmId) {
  navigatorKey.currentState?.pushNamed('/alarm-ring', arguments: alarmId);
}

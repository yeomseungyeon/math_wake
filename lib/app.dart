import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/alarm_list/alarm_list_screen.dart';
import 'features/alarm_ring/alarm_ring_screen.dart';
import 'features/settings/settings_screen.dart';

/// 전역 NavigatorKey — 알림 탭 시 알람 울림 화면으로 이동할 때 사용
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// cold-start 시 navigator 준비 전에 수신된 알람 ID를 보관
String? _pendingAlarmId;

/// 알림 탭 또는 fullScreenIntent → 알람 울림 화면으로 이동
/// navigator가 아직 준비되지 않은 경우 MathWakeApp.initState에서 처리
void navigateToAlarmRing(String alarmId) {
  final state = navigatorKey.currentState;
  if (state != null) {
    state.pushNamed('/alarm-ring', arguments: alarmId);
  } else {
    _pendingAlarmId = alarmId;
  }
}

class MathWakeApp extends StatefulWidget {
  const MathWakeApp({super.key});

  @override
  State<MathWakeApp> createState() => _MathWakeAppState();
}

class _MathWakeAppState extends State<MathWakeApp> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임 완료 후 보류 중인 알람 화면 이동 처리
    // (cold-start 시 navigator 준비 전에 수신된 알람 ID 처리)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingAlarmId;
      if (pending != null) {
        _pendingAlarmId = null;
        navigateToAlarmRing(pending);
      }
    });
  }

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

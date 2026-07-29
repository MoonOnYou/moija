import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/auth/auth_store.dart';
import 'features/splash/splash_screen.dart';
import 'shell/connectivity_gate.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  // 저장된 로그인 세션(JWT + 사용자)을 복원한다.
  await AuthStore.instance.load();
  runApp(const MoijaApp());
}

class MoijaApp extends StatelessWidget {
  const MoijaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모이자',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      theme: ThemeData(
        useMaterial3: true,
        // 배경은 흰색 단일, 강조는 coral 시드.
        scaffoldBackgroundColor: AppColors.bgPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.coral,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgPrimary,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
      // 모든 화면 위에 네트워크 오류 오버레이를 덮을 수 있도록 Navigator를 감싼다.
      builder: (context, child) =>
          ConnectivityGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

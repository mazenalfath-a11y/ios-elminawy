import 'package:flutter/material.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/entering_account/language_selection_screen.dart';
import 'package:flutter_version/screens/entering_account/login_screen.dart';
import 'package:flutter_version/screens/entering_account/pending_verification_screen.dart';
import 'package:flutter_version/screens/mainscreens/main_screen.dart';
import 'package:flutter_version/screens/entering_account/register_screen1.dart';
import 'package:flutter_version/screens/entering_account/register_screen2.dart';
import 'package:flutter_version/data/app_config.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/l10n/app_localizations.dart';
import 'package:flutter_version/utilities/locale_provider.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/rendering.dart';

import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_version/utilities/emulator_checker.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚫 حظر المحاكيات من طبقة Flutter/Dart
  final isEmu = await EmulatorChecker.isEmulator();
  if (isEmu) {
    runApp(const EmulatorBlockedApp());
    return; // ✋ إيقاف استكمال تشغيل باقي التطبيق
  }

  GoogleFonts.config.allowRuntimeFetching = true;

  // debugPaintSizeEnabled = true;

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CompanySettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, dynamic>> _initializeApp() async {
    const storage = FlutterSecureStorage();

    final token = await storage.read(key: "userToken");

    if (token == null || token.isEmpty) {
      if (AppConfig.showLanguageSelectionScreen) {
        return {'route': 'language_selection', 'userData': null};
      }
      return {'route': 'login', 'userData': null};
    }

    try {
      final apiService = ApiService();
      final response = await apiService.request("student/getuser", null, "GET");

      if (response != null && response.statusCode == 200) {
        // User is authenticated - save state
        await storage.write(key: "lastRoute", value: "home");
        return {'route': 'home', 'userData': null};
      } else if (response != null && response.statusCode == 403) {
        // User exists but not verified
        await storage.write(key: "lastRoute", value: "pending");
        return {'route': 'pending', 'userData': null};
      } else {
        // Network error / other error - fall back to cached route
        final lastRoute = await storage.read(key: "lastRoute");
        return {'route': lastRoute ?? 'login', 'userData': null};
      }
    } catch (e) {
      // Offline or exception - fall back to cached route
      final lastRoute = await storage.read(key: "lastRoute");
      return {'route': lastRoute ?? 'login', 'userData': null};
    }
  }

  Future<void> _loadCompanySettings(
    BuildContext context,
    CompanySettingsProvider companySettingsProvider,
    ThemeProvider themeProvider,
  ) async {
    try {
      const storage = FlutterSecureStorage();
      final companyCode = await storage.read(key: "companyCode");
      final companyId = await storage.read(key: "companyId");
      debugPrint(
        "🏢 companyCode=$companyCode companyId=$companyId",
      ); // ← add this

      if (companyCode == null ||
          companyCode.isEmpty ||
          companyId == null ||
          companyId.isEmpty) {
        debugPrint(
          "🏢 Skipping settings fetch — missing companyCode/companyId",
        );
        return;
      }

      final success = await companySettingsProvider.fetchCompanySettings(
        companyCode: companyCode,
        companyId: companyId,
      );

      if (success && companySettingsProvider.settings != null) {
        final colors = companySettingsProvider.settings!.appColors;
        themeProvider.setColorsFromCompanySettings(
          primary: colors.primary,
          secondary: colors.secondary,
          background: colors.background,
          surface: colors.surface,
          textPrimary: colors.textPrimary,
          textSecondary: colors.textSecondary,
          success: colors.success,
          error: colors.error,
        );
      }
    } catch (e) {
      debugPrint('Error loading company settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final companySettingsProvider = Provider.of<CompanySettingsProvider>(
      context,
    );

    // Sync static colors with provider
    AppColors.primaryColor = themeProvider.primaryColor;
    AppColors.secondaryColor = themeProvider.secondaryColor;
    AppColors.backgroundColor = themeProvider.backgroundColor;
    AppColors.surfaceColor = themeProvider.surfaceColor;
    AppColors.textPrimaryColor = themeProvider.textPrimaryColor;
    AppColors.textSecondaryColor = themeProvider.textSecondaryColor;
    AppColors.successColor = themeProvider.successColor;
    AppColors.errorColor = themeProvider.errorColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: AppConfig.teacherName,
      themeMode: themeProvider.currentTheme,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light().copyWith(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        cardColor: AppColors.getCardBackgroundColor(false),
        dividerColor: AppColors.lightDivider,
        colorScheme: const ColorScheme.light().copyWith(
          primary: AppColors.primaryBlue,
          onPrimary: Colors.white,
          surface: AppColors.getSurfaceColor(false),
          onSurface: AppColors.textPrimaryColor,
          secondary: AppColors.secondaryColor,
          onSecondary: Colors.white,
          error: AppColors.errorColor,
          onError: Colors.white,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: AppColors.textPrimaryColor),
          titleMedium: TextStyle(color: AppColors.textPrimaryColor),
          bodyLarge: TextStyle(color: AppColors.textPrimaryColor),
          bodyMedium: TextStyle(color: AppColors.textSecondaryColor),
        ),
        iconTheme: IconThemeData(color: AppColors.getIconColor(false)),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundColor,
          foregroundColor: AppColors.textPrimaryColor,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCardBackground,
        dividerColor: AppColors.darkDivider,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppColors.primaryBlue,
          onPrimary: Colors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          secondary: AppColors.secondaryColor,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: AppColors.darkTextPrimary),
          titleMedium: TextStyle(color: AppColors.darkTextPrimary),
          bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
          bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
        ),
        iconTheme: IconThemeData(color: AppColors.getIconColor(true)),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
        ),
      ),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _initializeApp(),
        builder: (context, snapshot) {
          // Still loading
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          final route = snapshot.data?['route'] ?? 'login';

          // Load company settings in background after app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!companySettingsProvider.isLoading &&
                companySettingsProvider.settings == null) {
              _loadCompanySettings(
                context,
                companySettingsProvider,
                themeProvider,
              );
            }
          });

          // Route to appropriate screen
          if (route == 'home') return MainScreen();
          if (route == 'pending') return PendingVerificationScreen();
          if (route == 'language_selection')
            return const LanguageSelectionScreen();
          return LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/language_selection': (_) => const LanguageSelectionScreen(),
        '/register1': (_) => const RegisterScreen1(),
        '/home': (_) => MainScreen(),
        '/register2': (_) => const RegisterScreen2(
              firstName: '',
              lastName: '',
              username: '',
              password: '',
              companyCode: '',
            ),
      },
    );
  }
}

class EmulatorBlockedApp extends StatelessWidget {
  const EmulatorBlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, color: Colors.red, size: 80),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(ctx)?.notAllowed ??
                      AppLocalizations.of(context)?.notAllowedTxt ??
                      "غير مسموح",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(ctx)?.emulatorBlockMessage ??
                      AppLocalizations.of(context)?.emulatorError ??
                      "هذا التطبيق لا يعمل على المحاكي\nيرجى استخدام جهاز حقيقي",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => exit(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(ctx)?.close ??
                        AppLocalizations.of(context)?.closeDialog ??
                        "إغلاق",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

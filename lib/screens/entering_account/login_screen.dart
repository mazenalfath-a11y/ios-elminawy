import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_version/data/offline_data_service.dart';
import 'package:flutter_version/screens/mainscreens/main_screen.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/models/company_settings_model.dart'
    hide AppColors;
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/utilities/device_utils.dart';
import 'package:flutter_version/widgets/elevated_button.dart';
import 'package:flutter_version/widgets/outlineTextField.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'forget_password_screen.dart';
import 'package:flutter_version/data/app_config.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_version/data/saved_accounts_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _loginUser() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.pleaseEnterUsernamePassword,
          AppColors.errorColor);
      return;
    }

    if (usernameController.text.contains(' ') ||
        RegExp(r'[\u064B-\u0652]').hasMatch(usernameController.text)) {
      _showSnackBar(
          AppLocalizations.of(context)!.usernameNote, AppColors.errorColor);
      return;
    }

    // Check for password minimum length
    if (passwordController.text.length < 8) {
      _showSnackBar(AppLocalizations.of(context)!.passwordMinLength,
          AppColors.errorColor);
      return;
    }

    setState(() => _isLoading = true);

    final deviceId = await DeviceUtils.getDeviceId();
    final data = {
      "email": usernameController.text.trim(),
      "password": passwordController.text.trim(),
      "deviceId": deviceId,
    };

    final response = await _apiService.request("student/Login", data, "POST");
    setState(() => _isLoading = false);

    if (response != null && response.statusCode == 200) {
      final rawToken = response.data["access_token"] ?? response.data["token"];
      final token =
          rawToken != null && rawToken.toString().startsWith("Bearer ")
              ? rawToken.toString().substring(7)
              : rawToken?.toString();
      // In _loginUser(), after saving token
      if (token != null) {
        // login_screen.dart — right after saveToken succeeds
        await _apiService.saveToken(token);
        await OfflineDataService.clearCache();
        print("✅ Token saved: $token");
      } else {
        print("❌ No token received!");
      }

      // Parse and apply company settings (colors, contact info, feature
      // flags, etc.) using the shared CompanySettingsModel/Provider instead
      // of hand-parsing individual fields here.
      if (response.data["companySettings"] != null) {
        try {
          final settingsModel =
              CompanySettingsModel.fromJson(response.data["companySettings"]);

          // NEW — keep cached values in sync
          if (AppConfig.companyCode.isNotEmpty) {
            await _storage.write(
                key: "companyCode", value: AppConfig.companyCode);
          }
          if (settingsModel.companyId.isNotEmpty) {
            await _storage.write(
                key: "companyId", value: settingsModel.companyId);
          }

          final companySettingsProvider =
              Provider.of<CompanySettingsProvider>(context, listen: false);
          await companySettingsProvider.setSettings(settingsModel);
          await _apiService.saveOfflinePdfFlag(settingsModel.enableOfflinePdf);
          await _apiService.saveOfflineVideoFlag(settingsModel.enableOfflineVideo);
          await _apiService.saveOfflineCoursesSettings(
            enabled: settingsModel.enableOfflineCourses,
            daysLimit: settingsModel.offlineCoursesDaysLimit,
          );

          // Apply the theme colors straight from the parsed model - no more
          // manual hex-string parsing here.
          final themeProvider =
              Provider.of<ThemeProvider>(context, listen: false);
          final colors = settingsModel.appColors;
          themeProvider.setPrimaryColor(colors.primary);
          themeProvider.setSecondaryColor(colors.secondary);
          themeProvider.setBackgroundColor(colors.background);
          themeProvider.setSurfaceColor(colors.surface);
          themeProvider.setTextPrimaryColor(colors.textPrimary);
          themeProvider.setTextSecondaryColor(colors.textSecondary);
          themeProvider.setSuccessColor(colors.success);
          themeProvider.setErrorColor(colors.error);
        } catch (e) {
          print("Error parsing company settings: $e");
        }
      }

      if (_rememberMe) {
        await _storage.write(
            key: "savedUsername", value: usernameController.text);
        await _storage.write(
            key: "savedPassword", value: passwordController.text);
      }

      try {
        await SavedAccountsManager.saveAccount(
          email: usernameController.text.trim(),
          password: passwordController.text.trim(),
          companyCode: AppConfig.companyCode,
          companyName: AppConfig.teacherName,
          token: token ?? '',
          studentName:
              '${response.data["FirstName"] ?? ""} ${response.data["LastName"] ?? ""}'
                  .trim(),
          studentId: response.data["_id"] ?? '',
        );
      } catch (e) {
        print('Error saving account: $e');
      }

      _showSnackBar(
          AppLocalizations.of(context)!.loginSuccess, AppColors.successColor);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => MainScreen()));
      });
    } else {
      String errorMsg;
      if (response?.statusCode == 403) {
        errorMsg = response?.data is String
            ? response!.data
            : AppLocalizations.of(context)?.accountRegisteredOnAnotherDevice ?? "هذا الحساب مسجل على جهاز آخر. يرجى التواصل مع المدرس لإعادة تعيين الجهاز.";
      } else {
        final rawData = response?.data;
        final rawDataStr = rawData?.toString().toLowerCase() ?? "";

        // Detect common English error messages to show localized Arabic version
        if (rawDataStr.contains("email or password") ||
            rawDataStr.contains("not correct") ||
            rawDataStr.contains("invalid") ||
            rawData == null) {
          errorMsg = AppLocalizations.of(context)!.invalidLogin;
        } else {
          // Attempt to extract message from Map, or use raw data string
          errorMsg = (rawData is Map)
              ? (rawData["message"]?.toString() ??
                  rawData["error"]?.toString() ??
                  rawData.toString())
              : rawData.toString();
        }
      }
      _showSnackBar(errorMsg, AppColors.errorColor);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: color,
      content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    isDark
                        ? AppColors.primaryColor.withOpacity(0.1)
                        : AppColors.lightGrad,
                    isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                  ],
                  stops: const [0.0, 0.78],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 32, right: 32),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 10,
                        top: 20,
                        child: Image.asset(
                          "assets/images/sparkles.png",
                          height: 40,
                          width: 40,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  right: 120,
                                  child: _buildGif(
                                    'assets/images/emojis/Astronaut.gif',
                                    scale: 0.6,
                                    opacity: 0.6,
                                  ),
                                ),
                                Positioned(
                                  left: 120,
                                  child: _buildGif(
                                    'assets/images/emojis/Judge.gif',
                                    scale: 0.6,
                                    opacity: 0.6,
                                  ),
                                ),
                                Positioned(
                                  left: 75,
                                  child: _buildGif(
                                    'assets/images/emojis/Detective.gif',
                                    scale: 0.9,
                                    opacity: 0.75,
                                  ),
                                ),
                                Positioned(
                                  right: 75,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..scale(-1.0, 1.0),
                                    child: _buildGif(
                                      'assets/images/emojis/Scientist.gif',
                                      scale: 0.9,
                                      opacity: 0.75,
                                    ),
                                  ),
                                ),
                                _buildGif(
                                  'assets/images/emojis/Student.gif',
                                  scale: 1.2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // ─── BODY ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcome,
                    style: GoogleFonts.cairo(
                      color: AppColors.getTextColor(isDark),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!
                        .loginToPlatform(AppConfig.teacherName),
                    style: GoogleFonts.cairo(
                      color: AppColors.getTextSecondaryColor(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── Form card ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.getBorderColor(isDark),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadowColor(isDark),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        outlineTextField(
                          hint: AppLocalizations.of(context)!.username,
                          controller: usernameController,
                          icon: PhosphorIconsFill.user,
                          context: context,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.usernameNote,
                              style: GoogleFonts.cairo(
                                  color:
                                      AppColors.getTextSecondaryColor(isDark),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        outlineTextField(
                          hint: AppLocalizations.of(context)!.password,
                          controller: passwordController,
                          icon: PhosphorIconsFill.lockKey,
                          isPassword: true,
                          context: context,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.passwordMinLength,
                              style: GoogleFonts.cairo(
                                  color:
                                      AppColors.getTextSecondaryColor(isDark),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    checkboxTheme: CheckboxThemeData(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      checkColor: WidgetStateProperty.all(
                                          AppColors.white),
                                      fillColor:
                                          WidgetStateProperty.resolveWith(
                                        (states) => states
                                                .contains(WidgetState.selected)
                                            ? AppColors.sky(isDark)
                                            : AppColors.getBorderColor(isDark),
                                      ),
                                      side: BorderSide(
                                        color: AppColors.getBorderColor(isDark),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v!),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  AppLocalizations.of(context)?.rememberMe ?? "تذكرني",
                                  style: GoogleFonts.cairo(
                                      color: AppColors.getTextSecondaryColor(
                                          isDark),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ForgetPasswordScreen()),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.forgotPassword ?? "نسيت كلمة المرور؟",
                                style: GoogleFonts.cairo(
                                  color: AppColors.sky(isDark),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButtonWidget(
                          onPressed: _loginUser,
                          text: AppLocalizations.of(context)!.login,
                          isLoading: _isLoading,
                          height: 56,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.dontHaveAccount,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextSecondaryColor(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(right: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register1'),
                        child: Text(
                          AppLocalizations.of(context)!.createAccount,
                          style: GoogleFonts.cairo(
                            color: AppColors.sky(isDark),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGif(String assetPath, {double scale = 1, double opacity = 1}) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Image.asset(
          assetPath,
          height: 150,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/widgets/elevated_button.dart';
import 'package:flutter_version/widgets/outlineTextField.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/widgets/step_progress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen2.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/data/app_config.dart';
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/models/company_settings_model.dart'
    hide AppColors;
import '../../l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterScreen1 extends StatefulWidget {
  const RegisterScreen1({Key? key}) : super(key: key);

  @override
  State<RegisterScreen1> createState() => _RegisterScreen1State();
}

class _RegisterScreen1State extends State<RegisterScreen1> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final companyCodeController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final ApiService _apiService = ApiService();
  bool isLoading = false;
  String? selectedCompanyCode;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _verifyAndNavigate() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Use AppConfig.companyCode if available, otherwise check selected company or user input
      final companyCode = AppConfig.companyCode.isNotEmpty
          ? AppConfig.companyCode
          : (selectedCompanyCode ?? companyCodeController.text.trim());

      final response = await _apiService.request(
        "student/company/settings?companyCode=$companyCode",
        {},
        "GET",
      );

      setState(() {
        isLoading = false;
      });

      if (response != null && response.statusCode == 200) {
        try {
          final settingsModel = CompanySettingsModel.fromJson(response.data);

          await _storage.write(key: "companyCode", value: companyCode);
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

        // Company code is valid, navigate to next screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterScreen2(
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                username: usernameController.text.trim(),
                password: passwordController.text.trim(),
                companyCode: companyCode,
              ),
            ),
          );
        }
      } else if (response != null && response.statusCode == 404) {
        _showSnackBar(AppLocalizations.of(context)!.companyCodeInvalid);
      } else {
        _showSnackBar(AppLocalizations.of(context)!.companyCodeError);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar(AppLocalizations.of(context)!.errorOccurred(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              isDark
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : AppColors.lightGrad,
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
            ],
            stops: const [0.0, 0.78],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 70, right: 20, left: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.createAccount,
                          style: GoogleFonts.cairo(
                            color: theme.textTheme.titleLarge?.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.getBorderColor(
                                      Provider.of<ThemeProvider>(context)
                                          .isDarkMode),
                                  width: 1),
                              color: AppColors.getInputBackgroundColor(
                                  Provider.of<ThemeProvider>(context)
                                      .isDarkMode)),
                          child: IconButton(
                            icon: Icon(
                              PhosphorIconsRegular.arrowLeft,
                              color: AppColors.getInputTextColor(
                                  Provider.of<ThemeProvider>(context)
                                      .isDarkMode),
                              size: 30,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  buildStepProgress(),
                  const SizedBox(height: 32),
                  Container(
                    height: size.height * 0.65,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.getBorderColor(
                            Provider.of<ThemeProvider>(context).isDarkMode),
                        width: 1,
                      ),
                      color: AppColors.getCardBackgroundColor(isDark),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: outlineTextField(
                                      hint: AppLocalizations.of(context)!
                                          .firstName,
                                      icon: PhosphorIconsFill.user,
                                      controller: firstNameController,
                                      context: context),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: outlineTextField(
                                      hint: AppLocalizations.of(context)!
                                          .lastName,
                                      icon: PhosphorIconsFill.user,
                                      controller: lastNameController,
                                      context: context),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.nameNote,
                                  style: GoogleFonts.cairo(
                                      color:
                                          AppColors.getSecondHintColor(isDark),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            outlineTextField(
                              hint: AppLocalizations.of(context)!.username,
                              icon: PhosphorIconsFill.at,
                              controller: usernameController,
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
                                          AppColors.getSecondHintColor(isDark),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                            if (AppConfig.companyCode.isEmpty) ...[
                              const SizedBox(height: 16),
                              if (AppConfig.availableCompanies.isNotEmpty)
                                _buildCompanyDropdown()
                              else
                                outlineTextField(
                                  hint:
                                      AppLocalizations.of(context)!.companyCode,
                                  icon: PhosphorIconsFill.hash,
                                  controller: companyCodeController,
                                  context: context,
                                ),
                              const SizedBox(height: 5),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .companyCodeNote,
                                    style: GoogleFonts.cairo(
                                        color: AppColors.getSecondHintColor(
                                            isDark),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900),
                                    textAlign: TextAlign.end,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .companyCodeNote1,
                                    style: GoogleFonts.cairo(
                                        color: AppColors.getSecondHintColor(
                                            isDark),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                outlineTextField(
                                  hint: AppLocalizations.of(context)!.password,
                                  icon: Icons.lock,
                                  controller: passwordController,
                                  context: context,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  AppLocalizations.of(context)!
                                      .passwordMinLength,
                                  style: GoogleFonts.cairo(
                                      color:
                                          AppColors.getSecondHintColor(isDark),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            outlineTextField(
                              hint:
                                  AppLocalizations.of(context)!.confirmPassword,
                              icon: Icons.lock,
                              controller: confirmPasswordController,
                              context: context,
                              isPassword: true,
                            ),
                            const SizedBox(height: 30),
                            ElevatedButtonWidget(
                                onPressed:
                                    isLoading ? null : _verifyAndNavigate,
                                text: AppLocalizations.of(context)!.next,
                                height: 56,
                                icon: Icon(PhosphorIconsBold.arrowRight,
                                    color: Colors.white)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _validateInputs() {
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.fillAllFields);
      return false;
    }

    // Check if First and Last name contain valid Arabic or English characters
    final nameRegex = RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$');
    if (!nameRegex.hasMatch(firstNameController.text.trim()) ||
        !nameRegex.hasMatch(lastNameController.text.trim())) {
      _showSnackBar(AppLocalizations.of(context)!.nameNote);
      return false;
    }

    // Only validate company code if it's not set in AppConfig
    if (AppConfig.companyCode.isEmpty) {
      // Check if using dropdown or text field
      if (AppConfig.availableCompanies.isNotEmpty) {
        // Validate dropdown selection
        if (selectedCompanyCode == null || selectedCompanyCode!.isEmpty) {
          _showSnackBar(AppLocalizations.of(context)!.fillAllFields);
          return false;
        }
      } else {
        // Validate text field input
        if (companyCodeController.text.trim().isEmpty) {
          _showSnackBar(AppLocalizations.of(context)!.fillAllFields);
          return false;
        }
        if (companyCodeController.text.trim().length < 3) {
          _showSnackBar(AppLocalizations.of(context)!.companyCodeMinLength);
          return false;
        }
      }
    }
    if (usernameController.text.trim().length < 3) {
      _showSnackBar(AppLocalizations.of(context)!.usernameMinLength);
      return false;
    }
    // Check for Arabic Harakat (vowels) or spaces in username
    if (usernameController.text.contains(' ') ||
        RegExp(r'[\u064B-\u0652]').hasMatch(usernameController.text)) {
      _showSnackBar(AppLocalizations.of(context)!.usernameNote);
      return false;
    }
    if (passwordController.text.trim().length < 8) {
      _showSnackBar(AppLocalizations.of(context)!.passwordMinLength);
      return false;
    }
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showSnackBar(AppLocalizations.of(context)!.passwordMismatch);
      return false;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(usernameController.text.trim())) {
      _showSnackBar(AppLocalizations.of(context)!.usernameAlpha);
      return false;
    }
    return true;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          msg,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: selectedCompanyCode,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.companyCode,
        prefixIcon: Icon(PhosphorIconsFill.chalkboardTeacher,
            color: AppColors.getIconColor(isDark)),
        hintStyle:
            GoogleFonts.cairo(color: AppColors.getInputHintColor(isDark)),
        filled: true,
        fillColor: AppColors.getInputBackgroundColor(isDark),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.getInputBorderColor(isDark),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      style: TextStyle(color: AppColors.getInputTextColor(isDark)),
      dropdownColor: AppColors.getInputBackgroundColor(isDark),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.getIconColor(isDark)),
      items: AppConfig.availableCompanies.map((company) {
        return DropdownMenuItem<String>(
          value: company['code'],
          child: Text(
            company['name'] ?? '',
            style: GoogleFonts.cairo(
              color: AppColors.getInputTextColor(isDark),
            ),
            textAlign: TextAlign.right,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedCompanyCode = newValue;
        });
      },
    );
  }
}

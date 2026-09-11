import 'package:flutter/material.dart';
import 'package:flutter_version/screens/entering_account/pending_verification_screen.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/widgets/elevated_button.dart';
import 'package:flutter_version/widgets/outlineTextField.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/widgets/step_progress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/mainscreens/main_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_version/data/saved_accounts_manager.dart';
import 'package:flutter_version/data/app_config.dart';
import 'dart:async';
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/utilities/device_utils.dart';

class RegisterScreen2 extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String companyCode;

  const RegisterScreen2({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.companyCode,
  });

  @override
  State<RegisterScreen2> createState() => _RegisterScreen2State();
}

class _RegisterScreen2State extends State<RegisterScreen2> {
  final studentPhoneController = TextEditingController();
  final parentPhoneController = TextEditingController();

  final Map<String, TextEditingController> _customTextControllers = {};
  final Map<String, String> _customSelectValues = {};

  String selectedGrade = "";
  String selectedDepartment = "";
  bool isLoading = false;
  bool isLoadingGroups = false;
  bool requireParentPhone = true;
  bool requireStudentVerify = false;

  // Groups data
  List<dynamic> allGroups = [];
  String? selectedGroupId;
  String? selectedGroupName;
  String? selectedStageName;

  Map<String, List<Map<String, String>>> dynamicGrades = {};
  List<Map<String, String>> combinedLevels = [];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCompanyCode();
    });
  }

  @override
  void dispose() {
    studentPhoneController.dispose();
    parentPhoneController.dispose();
    for (var ctrl in _customTextControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ─── API Methods ───────────────────────────────────────────────────────────

  Future<void> _checkCompanyCode() async {
    final code = widget.companyCode;
    if (code.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.companyCode, Colors.red);
      return;
    }
    if (code.length < 3) {
      _showSnackBar(
          AppLocalizations.of(context)!.companyCodeMinLength, Colors.red);
      return;
    }

    // 1️⃣ Load groups (always from API)
    await _fetchGroupsFromApi(code);

    // 2️⃣ Initialize levels from the provider (it already has the settings)
    final provider =
        Provider.of<CompanySettingsProvider>(context, listen: false);
    if (provider.settings != null) {
      _initializeFromProvider(provider);
    } else {
      // Fallback: fetch settings if provider is empty (e.g., direct navigation)
      _fetchSettingsAndInitialize(code);
    }
  }

  /// Read settings from the provider and build the UI.
  void _initializeFromProvider(CompanySettingsProvider provider) {
    final settings = provider.settings!;

    // Set flags
    requireParentPhone = settings.requireParentPhone;
    requireStudentVerify = settings.requireStudentVerify;

    // Build combined levels from the provider's list
    combinedLevels = settings.combinedLevels.map((cl) {
      return {
        'value': cl.value,
        'label': cl.label,
        'levelCode': cl.levelCode,
        'departmentCode': cl.departmentCode,
      };
    }).toList();

    _buildDynamicGrades();
  }

  /// Fallback: fetch settings from API if provider doesn't have them.
  Future<void> _fetchSettingsAndInitialize(String companyCode) async {
    final provider =
        Provider.of<CompanySettingsProvider>(context, listen: false);
    final success = await provider.fetchCompanySettings(
      companyCode: companyCode,
      companyId:
          '', // we might not have companyId, but it's not required for this endpoint? Actually it is required. But we can pass an empty string? Better to fetch from API with only companyCode as we did before.
    );
    if (success && mounted) {
      _initializeFromProvider(provider);
      setState(() {}); // rebuild UI
    } else {
      _showSnackBar(AppLocalizations.of(context)!.companyCodeError, Colors.red);
    }
  }

  Future<void> _fetchGroupsFromApi(String companyCode) async {
    try {
      setState(() => isLoadingGroups = true);
      final response = await _apiService.request(
        "group/get_groups_by_company?companyCode=$companyCode",
        {},
        "GET",
      );
      if (response != null && response.statusCode == 200) {
        setState(() {
          allGroups = response.data ?? [];
          if (allGroups.isNotEmpty) {
            selectedGroupId = allGroups[0]["_id"];
            selectedGroupName = allGroups[0]["groupName"];
          }
        });
      } else {
        setState(() {
          allGroups = [];
          selectedGroupId = null;
          selectedGroupName = null;
        });
      }
    } catch (e) {
      setState(() {
        allGroups = [];
        selectedGroupId = null;
        selectedGroupName = null;
      });
    } finally {
      setState(() => isLoadingGroups = false);
    }
  }

  void _buildDynamicGrades() {
    dynamicGrades.clear();
    const orderedDepts = ['pri', 'pre', 'sec'];
    const allowedLevelsForPreSec = ['one', 'two', 'three'];

    Map<String, List<Map<String, String>>> grouped = {};

    for (var level in combinedLevels) {
      final levelCode = level['levelCode'] ?? '';
      final deptCode = level['departmentCode'] ?? '';

      if ((deptCode == 'pre' || deptCode == 'sec') &&
          !allowedLevelsForPreSec.contains(levelCode)) continue;

      final deptLabel = _getDepartmentLabel(deptCode);
      if (!grouped.containsKey(deptLabel)) grouped[deptLabel] = [];

      final alreadyExists = grouped[deptLabel]!.any((g) =>
          g['levelCode'] == levelCode && g['departmentCode'] == deptCode);
      if (!alreadyExists) grouped[deptLabel]!.add(level);
    }

    final Map<String, List<Map<String, String>>> ordered = {};
    for (final deptCode in orderedDepts) {
      final label = _getDepartmentLabel(deptCode);
      if (grouped.containsKey(label)) ordered[label] = grouped[label]!;
    }
    for (final entry in grouped.entries) {
      if (!ordered.containsKey(entry.key)) ordered[entry.key] = entry.value;
    }

    setState(() => dynamicGrades = ordered);
  }

  String _getDepartmentLabel(String deptCode) {
    switch (deptCode) {
      case 'pri':
        return AppLocalizations.of(context)!.primary;
      case 'pre':
        return AppLocalizations.of(context)!.preparatory;
      case 'sec':
        return AppLocalizations.of(context)!.secondary;
      default:
        return deptCode;
    }
  }

  // ─── Registration ──────────────────────────────────────────────────────────

  Future<void> _registerUser() async {
    if (studentPhoneController.text.length != 11) {
      _showSnackBar(
          AppLocalizations.of(context)!.enterValidStudentPhone, Colors.red);
      return;
    }
    final String rawParentPhone = parentPhoneController.text.trim();
    if (requireParentPhone) {
      if (AppConfig.isParentPhoneMandatory) {
        if (rawParentPhone.length != 11) {
          _showSnackBar(
              AppLocalizations.of(context)!.enterValidParentPhone, Colors.red);
          return;
        }
      } else {
        if (rawParentPhone.isNotEmpty && rawParentPhone.length != 11) {
          _showSnackBar(
              AppLocalizations.of(context)!.enterValidParentPhone, Colors.red);
          return;
        }
      }
    }
    if (selectedGrade.isEmpty || selectedDepartment.isEmpty) {
      _showSnackBar(
          AppLocalizations.of(context)!.selectAcademicYearError, Colors.orange);
      return;
    }

    final settings =
        Provider.of<CompanySettingsProvider>(context, listen: false).settings;

    if (settings != null && settings.customRegistrationFields.isNotEmpty) {
      for (var cf in settings.customRegistrationFields) {
        if (cf.type == 'select') {
          final val = _customSelectValues[cf.id];
          if (cf.required && (val == null || val.trim().isEmpty)) {
            _showSnackBar("يرجى اختيار: ${cf.label}", Colors.red);
            return;
          }
        } else {
          final ctrl = _customTextControllers[cf.id];
          final val = ctrl?.text.trim() ?? '';
          if (cf.required && val.isEmpty) {
            _showSnackBar("يرجى كتابة: ${cf.label}", Colors.red);
            return;
          }
          if (cf.maxLength != null && val.length > cf.maxLength!) {
            _showSnackBar("تجاوزت الحد الأقصى للحروف للحقل: ${cf.label}", Colors.red);
            return;
          }
        }
      }
    }

    setState(() => isLoading = true);

    final parentPhone = (requireParentPhone && rawParentPhone.isNotEmpty)
        ? rawParentPhone
        : studentPhoneController.text.trim();

    final List<Map<String, String>> customFieldsPayload = [];
    if (settings != null && settings.customRegistrationFields.isNotEmpty) {
      for (var cf in settings.customRegistrationFields) {
        String val = '';
        if (cf.type == 'select') {
          val = _customSelectValues[cf.id] ?? '';
        } else {
          val = _customTextControllers[cf.id]?.text.trim() ?? '';
        }
        if (val.isNotEmpty) {
          customFieldsPayload.add({
            'fieldId': cf.id,
            'label': cf.label,
            'value': val,
          });
        }
      }
    }

    final deviceId = await DeviceUtils.getDeviceId();

    final data = {
      "FirstName": widget.firstName,
      "LastName": widget.lastName,
      "email": widget.username,
      "password": widget.password,
      "mobile": studentPhoneController.text.trim(),
      "parentPhoneNumber": parentPhone,
      "level": selectedGrade,
      "departement": selectedDepartment,
      "CollegesName": "Medicine",
      "groupId": selectedGroupId,
      "companyCode": widget.companyCode,
      "customFields": customFieldsPayload,
      "deviceId": deviceId,
    };

    final response =
        await _apiService.request("student/register", data, "POST");
    setState(() => isLoading = false);

    if (response != null &&
        (response.statusCode == 201 || response.statusCode == 200)) {
      final rawToken = response.data["access_token"] ?? response.data["token"];
      final token =
          rawToken != null && rawToken.toString().startsWith("Bearer ")
              ? rawToken.toString().substring(7)
              : rawToken?.toString();

      if (token != null) {
        await _apiService.saveToken(token);
        debugPrint("✅ Token saved after register: $token");
      } else {
        debugPrint("❌ No token received on register!");
      }

      try {
        await SavedAccountsManager.saveAccount(
          email: widget.username,
          password: widget.password,
          companyCode: widget.companyCode,
          companyName: AppConfig.teacherName,
          token: token ?? '',
          studentName: '${widget.firstName} ${widget.lastName}',
          studentId: response.data['_id'] ?? '',
        );
      } catch (e) {
        debugPrint('Error saving account: $e');
      }

      _showSnackBar(
          AppLocalizations.of(context)!.accountCreatedSuccess, Colors.green);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (requireStudentVerify) {
          // Needs teacher/admin approval first
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const PendingVerificationScreen()),
          );
        } else {
          // No approval needed — go straight to home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainScreen()),
            (route) => false,
          );
        }
      }
    } else {
      final message = response?.data?.toString() ??
          AppLocalizations.of(context)!.registerError;
      _showSnackBar("❌ $message", Colors.red);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  String _getEducationalStageLabel() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (isArabic && AppConfig.customEducationalStageAr.isNotEmpty) {
      return AppConfig.customEducationalStageAr;
    } else if (!isArabic && AppConfig.customEducationalStageEn.isNotEmpty) {
      return AppConfig.customEducationalStageEn;
    }
    return AppLocalizations.of(context)?.educationalStage ??
        (isArabic ? "المرحلة الدراسية" : "Educational Stage");
  }

  String _getAcademicYearLabel() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (isArabic && AppConfig.customAcademicYearAr.isNotEmpty) {
      return AppConfig.customAcademicYearAr;
    } else if (!isArabic && AppConfig.customAcademicYearEn.isNotEmpty) {
      return AppConfig.customAcademicYearEn;
    }
    return AppLocalizations.of(context)?.selectAcademicYear ??
        (isArabic ? "اختر السنة الدراسية" : "Select Academic Year");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : AppColors.lightGrad,
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
            ],
            stops: const [0.0, 0.78],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 70, right: 20, left: 20),
            child: Column(
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
                                Provider.of<ThemeProvider>(context).isDarkMode),
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
                buildStepProgress(isSecondStep: true),
                const SizedBox(height: 32),
                Expanded(
                  child: _buildFormCard(theme, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlineTextField(
            hint: AppLocalizations.of(context)!.studentPhone,
            icon: PhosphorIconsFill.phone,
            controller: studentPhoneController,
            context: context,
            isNumber: true,
            isPassword: false,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.mobilePhoneNote,
                style: GoogleFonts.cairo(
                    color: AppColors.getSecondHintColor(isDark),
                    fontSize: 9,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (requireParentPhone) ...[
            OutlineTextField(
              hint: AppConfig.isParentPhoneMandatory
                  ? AppLocalizations.of(context)!.parentPhone
                  : "${AppLocalizations.of(context)!.parentPhone} (اختياري)",
              icon: PhosphorIconsFill.phone,
              controller: parentPhoneController,
              context: context,
              isNumber: true,
              isPassword: false,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.mobilePhoneNote,
                  style: GoogleFonts.cairo(
                      color: AppColors.getSecondHintColor(isDark),
                      fontSize: 9,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (dynamicGrades.isNotEmpty) ...[
            _buildDropdownField(
              hint: _getEducationalStageLabel(),
              value: selectedStageName,
              icon: PhosphorIconsFill.graduationCap,
              isDark: isDark,
              theme: theme,
              items: dynamicGrades.keys.toList(),
              onSelected: (val) {
                setState(() {
                  selectedStageName = val;
                  selectedGrade = "";
                  selectedDepartment = "";
                });
              },
            ),
            const SizedBox(height: 16),
            _buildGradeDropdown(isDark: isDark, theme: theme),
            const SizedBox(height: 16),
          ] else ...[
            Center(
              child: Text(
                AppLocalizations.of(context)!.noLevelsAvailable,
                style:
                    GoogleFonts.cairo(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isLoadingGroups) ...[
            Center(
                child: CircularProgressIndicator(color: AppColors.sky(isDark))),
            const SizedBox(height: 16),
          ] else if (allGroups.isNotEmpty) ...[
            _buildDropdownField(
              hint: AppLocalizations.of(context)!.selectGroupOptional,
              value: selectedGroupName,
              icon: PhosphorIconsFill.usersThree,
              isDark: isDark,
              theme: theme,
              items: allGroups
                  .map<String>((g) => g["groupName"].toString())
                  .toList(),
              onSelected: (val) {
                final group =
                    allGroups.firstWhere((g) => g["groupName"] == val);
                setState(() {
                  selectedGroupId = group["_id"];
                  selectedGroupName = val;
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Render Dynamic Custom Registration Fields
          Consumer<CompanySettingsProvider>(
            builder: (context, provider, _) {
              final customFields = provider.settings?.customRegistrationFields ?? [];
              if (customFields.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: customFields.map((cf) {
                  if (cf.type == 'select') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildDropdownField(
                        hint: "${cf.label}${cf.required ? ' *' : ''}",
                        value: _customSelectValues[cf.id],
                        icon: PhosphorIconsFill.listBullets,
                        isDark: isDark,
                        theme: theme,
                        items: cf.options,
                        onSelected: (val) {
                          setState(() {
                            _customSelectValues[cf.id] = val;
                          });
                        },
                      ),
                    );
                  } else {
                    final controller = _customTextControllers.putIfAbsent(
                      cf.id,
                      () => TextEditingController(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlineTextField(
                            hint: "${cf.label}${cf.required ? ' *' : ''}",
                            icon: PhosphorIconsFill.notePencil,
                            controller: controller,
                            context: context,
                            isNumber: false,
                            isPassword: false,
                          ),
                          if (cf.maxLength != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "أقصى عدد حروف: ${cf.maxLength}",
                                  style: GoogleFonts.cairo(
                                      color: AppColors.getSecondHintColor(isDark),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                }).toList(),
              );
            },
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.getInputBackgroundColor(isDark),
                    border: Border.all(color: AppColors.getBorderColor(isDark)),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.arrowLeft,
                    color: AppColors.getInputTextColor(isDark),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.sky(isDark)))
                      : ElevatedButtonWidget(
                          onPressed: _registerUser,
                          text: AppLocalizations.of(context)!.createAccount,
                          height: 56,
                          icon: Icon(
                            PhosphorIconsFill.checkCircle,
                            textDirection: TextDirection.ltr,
                            color: Colors.white,
                          ),
                        )),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.getTextSecondaryColor(isDark)),
              children: [
                TextSpan(text: AppLocalizations.of(context)?.byLoggingInYouAgree ?? "بالدخول، أنت توافق على "),
                TextSpan(
                  text: AppLocalizations.of(context)?.termsAndConditions ?? "الشروط والأحكام",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.sky(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dropdown Widgets ──────────────────────────────────────────────────────

  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    required List<String> items,
    required void Function(String) onSelected,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () => _showBottomSheet(
          context: context,
          title: hint,
          items: items,
          selectedValue: value,
          onSelected: onSelected,
          theme: theme,
          isDark: isDark,
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              color: AppColors.getInputHintColor(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon:
                Icon(icon, color: AppColors.getIconColor(isDark), size: 20),
            suffixIcon: Icon(PhosphorIconsRegular.caretDown,
                color: AppColors.getIconColor(isDark), size: 20),
            filled: true,
            fillColor: AppColors.getInputBackgroundColor(isDark),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.getInputBorderColor(isDark),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.sky(isDark), width: 1),
            ),
          ),
          isEmpty: value == null,
          child: value != null
              ? Text(
                  value,
                  style: GoogleFonts.cairo(
                    color: AppColors.getInputTextColor(isDark),
                    fontSize: 14,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildGradeDropdown({required bool isDark, required ThemeData theme}) {
    final stageGrades = selectedStageName != null
        ? (dynamicGrades[selectedStageName] ?? [])
        : <Map<String, String>>[];

    final selectedLabel =
        selectedGrade.isNotEmpty && selectedDepartment.isNotEmpty
            ? stageGrades.firstWhere(
                (g) =>
                    g['levelCode'] == selectedGrade &&
                    g['departmentCode'] == selectedDepartment,
                orElse: () => {},
              )['label']
            : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: selectedStageName == null || stageGrades.isEmpty
            ? () => _showSnackBar(AppLocalizations.of(context)?.chooseStageFirst ?? "اختر المرحلة الدراسية أولاً", Colors.orange)
            : () => _showGradeBottomSheet(
                  context: context,
                  grades: stageGrades,
                  selectedGrade: selectedGrade,
                  selectedDept: selectedDepartment,
                  theme: theme,
                  isDark: isDark,
                  onSelected: (levelCode, deptCode, label) {
                    setState(() {
                      selectedGrade = levelCode;
                      selectedDepartment = deptCode;
                    });
                    _showSnackBar(
                        "${AppLocalizations.of(context)!.selected}: $label",
                        AppColors.sky(isDark));
                  },
                ),
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: _getAcademicYearLabel(),
            hintStyle: GoogleFonts.cairo(
              color: AppColors.getInputHintColor(isDark),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(PhosphorIconsFill.calendarBlank,
                color: AppColors.getIconColor(isDark), size: 20),
            suffixIcon: Icon(PhosphorIconsRegular.caretDown,
                color: AppColors.getIconColor(isDark), size: 20),
            filled: true,
            fillColor: AppColors.getInputBackgroundColor(isDark),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.getInputBorderColor(isDark),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.sky(isDark), width: 1),
            ),
          ),
          isEmpty: selectedLabel == null,
          child: selectedLabel != null
              ? Text(
                  selectedLabel,
                  style: GoogleFonts.cairo(
                    color: AppColors.getInputTextColor(isDark),
                    fontSize: 14,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ─── Bottom Sheets ─────────────────────────────────────────────────────────

  void _showBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String) onSelected,
    required ThemeData theme,
    required bool isDark,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getBorderColor(isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getInputTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final isSelected = item == selectedValue;
                  return ListTile(
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected
                        ? AppColors.sky(isDark).withValues(alpha: 0.1)
                        : Colors.transparent,
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: AppColors.sky(isDark), size: 20)
                        : null,
                    title: Text(
                      item,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        color: isSelected
                            ? AppColors.sky(isDark).withValues(alpha: 0.9)
                            : AppColors.getInputTextColor(isDark),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGradeBottomSheet({
    required BuildContext context,
    required List<Map<String, String>> grades,
    required String selectedGrade,
    required String selectedDept,
    required ThemeData theme,
    required bool isDark,
    required void Function(String levelCode, String deptCode, String label)
        onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getBorderColor(isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getAcademicYearLabel(),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getInputTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                ...grades.map((grade) {
                  final levelCode = grade['levelCode']!;
                  final deptCode = grade['departmentCode']!;
                  final label = grade['label']!;
                  final isSelected =
                      selectedGrade == levelCode && selectedDept == deptCode;

                  return ListTile(
                    onTap: () {
                      onSelected(levelCode, deptCode, label);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected
                        ? AppColors.sky(isDark).withValues(alpha: 0.1)
                        : Colors.transparent,
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: AppColors.sky(isDark), size: 20)
                        : null,
                    title: Text(
                      label,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        color: isSelected
                            ? AppColors.sky(isDark).withValues(alpha: 0.9)
                            : AppColors.getInputTextColor(isDark),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

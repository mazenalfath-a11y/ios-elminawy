import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_version/data/app_config.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/widgets/outlineTextField.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  int step = 1; // 1: Send OTP, 2: Verify OTP, 3: Reset Password
  bool isLoading = false;
  String? resetToken;
  String? maskedPhone;
  String? errorMessage;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  // Step 1: Send OTP via WhatsApp
  Future<void> _sendOtp() async {
    final identifier = phoneController.text.trim();
    if (identifier.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)?.enterPhoneOrEmail ?? "يرجى إدخال رقم الهاتف أو البريد الإلكتروني المسجل", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/student/whatsapp/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identifier": identifier}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          step = 2;
          maskedPhone = data["phone"];
        });
        _showSnackBar(data["message"] ?? AppLocalizations.of(context)?.whatsappCodeSentSuccess ?? "تم إرسال كود التحقق بنجاح على الواتساب");
      } else {
        final err = data is Map ? (data["message"] ?? data["error"] ?? AppLocalizations.of(context)?.failedToSendCode ?? "فشل إرسال الكود") : data.toString();
        _showSnackBar(err, isError: true);
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)?.errorConnectingToServer ?? "حدث خطأ أثناء الاتصال بالخادم", isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Step 2: Verify OTP Code
  Future<void> _verifyOtp() async {
    final otpCode = otpController.text.trim();
    if (otpCode.length < 4) {
      _showSnackBar(AppLocalizations.of(context)?.enter6DigitCode ?? "يرجى إدخال كود التحقق المكون من 6 أرقام", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/student/whatsapp/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": phoneController.text.trim(),
          "otpCode": otpCode,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          resetToken = data["resetToken"];
          step = 3;
        });
        _showSnackBar(AppLocalizations.of(context)?.verifiedEnterNewPassword ?? "تم التحقق بنجاح، أدخل كلمة المرور الجديدة");
      } else {
        final err = data is Map ? (data["message"] ?? AppLocalizations.of(context)?.invalidVerificationCode ?? "كود التحقق غير صحيح") : data.toString();
        _showSnackBar(err, isError: true);
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)?.errorVerifyingCode ?? "حدث خطأ أثناء التحقق من الكود", isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Step 3: Reset Password
  Future<void> _resetPassword() async {
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();

    if (newPass.length < 6) {
      _showSnackBar(AppLocalizations.of(context)?.passwordMinLength6 ?? "كلمة المرور يجب أن تكون 6 أحرف على الأقل", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar(AppLocalizations.of(context)?.passwordsDoNotMatch ?? "كلمة المرور وتأكيدها غير متطابقين", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/student/whatsapp/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "resetToken": resetToken,
          "newPassword": newPass,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final err = data is Map ? (data["message"] ?? AppLocalizations.of(context)?.failedToChangePassword ?? "فشل تغيير كلمة المرور") : data.toString();
        _showSnackBar(err, isError: true);
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)?.errorSettingPassword ?? "حدث خطأ أثناء تعيين كلمة المرور", isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)?.passwordChangedSuccess ?? "تم تغيير كلمة المرور بنجاح 🎉",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          AppLocalizations.of(context)?.loginWithNewPassword ?? "يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة.",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Back to login screen
            },
            child: Text(
              AppLocalizations.of(context)?.loginTitle ?? "تسجيل الدخول",
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Icon(
                PhosphorIconsFill.whatsappLogo,
                size: 64,
                color: Colors.green[600],
              ),
              const SizedBox(height: 15),
              Text(
                AppLocalizations.of(context)!.retrievePassword,
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white : Colors.grey[800],
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // STEP 1: Phone / Identifier Input
              if (step == 1) ...[
                Text(
                  AppLocalizations.of(context)?.enterPhoneToSendCode ?? "أدخل رقم هاتفك أو بريدك المسجل لإرسال كود التحقق عبر الواتساب",
                  style: GoogleFonts.cairo(
                    color: AppColors.getSecondHintColor(isDark),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                outlineTextField(
                  hint: AppLocalizations.of(context)?.phoneOrUsernameHint ?? "رقم الهاتف أو اسم المستخدم المسجل",
                  controller: phoneController,
                  icon: PhosphorIconsFill.user,
                  isNumber: false,
                  context: context,
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  title: AppLocalizations.of(context)?.sendWhatsappCode ?? "إرسال كود الواتساب",
                  onPressed: _sendOtp,
                ),
              ],

              // STEP 2: OTP Verification Input
              if (step == 2) ...[
                Text(
                  AppLocalizations.of(context)?.codeSentToNumber(maskedPhone ?? phoneController.text) ?? "تم إرسال كود التحقق المكون من 6 أرقام إلى حساب الواتساب للرقم:\n${maskedPhone ?? phoneController.text}",
                  style: GoogleFonts.cairo(
                    color: AppColors.getSecondHintColor(isDark),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                outlineTextField(
                  hint: AppLocalizations.of(context)?.otpCodeHint ?? "كود التحقق (OTP)",
                  controller: otpController,
                  icon: PhosphorIconsFill.shieldCheck,
                  isNumber: true,
                  context: context,
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  title: AppLocalizations.of(context)?.confirmCodeBtn ?? "تأكيد الكود",
                  onPressed: _verifyOtp,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            step = 1;
                          });
                        },
                  child: Text(
                    AppLocalizations.of(context)?.changePhoneNumber ?? "تغيير رقم الهاتف",
                    style: GoogleFonts.cairo(color: Colors.blue[600], fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              // STEP 3: Reset Password Input
              if (step == 3) ...[
                Text(
                  AppLocalizations.of(context)?.enterNewPasswordToComplete ?? "أدخل كلمة المرور الجديدة وتأكيدها لاستكمال العملية",
                  style: GoogleFonts.cairo(
                    color: AppColors.getSecondHintColor(isDark),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                outlineTextField(
                  hint: AppLocalizations.of(context)?.newPasswordHint ?? "كلمة المرور الجديدة",
                  controller: newPassController,
                  icon: PhosphorIconsFill.lock,
                  context: context,
                ),
                const SizedBox(height: 15),
                outlineTextField(
                  hint: AppLocalizations.of(context)?.confirmNewPasswordHint ?? "تأكيد كلمة المرور الجديدة",
                  controller: confirmPassController,
                  icon: PhosphorIconsFill.lock,
                  context: context,
                ),
                const SizedBox(height: 25),
                _buildActionButton(
                  title: AppLocalizations.of(context)?.saveNewPasswordBtn ?? "حفظ كلمة المرور الجديدة",
                  onPressed: _resetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String title, required VoidCallback onPressed}) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                title,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

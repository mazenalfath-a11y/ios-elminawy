import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/data/saved_accounts_manager.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/screens/mainscreens/main_screen.dart';
import 'package:flutter_version/screens/entering_account/login_screen.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/utilities/device_utils.dart';
import 'package:flutter_version/data/offline_data_service.dart';
import 'package:flutter_version/l10n/app_localizations.dart';

class AccountSwitchDialog extends StatefulWidget {
  const AccountSwitchDialog({super.key});

  @override
  State<AccountSwitchDialog> createState() => _AccountSwitchDialogState();
}

class _AccountSwitchDialogState extends State<AccountSwitchDialog> {
  List<SavedAccount> _accounts = [];
  SavedAccount? _activeAccount;
  bool _isLoading = true;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await SavedAccountsManager.getAccounts();
      final activeAccount = await SavedAccountsManager.getActiveAccount();
      setState(() {
        _accounts = accounts;
        _activeAccount = activeAccount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToAccount(SavedAccount account) async {
    if (_isSwitching) return;

    setState(() => _isSwitching = true);

    try {
      final apiService = ApiService();

      // 1. Logout from current account
      await apiService.request("student/logout", {}, "POST");
      ApiService
          .clearToken(); // prevents any request in-between from using the old token
      await OfflineDataService
          .clearCache(); // ✅ prevent old account's cached home data from leaking in

      // 2. Get device ID
      final deviceId = await DeviceUtils.getDeviceId();

      // 3. Login to selected account
      final loginData = {
        "email": account.email,
        "password": account.password,
        "deviceId": deviceId,
      };

      final response =
          await apiService.request("student/Login", loginData, "POST");

      if (response != null && response.statusCode == 200) {
        final rawToken =
            response.data["access_token"] ?? response.data["token"];
        final token =
            rawToken != null && rawToken.toString().startsWith("Bearer ")
                ? rawToken.toString().substring(7)
                : rawToken?.toString();

        debugPrint("🔑 Switch login token: $token");

        if (token != null && token.isNotEmpty) {
          await apiService.saveToken(token);
          await OfflineDataService.clearCache();
        } else {
          throw Exception(AppLocalizations.of(context)?.noAccessTokenReceived ?? "لم يتم استلام رمز الدخول من الخادم");
        }

        // Update account in storage
        await SavedAccountsManager.saveAccount(
          email: account.email,
          password: account.password,
          companyCode: account.companyCode,
          companyName: account.companyName,
          token: token,
          studentName:
              '${response.data["FirstName"] ?? ""} ${response.data["LastName"] ?? ""}'
                  .trim(),
          studentId: response.data["_id"] ?? '',
        );

        // Apply company colors
        if (response.data["companySettings"] != null &&
            response.data["companySettings"]["appColors"] != null) {
          final colors = response.data["companySettings"]["appColors"];
          final provider = Provider.of<ThemeProvider>(context, listen: false);

          try {
            if (colors["primary"] != null) {
              provider.setPrimaryColor(
                  Color(int.parse(colors["primary"].replaceAll("#", "0xFF"))));
            }
            if (colors["secondary"] != null) {
              provider.setSecondaryColor(Color(
                  int.parse(colors["secondary"].replaceAll("#", "0xFF"))));
            }
            if (colors["background"] != null) {
              provider.setBackgroundColor(Color(
                  int.parse(colors["background"].replaceAll("#", "0xFF"))));
            }
            if (colors["surface"] != null) {
              provider.setSurfaceColor(
                  Color(int.parse(colors["surface"].replaceAll("#", "0xFF"))));
            }
          } catch (e) {
            print("Error applying colors: $e");
          }
        }

        // Close dialog and navigate to main screen
        if (mounted) {
          setState(
              () => _isSwitching = false); // ✅ reset before navigating away
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainScreen()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                AppLocalizations.of(context)?.switchedToAccount(account.companyName.toString()) ?? "تم التبديل إلى ${account.companyName}",
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          );
        }
      } else {
        throw Exception(AppLocalizations.of(context)?.loginFailed ?? "فشل تسجيل الدخول");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSwitching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? 'حدث خطأ: ${e.toString()}',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(SavedAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context)?.deleteAccount ?? AppLocalizations.of(context)?.deleteAccountBtn ?? "حذف الحساب",
            style: GoogleFonts.cairo()),
        content: Text(
          AppLocalizations.of(context)?.confirmDeleteAccount(account.companyName.toString()) ?? "هل تريد حذف حساب ${account.companyName} من القائمة؟",
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? AppLocalizations.of(context)?.cancelBtn ?? "إلغاء",
                style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)?.delete ?? AppLocalizations.of(context)?.deleteBtn ?? "حذف",
                style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SavedAccountsManager.removeAccount(account.id);
      _loadAccounts();
    }
  }

  void _addNewAccount() {
    Navigator.of(context).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Dialog(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(PhosphorIconsRegular.userSwitch,
                    color: AppColors.sky(isDark), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.switchAccountTitle ?? "تبديل الحساب",
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDark)),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon:
                      Icon(Icons.close, color: AppColors.getTextColor(isDark)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: AppColors.sky(isDark),
                ),
              )
            else if (_accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  AppLocalizations.of(context)?.noSavedAccounts ?? "لا توجد حسابات محفوظة",
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    final isActive = _activeAccount?.id == account.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isActive ? 4 : 1,
                      color: isActive
                          ? AppColors.sky(isDark).withOpacity(0.25)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor:
                                AppColors.getBackgroundColor(isDark),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CachedNetworkImage(
                                  imageUrl:
                                      'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/People/Man%20Student.png'),
                            )),
                        title: Text(
                          account.studentName.isNotEmpty
                              ? account.studentName
                              : account.email,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.companyName,
                              style: GoogleFonts.cairo(fontSize: 13),
                            ),
                            if (isActive)
                              Text(
                                AppLocalizations.of(context)?.activeAccount ?? "الحساب النشط",
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.sky(isDark),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              IconButton(
                                onPressed: _isSwitching
                                    ? null
                                    : () => _switchToAccount(account),
                                icon: _isSwitching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.login,
                                        color: AppColors.sky(isDark),
                                      ),
                              ),
                            IconButton(
                              onPressed: () => _deleteAccount(account),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addNewAccount,
                icon: Icon(
                  Icons.add,
                  color: AppColors.sky(isDark),
                  size: 20,
                ),
                label: Text(
                  AppLocalizations.of(context)?.addNewAccount ?? "إضافة حساب جديد",
                  style: GoogleFonts.cairo(
                    color: AppColors.sky(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),

                  // Border settings
                  side: BorderSide(
                    color: AppColors.sky(isDark),
                    width: 1.5,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

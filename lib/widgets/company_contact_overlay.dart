import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_version/providers/company_settings_provider.dart';
import 'package:flutter_version/models/company_settings_model.dart' hide AppColors;
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:flutter_version/utilities/app_colors.dart';

class CompanyContactOverlay extends StatefulWidget {
  final Widget child;

  const CompanyContactOverlay({super.key, required this.child});

  @override
  State<CompanyContactOverlay> createState() => _CompanyContactOverlayState();
}

class _CompanyContactOverlayState extends State<CompanyContactOverlay> {
  bool _expanded = false;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('CompanyContactOverlay: failed to launch $url ($e)');
    }
  }

  void _openWhatsapp(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    _launch('https://wa.me/$cleaned');
  }

  void _openFacebook(String url) => _launch(url);

  void _openTechSupport(String value) {
    // techSupport entries are often links (Telegram, a support site), not
    // always phone numbers — only treat it as tel: if it looks numeric.
    final isPhoneLike = RegExp(r'^\+?[0-9\s\-]+$').hasMatch(value);
    _launch(isPhoneLike ? 'tel:$value' : value);
  }

  // ✅ contactInfo entries are lists now (a company can list more than one
  // WhatsApp number, e.g. "Customer Service" + "Tech Support"). If there's
  // only one entry, tap opens it directly. If there are several, show a
  // quick picker instead of guessing which one the student wants.
  void _handleTap(List<ContactEntry> entries, void Function(String) opener) {
    if (entries.length == 1) {
      opener(entries.first.value);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: entries
              .map((e) => ListTile(
                    title: Text(
                      e.displayName.isNotEmpty ? e.displayName : e.value,
                      textAlign: TextAlign.right,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      opener(e.value);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companySettings = context.watch<CompanySettingsProvider>();
    final overlay = companySettings.overlayIconDisplay;
    final contact = companySettings.contactInfo;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final List<_ContactButtonData> buttons = [];

    if (overlay.whatsapp && contact.whatsapp.isNotEmpty) {
      buttons.add(_ContactButtonData(
        icon: PhosphorIconsFill.whatsappLogo,
        color: const Color(0xFF25D366),
        onTap: () => _handleTap(contact.whatsapp, _openWhatsapp),
      ));
    }
    if (overlay.facebook && contact.facebook.isNotEmpty) {
      buttons.add(_ContactButtonData(
        icon: PhosphorIconsFill.facebookLogo,
        color: const Color(0xFF1877F2),
        onTap: () => _handleTap(contact.facebook, _openFacebook),
      ));
    }
    if (overlay.techSupport && contact.techSupport.isNotEmpty) {
      buttons.add(_ContactButtonData(
        icon: PhosphorIconsFill.headset,
        color: const Color(0xFF6C757D),
        onTap: () => _handleTap(contact.techSupport, _openTechSupport),
      ));
    }

    return Stack(
      children: [
        widget.child,
        if (buttons.isNotEmpty)
          Positioned(
            bottom: 24,
            right: 16,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expanded)
                    ...buttons.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContactBubble(data: b),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sky(isDark),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _expanded
                            ? Icons.close_rounded
                            : PhosphorIconsFill.chatCircleDots,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactButtonData {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ContactButtonData({
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ContactBubble extends StatelessWidget {
  final _ContactButtonData data;

  const _ContactBubble({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: data.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(data.icon, color: Colors.white, size: 22, textDirection: TextDirection.ltr),
      ),
    );
  }
}

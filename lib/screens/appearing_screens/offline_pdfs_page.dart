import 'package:flutter_version/l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_version/screens/appearing_screens/pdf_editor_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class OfflinePdfsPage extends StatefulWidget {
  const OfflinePdfsPage({Key? key}) : super(key: key);

  @override
  State<OfflinePdfsPage> createState() => _OfflinePdfsPageState();
}

class _OfflinePdfsPageState extends State<OfflinePdfsPage> {
  bool _isLoading = true;
  List<dynamic> _pdfFiles = [];

  @override
  void initState() {
    super.initState();
    _loadLocalPdfs();
  }

  Future<void> _loadLocalPdfs() async {
    setState(() => _isLoading = true);
    if (kIsWeb) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) {
        final List<FileSystemEntity> allFiles = dir.listSync();
        setState(() {
          // Filter out only files ending in .pdf
          _pdfFiles =
              allFiles.where((file) => file.path.endsWith('.pdf')).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading local PDFs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openPdf(String filePath) {
    final sep = kIsWeb ? '/' : Platform.pathSeparator;
    final fileName = filePath.split(sep).last;
    final pdfId = fileName.replaceAll('.pdf', '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfEditorPage(
          title: AppLocalizations.of(context)?.downloadedFileTitle(fileName.toString()) ?? "ملف محمل: $fileName",
          pdfPath: filePath,
          pdfId: pdfId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.downloadedFilesOffline ?? "الملفات المحملة (بدون إنترنت)",
          style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextColor(isDark)),
        ),
        backgroundColor: AppColors.getBackgroundColor(isDark),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: AppColors.sky(isDark),
            ))
          : _pdfFiles.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)?.noDownloadedPdfs ?? "لا توجد ملفات PDF تم تحميلها مسبقاً",
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.getTextSecondaryColor(isDark)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _pdfFiles.length,
                  itemBuilder: (context, index) {
                    final file = _pdfFiles[index];
                    final sep = kIsWeb ? '/' : Platform.pathSeparator;
                    final fileName =
                        file.path.split(sep).last;

                    return Card(
                      color: AppColors.getInputBackgroundColor(isDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.redAccent, size: 36),
                        title: Text(
                          fileName,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.ltr,
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)?.availableOffline ?? "متاح للاستخدام بدون إنترنت",
                          style: GoogleFonts.cairo(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        onTap: () => _openPdf(file.path),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    );
                  },
                ),
    );
  }
}

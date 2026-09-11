$path = "e:\Projects_code\Flutter\application\lib\screens\appearing_screens\course_details_page.dart"
$lines = [System.IO.File]::ReadAllLines($path)
$newLines = New-Object System.Collections.Generic.List[string]

$inOldLessonCard = $false
$inOldTabs = $false

foreach ($line in $lines) {
    # Replace LessonCard
    if ($line -like "*Widget _buildLessonCard(*") {
        $newLines.Add("  Widget _buildLessonCard(String title, String videoUrl, id, exerciseId, files,")
        $newLines.Add("      additionalVideos, courseId,")
        $newLines.Add("      {required bool isFree, required bool isLockedByExercise}) {")
        $newLines.Add("    final theme = Theme.of(context);")
        $newLines.Add("    final isDark = theme.brightness == Brightness.dark;")
        $newLines.Add("")
        $newLines.Add("    final isLocked = (!widget.isPurchased && !isFree) || isLockedByExercise;")
        $newLines.Add('    final isFirst = lessons.isNotEmpty && lessons[0]["id"] == id;')
        $newLines.Add("")
        $newLines.Add("    return GestureDetector(")
        $newLines.Add("      onTap: () {")
        $newLines.Add("        if (!isLocked) {")
        $newLines.Add("          Navigator.push(")
        $newLines.Add("            context,")
        $newLines.Add("            MaterialPageRoute(")
        $newLines.Add("              builder: (_) => VideoWatchPage(")
        $newLines.Add("                  videoTitle: title,")
        $newLines.Add("                  videoUrl: videoUrl,")
        $newLines.Add("                  v_id: id,")
        $newLines.Add("                  exerciseId: exerciseId,")
        $newLines.Add("                  files: files,")
        $newLines.Add("                  additionalVideos: additionalVideos ?? [],")
        $newLines.Add("                  courseId: courseId,")
        $newLines.Add("                  exerciseArr: exerciseArr),")
        $newLines.Add("            ),")
        $newLines.Add("          );")
        $newLines.Add("        } else {")
        $newLines.Add("          _showPurchaseVideoDialog(id);")
        $newLines.Add("        }")
        $newLines.Add("      },")
        $newLines.Add("      child: Container(")
        $newLines.Add("        width: double.infinity,")
        $newLines.Add("        margin: const EdgeInsets.only(bottom: 12),")
        $newLines.Add("        padding: const EdgeInsets.all(16),")
        $newLines.Add("        decoration: BoxDecoration(")
        $newLines.Add("          color: isDark ? theme.cardColor : Colors.white,")
        $newLines.Add("          borderRadius: BorderRadius.circular(16),")
        $newLines.Add("          border: isFirst ? Border.all(color: AppColors.sky, width: 2) : Border.all(color: Colors.black.withOpacity(0.05)),")
        $newLines.Add("          boxShadow: isFirst ? [")
        $newLines.Add("            BoxShadow(")
        $newLines.Add("              color: AppColors.sky.withOpacity(0.1),")
        $newLines.Add("              blurRadius: 10,")
        $newLines.Add("              offset: const Offset(0, 4),")
        $newLines.Add("            )")
        $newLines.Add("          ] : [],")
        $newLines.Add("        ),")
        $newLines.Add("        child: Row(")
        $newLines.Add("          children: [")
        $newLines.Add("            Container(")
        $newLines.Add("              padding: const EdgeInsets.all(8),")
        $newLines.Add("              decoration: BoxDecoration(")
        $newLines.Add("                color: isFirst ? AppColors.sky : (isLocked ? Colors.grey.withOpacity(0.1) : const Color(0xFFF1F5F9)),")
        $newLines.Add("                shape: BoxShape.circle,")
        $newLines.Add("              ),")
        $newLines.Add("              child: Icon(")
        $newLines.Add("                isLocked ? PhosphorIconsFill.lock : PhosphorIconsFill.play,")
        $newLines.Add("                color: isFirst ? Colors.white : (isLocked ? Colors.grey : AppColors.sky),")
        $newLines.Add("                size: 20,")
        $newLines.Add("              ),")
        $newLines.Add("            ),")
        $newLines.Add("            const SizedBox(width: 12),")
        $newLines.Add("            Expanded(")
        $newLines.Add("              child: Column(")
        $newLines.Add("                crossAxisAlignment: CrossAxisAlignment.end,")
        $newLines.Add("                children: [")
        $newLines.Add("                  Text(")
        $newLines.Add("                    title,")
        $newLines.Add("                    maxLines: 1,")
        $newLines.Add("                    overflow: TextOverflow.ellipsis,")
        $newLines.Add("                    style: GoogleFonts.cairo(")
        $newLines.Add("                      color: isDark ? Colors.white : const Color(0xFF1E293B),")
        $newLines.Add("                      fontSize: 14,")
        $newLines.Add("                      fontWeight: FontWeight.w800,")
        $newLines.Add("                    ),")
        $newLines.Add("                    textAlign: TextAlign.right,")
        $newLines.Add("                  ),")
        $newLines.Add("                  Text(")
        $newLines.Add('                    "فيديو • 45 دقيقة",')
        $newLines.Add("                    style: GoogleFonts.cairo(")
        $newLines.Add("                      color: Colors.grey,")
        $newLines.Add("                      fontSize: 11,")
        $newLines.Add("                      fontWeight: FontWeight.w600,")
        $newLines.Add("                    ),")
        $newLines.Add("                  ),")
        $newLines.Add("                ],")
        $newLines.Add("              ),")
        $newLines.Add("            ),")
        $newLines.Add("          ],")
        $newLines.Add("        ),")
        $newLines.Add("      ),")
        $newLines.Add("    );")
        $newLines.Add("  }")
        $inOldLessonCard = $true
        continue
    }

    if ($inOldLessonCard) {
        if ($line -eq "  }") {
            $inOldLessonCard = $false
        }
        continue
    }

    # Replace Tabs
    if ($line -like "*Widget _buildTabs() {*") {
        $newLines.Add("  Widget _buildTabs() {")
        $newLines.Add("    final theme = Theme.of(context);")
        $newLines.Add("    final isDark = theme.brightness == Brightness.dark;")
        $newLines.Add("    ")
        $newLines.Add("    return SingleChildScrollView(")
        $newLines.Add("      scrollDirection: Axis.horizontal,")
        $newLines.Add("      reverse: true,")
        $newLines.Add("      child: Row(")
        $newLines.Add("        mainAxisAlignment: MainAxisAlignment.end,")
        $newLines.Add("        children: List.generate(visibleTabs.length, (index) {")
        $newLines.Add("          final isSelected = _selectedTabIndex == index;")
        $newLines.Add("          return GestureDetector(")
        $newLines.Add("            onTap: () => setState(() => _selectedTabIndex = index),")
        $newLines.Add("            child: Container(")
        $newLines.Add("              margin: const EdgeInsets.only(left: 8),")
        $newLines.Add("              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),")
        $newLines.Add("              decoration: BoxDecoration(")
        $newLines.Add("                color: isSelected ? Colors.white : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),")
        $newLines.Add("                borderRadius: BorderRadius.circular(12),")
        $newLines.Add("                border: isSelected ? Border.all(color: Colors.black.withOpacity(0.05)) : null,")
        $newLines.Add("                boxShadow: isSelected ? [")
        $newLines.Add("                  BoxShadow(")
        $newLines.Add("                    color: Colors.black.withOpacity(0.05),")
        $newLines.Add("                    blurRadius: 4,")
        $newLines.Add("                    offset: const Offset(0, 2),")
        $newLines.Add("                  )")
        $newLines.Add("                ] : [],")
        $newLines.Add("              ),")
        $newLines.Add("              child: Text(")
        $newLines.Add("                visibleTabs[index],")
        $newLines.Add("                style: GoogleFonts.cairo(")
        $newLines.Add("                  color: isSelected ? const Color(0xFF1E293B) : Colors.grey,")
        $newLines.Add("                  fontSize: 14,")
        $newLines.Add("                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,")
        $newLines.Add("                ),")
        $newLines.Add("              ),")
        $newLines.Add("            ),")
        $newLines.Add("          );")
        $newLines.Add("        }),")
        $newLines.Add("      ),")
        $newLines.Add("    );")
        $newLines.Add("  }")
        $inOldTabs = $true
        continue
    }

    if ($inOldTabs) {
        if ($line -eq "  }") {
            $inOldTabs = $false
        }
        continue
    }

    $newLines.Add($line)
}

[System.IO.File]::WriteAllLines($path, $newLines, [System.Text.Encoding]::UTF8)

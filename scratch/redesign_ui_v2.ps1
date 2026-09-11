$path = "e:\Projects_code\Flutter\application\lib\screens\appearing_screens\course_details_page.dart"
$content = [System.IO.File]::ReadAllText($path)

# New build method implementation
$newBuild = '  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildNotchHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoHeader(),
                        const SizedBox(height: 24),
                        _buildCourseInfo(theme),
                        const SizedBox(height: 12),
                        _buildStatsRow(isDark),
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppLocalizations.of(context)!.courseContent,
                            style: GoogleFonts.cairo(
                              color: theme.textTheme.titleMedium?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTabs(),
                        const SizedBox(height: 16),
                        _buildTabContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(isDark),
            ),
          ],
        ),
      ),
    );
  }'

# Replace build method body using regex (more robust)
$buildRegex = '(?s)  @override\s+Widget build\(BuildContext context\) \{.*?\n  \}'
$content = [regex]::Replace($content, $buildRegex, $newBuild)

# Update _buildTitleRow (find it by name)
$titleRowRegex = '(?s)  Widget _buildTitleRow\(ThemeData theme\) \{.*?\}\n  \}'
$newCourseInfo = '  Widget _buildCourseInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    "XP 500+",
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFFF6B4A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.network(
                    "https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Activities/Wrapped%20Gift.png",
                    width: 16,
                    height: 16,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                widget.title,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              " | الصف الثالث الثانوي",
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
            Text(
              widget.teacherName ?? "أ. محمد عبد المعبود",
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.sky,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsFill.users, color: Colors.grey, size: 18),
          ],
        ),
      ],
    );
  }'
$content = [regex]::Replace($content, $titleRowRegex, $newCourseInfo)

# Update _buildCourseImage (find it by name)
$courseImageRegex = '(?s)  Widget _buildCourseImage\(\) \{.*?\}\n    \);\n  \}'
$newVideoHeader = '  Widget _buildVideoHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(widget.image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "اعلان الكورس",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(
                PhosphorIconsFill.play,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildStatBadge("${lessons.length} درس", PhosphorIconsFill.videoCamera, isDark),
        const SizedBox(width: 12),
        _buildStatBadge("${pdfs.length} ملفات", PhosphorIconsFill.filePdf, isDark),
      ],
    );
  }

  Widget _buildStatBadge(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: AppColors.sky),
        ],
      ),
    );
  }'
$content = [regex]::Replace($content, $courseImageRegex, $newVideoHeader)

# Redesign _buildLessonCard to match photo
$lessonCardRegex = '(?s)  Widget _buildLessonCard\(String title, String videoUrl, id, exerciseId, files,.*?\}\n    \);\n  \}'
$newLessonCard = '  Widget _buildLessonCard(String title, String videoUrl, id, exerciseId, files,
      additionalVideos, courseId,
      {required bool isFree, required bool isLockedByExercise}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isLocked = (!widget.isPurchased && !isFree) || isLockedByExercise;
    final isFirst = lessons.isNotEmpty && lessons[0]["id"] == id;

    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoWatchPage(
                  videoTitle: title,
                  videoUrl: videoUrl,
                  v_id: id,
                  exerciseId: exerciseId,
                  files: files,
                  additionalVideos: additionalVideos ?? [],
                  courseId: courseId,
                  exerciseArr: exerciseArr),
            ),
          );
        } else {
          _showPurchaseVideoDialog(id);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isFirst ? Border.all(color: AppColors.sky, width: 2) : Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: isFirst ? [
            BoxShadow(
              color: AppColors.sky.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFirst ? AppColors.sky : (isLocked ? Colors.grey.withOpacity(0.1) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? PhosphorIconsFill.lock : PhosphorIconsFill.play,
                color: isFirst ? Colors.white : (isLocked ? Colors.grey : AppColors.sky),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    "فيديو • 45 دقيقة",
                    style: GoogleFonts.cairo(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }'
$content = [regex]::Replace($content, $lessonCardRegex, $newLessonCard)

# Update _buildTabs for horizontal look
$tabsRegex = '(?s)  Widget _buildTabs\(\) \{.*?\}\n  \}'
$newTabs = '  Widget _buildTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(visibleTabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ] : [],
              ),
              child: Text(
                visibleTabs[index],
                style: GoogleFonts.cairo(
                  color: isSelected ? const Color(0xFF1E293B) : Colors.grey,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }'
$content = [regex]::Replace($content, $tabsRegex, $newTabs)

# Write back with UTF8
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)

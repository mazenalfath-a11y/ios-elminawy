import 'package:flutter_version/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Embeddable course-chat widget. Used inside [CourseDetailsPage] as the
/// AppLocalizations.of(context)?.chat ?? "الشات" tab. This is the same chat behavior that used to live in
/// MessagesPage (fetch/send/delete/retry/pagination/reply-to) but without
/// its own Scaffold/AppBar, so it can sit inside another page's tab content.
///
/// NOTE: because this is embedded (not its own page), it does not intercept
/// back-navigation while a message is sending the way MessagesPage used to
/// via PopScope. If you need that protection here too, wrap the parent
/// bottom-sheet route in a PopScope keyed off this widget's sending state.
class CourseChatTab extends StatefulWidget {
  final String courseId;

  const CourseChatTab({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseChatTab> createState() => _CourseChatTabState();
}

class _CourseChatTabState extends State<CourseChatTab> {
  final ApiService _apiService = ApiService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 50;
  bool _loadFailed = false;
  String? _loadFailedReason;

  String? _currentUserId;
  String? _currentUserName;
  String? _replyToId;
  String? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchMessages(clear: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Load current user ────────────────────────────────────────────────

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? userName = prefs.getString('user_name');

      if (userId != null && userName != null && userName != (AppLocalizations.of(context)?.unknownPerson ?? "مجهول")) {
        if (mounted) {
          setState(() {
            _currentUserId = userId;
            _currentUserName = userName;
          });
        }
        return;
      }

      final response =
          await _apiService.request('student/getuser', null, 'GET');
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        final id = data['_id']?.toString();
        final firstName = data['FirstName'] ?? '';
        final lastName = data['LastName'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        final name = fullName.isNotEmpty ? fullName : (data['name'] ?? AppLocalizations.of(context)?.studentRole ?? "طالب");

        if (mounted) {
          setState(() {
            _currentUserId = id;
            _currentUserName = name;
          });
        }
        if (id != null) {
          await prefs.setString('user_id', id);
          await prefs.setString('user_name', name);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  // ─── Fetch messages ────────────────────────────────────────────────────

  Future<void> _fetchMessages({bool clear = false}) async {
    if (_isLoading || (!_hasMore && !clear)) return;
    if (!mounted) return;
    if (widget.courseId.isEmpty) {
      _showError(AppLocalizations.of(context)?.invalidCourseId ?? "معرف الكورس غير صالح");
      return;
    }

    setState(() {
      _isLoading = true;
      if (clear) {
        _loadFailed = false;
        _loadFailedReason = null;
      }
    });

    try {
      final page = clear ? 1 : _currentPage + 1;
      final String endpoint =
          'course-chat/${widget.courseId}?page=$page&limit=$_limit';

      final response = await _apiService.request(endpoint, null, 'GET');

      if (mounted) {
        if (response == null) {
          setState(() {
            _isLoading = false;
            if (clear) {
              _loadFailed = true;
              _loadFailedReason = AppLocalizations.of(context)?.noServerResponse ?? "لا يوجد رد من الخادم";
            }
          });
          _showError(AppLocalizations.of(context)?.noServerResponse ?? "لا يوجد رد من الخادم");
          return;
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          setState(() {
            _isLoading = false;
            if (clear) {
              _loadFailed = true;
              _loadFailedReason =
                  AppLocalizations.of(context)?.sessionExpired ?? "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً";
            }
          });
          _showError(AppLocalizations.of(context)?.sessionExpired ?? "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً");
          return;
        }

        if (response.statusCode == 200) {
          final data = response.data;

          final List<Map<String, dynamic>> newMessages =
              data is Map && data['messages'] is List
                  ? List<Map<String, dynamic>>.from(data['messages'])
                  : [];

          setState(() {
            if (clear) {
              final tempMessages = _messages
                  .where(
                    (m) => m['_id']?.toString().startsWith('temp_') == true,
                  )
                  .toList();
              _messages = [...tempMessages, ...newMessages];
              _currentPage = 1;
            } else {
              final tempMessages = _messages
                  .where(
                    (m) => m['_id']?.toString().startsWith('temp_') == true,
                  )
                  .toList();
              final realMessages = _messages
                  .where(
                    (m) => m['_id']?.toString().startsWith('temp_') != true,
                  )
                  .toList();
              _messages = [...tempMessages, ...realMessages, ...newMessages];
              _currentPage = page;
            }
            _hasMore = newMessages.length == _limit;
            _isLoading = false;
          });

          if (clear) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scrollToBottom();
            });
          }
        } else {
          String errorMsg = AppLocalizations.of(context)?.failedToLoadMessages ?? "فشل تحميل الرسائل";
          if (response.data is Map && response.data['message'] != null) {
            errorMsg = response.data['message'];
          }
          setState(() {
            _isLoading = false;
            if (clear) {
              _loadFailed = true;
              _loadFailedReason = errorMsg;
            }
          });
          _showError(errorMsg);
        }
      }
    } catch (e) {
      debugPrint('❌ Exception in _fetchMessages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (clear) {
            _loadFailed = true;
            _loadFailedReason = e.toString();
          }
        });
        _showError(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? "حدث خطأ: $e");
      }
    }
  }

  void _onScroll() {
    // The list is `reverse: true`, so pixels == 0 is the BOTTOM (newest
    // message) and pixels == maxScrollExtent is the TOP (oldest loaded
    // message). Load older messages as the user scrolls toward the top.
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchMessages();
    }
  }

  // ─── Helpers to safely get sender info ───────────────────────────────

  String? _getSenderId(Map<String, dynamic> msg) {
    final sender = msg['sender'];
    if (sender is Map) {
      return sender['_id']?.toString();
    } else if (sender is String) {
      return sender;
    }
    return null;
  }

  String _getSenderName(Map<String, dynamic> msg) {
    final sender = msg['sender'];

    if (sender is Map) {
      return sender['name']?.toString() ??
          msg['senderName']?.toString() ??
          AppLocalizations.of(context)?.unknownPerson ?? "مجهول";
    }

    return msg['senderName']?.toString() ?? AppLocalizations.of(context)?.unknownPerson ?? "مجهول";
  }

  // ─── Send message ─────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_isSending) return;
    if (widget.courseId.isEmpty) {
      _showError(AppLocalizations.of(context)?.invalidCourseId ?? "معرف الكورس غير صالح");
      return;
    }

    if (!mounted) return;
    setState(() => _isSending = true);

    final Map<String, dynamic> tempMsg = {
      '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'message': text,
      'sender': {
        '_id': _currentUserId,
        'name': _currentUserName ?? AppLocalizations.of(context)?.you ?? "أنت",
      },
      'createdAt': DateTime.now().toIso8601String(),
      'replyTo': _replyToId,
    };

    final String? replyToForThisMessage = _replyToId;

    setState(() {
      _replyToId = null;
      _replyToMessage = null;
      _messageController.clear();
      _messages.insert(0, tempMsg);
    });
    _scrollToBottom();

    try {
      final Map<String, dynamic> body = {
        'message': text,
        if (replyToForThisMessage != null) 'replyTo': replyToForThisMessage,
      };
      final String endpoint = 'course-chat/send/${widget.courseId}';

      final response = await _apiService.request(endpoint, body, 'POST');

      if (response == null) {
        _handleSendFailure(tempMsg, AppLocalizations.of(context)?.noServerResponse ?? "لا يوجد رد من الخادم");
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        _handleSendFailure(
            tempMsg, AppLocalizations.of(context)?.sessionExpired ?? "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً");
        return;
      }

      if (response.statusCode == 200) {
        Map<String, dynamic>? newMessage;
        if (response.data is Map) {
          final Map data = response.data as Map;
          if (data.containsKey('message') && data['message'] is Map) {
            newMessage = Map<String, dynamic>.from(data['message']);
          } else {
            newMessage = Map<String, dynamic>.from(data);
          }
        }

        if (newMessage != null && newMessage['_id'] != null) {
          final Map<String, dynamic> realMsg = newMessage;

          if (realMsg['sender'] == null) {
            realMsg['sender'] = {
              '_id': _currentUserId,
              'name': _currentUserName ?? AppLocalizations.of(context)?.you ?? "أنت",
            };
          }

          if (mounted) {
            final int tempIndex =
                _messages.indexWhere((m) => m['_id'] == tempMsg['_id']);
            setState(() {
              if (tempIndex != -1) {
                _messages.removeAt(tempIndex);
                _messages.insert(tempIndex, realMsg);
              } else {
                _messages.insert(0, realMsg);
              }
            });
          }
        } else {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            await _fetchMessages(clear: true);
          }
        }
      } else {
        String errorMsg = AppLocalizations.of(context)?.failedToSendMsg(response.statusCode.toString()) ?? "فشل إرسال الرسالة: ${response.statusCode}";
        if (response.data is Map && response.data['message'] != null) {
          errorMsg = response.data['message'];
        }
        _handleSendFailure(tempMsg, errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Exception in _sendMessage: $e');
      _handleSendFailure(tempMsg, AppLocalizations.of(context)?.errorSending(e.toString()) ?? "حدث خطأ أثناء الإرسال: $e");
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      } else {
        _isSending = false;
      }
    }
  }

  void _handleSendFailure(Map<String, dynamic> tempMsg, String errorMsg) {
    debugPrint('❌ Send failed for ${tempMsg['_id']}: $errorMsg');
    if (!mounted) return;
    setState(() {
      final int idx = _messages.indexWhere((m) => m['_id'] == tempMsg['_id']);
      if (idx != -1) {
        _messages[idx] = {
          ..._messages[idx],
          'failed': true,
        };
      }
    });
    _showError(errorMsg);
  }

  Future<void> _retryFailedMessage(Map<String, dynamic> msg) async {
    final String? text = msg['message'];
    if (text == null || text.isEmpty) return;
    setState(() {
      _messages.removeWhere((m) => m['_id'] == msg['_id']);
    });
    _messageController.text = text;
    await _sendMessage();
  }

  // ─── Delete message ───────────────────────────────────────────────────

  Future<void> _deleteMessage(String messageId) async {
    if (messageId.startsWith('temp_')) {
      setState(() {
        _messages.removeWhere((m) => m['_id'] == messageId);
      });
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.deleteMessageBtn ?? "حذف الرسالة",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)?.confirmDeleteMsg ?? "هل أنت متأكد من حذف هذه الرسالة؟",
          style: GoogleFonts.cairo(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancelBtn ?? "إلغاء", style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)?.deleteBtn ?? "حذف",
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.request(
        'course-chat/delete/$messageId',
        null,
        'DELETE',
      );
      if (mounted) {
        if (response != null && response.statusCode == 200) {
          setState(() {
            _messages
                .removeWhere((Map<String, dynamic> m) => m['_id'] == messageId);
          });
          _showSnackBar(AppLocalizations.of(context)?.msgDeletedSuccess ?? "تم حذف الرسالة", isError: false);
        } else {
          _showError(AppLocalizations.of(context)?.failedToDeleteMsg ?? "فشل حذف الرسالة");
        }
      }
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context)?.errorDeleting ?? "حدث خطأ أثناء الحذف");
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    _showSnackBar(message, isError: true);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final DateTime dt = DateTime.parse(dateStr);
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(dt);
      if (diff.inDays > 0) {
        return '${dt.day}/${dt.month}/${dt.year}';
      } else if (diff.inHours > 0) {
        return AppLocalizations.of(context)?.hoursAgo(diff.inHours.toString()) ?? "${diff.inHours} ساعة";
      } else if (diff.inMinutes > 0) {
        return AppLocalizations.of(context)?.minutesAgo(diff.inMinutes.toString()) ?? "${diff.inMinutes} دقيقة";
      } else {
        return AppLocalizations.of(context)?.justNow ?? "الآن";
      }
    } catch (_) {
      return dateStr;
    }
  }

  // ─── Build message item ──────────────────────────────────────────────

  Widget _buildMessageItem(Map<String, dynamic> msg, bool isDark) {
    final bool isMine = _getSenderId(msg) == _currentUserId;
    final String senderName = _getSenderName(msg);
    final String messageText = msg['message'] ?? '';
    final String? createdAt = msg['createdAt'];
    final String? replyTo = msg['replyTo'];
    final bool isFailed = msg['failed'] == true;
    String replyPreview = '';
    if (replyTo != null) {
      final Map<String, dynamic> repliedMsg = _messages.firstWhere(
        (Map<String, dynamic> m) => m['_id'] == replyTo,
        orElse: () => <String, dynamic>{},
      );
      replyPreview = repliedMsg.isNotEmpty
          ? (repliedMsg['message'] ?? '')
          : AppLocalizations.of(context)?.deletedMessage ?? "رسالة محذوفة";
      if (replyPreview.length > 60) {
        replyPreview = replyPreview.substring(0, 60) + '...';
      }
    }

    final bool isTemp = msg['_id']?.toString().startsWith('temp_') ?? false;

    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        if (isFailed) {
          _retryFailedMessage(msg);
          return;
        }
        setState(() {
          if (_replyToId == msg['_id']) {
            _replyToId = null;
            _replyToMessage = null;
          } else {
            _replyToId = msg['_id'];
            _replyToMessage = messageText;
          }
        });
      },
      onLongPress: () {
        if (isMine) {
          _deleteMessage(msg['_id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (replyTo != null && replyPreview.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      PhosphorIconsRegular.arrowBendUpLeft,
                      size: 14,
                      color: AppColors.getTextHintColor(isDark),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        replyPreview,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.getTextHintColor(isDark),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: <Widget>[
                if (isMine)
                  IconButton(
                    icon: Icon(
                      isFailed
                          ? PhosphorIconsRegular.warningCircle
                          : (isTemp
                              ? PhosphorIconsRegular.clock
                              : PhosphorIconsRegular.trash),
                      size: 18,
                      color: isFailed
                          ? Colors.red
                          : (isTemp ? Colors.orange : Colors.grey),
                    ),
                    onPressed: () => isFailed
                        ? _retryFailedMessage(msg)
                        : _deleteMessage(msg['_id']),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? (isFailed
                              ? Colors.red.shade300
                              : (isTemp
                                  ? Colors.orange.shade300
                                  : AppColors.sky(isDark)))
                          : AppColors.getInputBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      messageText,
                      style: GoogleFonts.cairo(
                        color: isMine
                            ? Colors.white
                            : AppColors.getTextColor(isDark),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                if (!isMine)
                  IconButton(
                    icon: const Icon(
                      PhosphorIconsRegular.trash,
                      size: 18,
                      color: Colors.transparent,
                    ),
                    onPressed: null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  senderName,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.getTextHintColor(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isFailed
                      ? AppLocalizations.of(context)?.sendFailedRetry ?? "فشل الإرسال، اضغط لإعادة المحاولة"
                      : (isTemp ? AppLocalizations.of(context)?.sendingMsg ?? "جاري الإرسال..." : _formatTime(createdAt)),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: isFailed
                        ? Colors.red
                        : (isTemp
                            ? Colors.orange
                            : AppColors.getTextHintColor(isDark)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchMessages(clear: true),
            child: _messages.isEmpty && !_isLoading && _loadFailed
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          PhosphorIconsFill.warningCircle,
                          size: 48,
                          color: Colors.red.withOpacity(0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)?.cannotLoadMessages ?? "تعذر تحميل الرسائل",
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                        if (_loadFailedReason != null) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _loadFailedReason!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.getTextHintColor(isDark),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _fetchMessages(clear: true),
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            AppLocalizations.of(context)?.retryBtn ?? "إعادة المحاولة",
                            style: GoogleFonts.cairo(),
                          ),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              PhosphorIconsFill.chats,
                              size: 48,
                              color: AppColors.getTextHintColor(isDark)
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)?.noMessagesYet ?? "لا توجد رسائل بعد",
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.getTextSecondaryColor(isDark),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)?.beFirstToWrite ?? "كن أول من يكتب!",
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.getTextHintColor(isDark),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (BuildContext ctx, int idx) {
                          if (idx == _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final Map<String, dynamic> msg = _messages[idx];
                          return _buildMessageItem(msg, isDark);
                        },
                      ),
          ),
        ),
        if (_replyToId != null && _replyToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.getCardBackgroundColor(isDark),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)?.replyingTo ?? "الرد على:",
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.getTextHintColor(isDark),
                        ),
                      ),
                      Text(
                        _replyToMessage!,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.getTextColor(isDark),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.x,
                    color: AppColors.getTextHintColor(isDark),
                    size: 18,
                  ),
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      _replyToId = null;
                      _replyToMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.getInputBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getCardBorderColor(isDark)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  style: GoogleFonts.cairo(
                    color: AppColors.getTextColor(isDark),
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.writeMessageHint ?? "اكتب رسالة...",
                    hintStyle: GoogleFonts.cairo(
                      color: AppColors.getTextHintColor(isDark),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  textAlign: TextAlign.right,
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sky(isDark),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          PhosphorIconsFill.paperPlaneTilt,
                          color: Colors.white,
                          size: 18,
                          textDirection: TextDirection.ltr,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

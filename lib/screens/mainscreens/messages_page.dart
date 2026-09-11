import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_version/data/api_service.dart';
import 'package:flutter_version/utilities/app_colors.dart';
import 'package:flutter_version/utilities/theme_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_version/l10n/app_localizations.dart';

class MessagesPage extends StatefulWidget {
  final String? courseId;
  final VoidCallback? onBackToHome;

  const MessagesPage({Key? key, this.courseId, this.onBackToHome})
      : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ApiService _apiService = ApiService();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _teachers = [];
  Map<String, dynamic>? _selectedTeacher;
  bool _isLoadingTeachers = true;
  String? _teachersError;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = false;
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
    _fetchTeachers();
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

  // ─── Fetch available teachers ─────────────────────────────────────────

  Future<void> _fetchTeachers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeachers = true;
      _teachersError = null;
    });

    try {
      final response =
          await _apiService.request('direct-chat/teachers', null, 'GET');
      if (mounted) {
        if (response != null &&
            response.statusCode == 200 &&
            response.data is List) {
          final List<Map<String, dynamic>> list =
              List<Map<String, dynamic>>.from(
            (response.data as List)
                .map((e) => Map<String, dynamic>.from(e as Map)),
          );
          setState(() {
            _teachers = list;
            _isLoadingTeachers = false;
            if (_teachers.isNotEmpty) {
              _selectedTeacher = _teachers.first;
            }
          });

          if (_selectedTeacher != null) {
            _fetchMessages(clear: true);
          }
        } else {
          setState(() {
            _isLoadingTeachers = false;
            _teachersError = AppLocalizations.of(context)?.cannotLoadTeachers ?? "تعذر تحميل قائمة المدرسين";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeachers = false;
          _teachersError = AppLocalizations.of(context)?.errorLoadingTeachers(e.toString()) ?? "حدث خطأ أثناء تحميل المدرسين: $e";
        });
      }
    }
  }

  // ─── Fetch messages ────────────────────────────────────────────────────

  Future<void> _fetchMessages({bool clear = false}) async {
    if (_isLoadingMessages || (!_hasMore && !clear)) return;
    if (!mounted) return;
    if (_selectedTeacher == null) return;

    final String teacherId = _selectedTeacher!['_id']?.toString() ?? '';
    if (teacherId.isEmpty) return;

    setState(() {
      _isLoadingMessages = true;
      if (clear) {
        _loadFailed = false;
        _loadFailedReason = null;
      }
    });

    try {
      final page = clear ? 1 : _currentPage + 1;
      final String endpoint =
          'direct-chat/messages/$teacherId?page=$page&limit=$_limit';

      final response = await _apiService.request(endpoint, null, 'GET');

      if (mounted) {
        if (response == null) {
          setState(() {
            _isLoadingMessages = false;
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
            _isLoadingMessages = false;
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
                      (m) => m['_id']?.toString().startsWith('temp_') == true)
                  .toList();
              _messages = [...tempMessages, ...newMessages];
              _currentPage = 1;
            } else {
              final tempMessages = _messages
                  .where(
                      (m) => m['_id']?.toString().startsWith('temp_') == true)
                  .toList();
              final realMessages = _messages
                  .where(
                      (m) => m['_id']?.toString().startsWith('temp_') != true)
                  .toList();
              _messages = [...tempMessages, ...realMessages, ...newMessages];
              _currentPage = page;
            }
            _hasMore = newMessages.length == _limit;
            _isLoadingMessages = false;
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
            _isLoadingMessages = false;
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
          _isLoadingMessages = false;
          if (clear) {
            _loadFailed = true;
            _loadFailedReason = e.toString();
          }
        });
        _showError(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? "حدث خطأ: $e");
      }
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────

  Future<void> _handleRefresh() async {
    await _fetchTeachers();
    if (_selectedTeacher != null) {
      await _fetchMessages(clear: true);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !_isLoadingMessages &&
        _hasMore) {
      _fetchMessages();
    }
  }

  // ─── Helpers to get sender info ───────────────────────────────────────

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
    if (_selectedTeacher == null) {
      _showError(AppLocalizations.of(context)?.pleaseSelectTeacherFirst ?? "يرجى اختيار المدرس أولاً");
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
      'senderModel': 'Student',
      'senderName': _currentUserName ?? AppLocalizations.of(context)?.you ?? "أنت",
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
        'teacherId': _selectedTeacher!['_id'],
        if (replyToForThisMessage != null) 'replyTo': replyToForThisMessage,
      };

      final response =
          await _apiService.request('direct-chat/send', body, 'POST');

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
            AppLocalizations.of(context)?.deleteMessageTitle ?? AppLocalizations.of(context)?.deleteMessageBtn ?? "حذف الرسالة",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
            AppLocalizations.of(context)?.deleteMessageConfirm ??
                AppLocalizations.of(context)?.confirmDeleteMsg ?? "هل أنت متأكد من حذف هذه الرسالة؟",
            style: GoogleFonts.cairo()),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? AppLocalizations.of(context)?.cancelBtn ?? "إلغاء",
                style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)?.delete ?? AppLocalizations.of(context)?.deleteBtn ?? "حذف",
                style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiService.request(
          'direct-chat/delete/$messageId', null, 'DELETE');
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

  // ─── Build Header Container ───────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, bottom: 20, right: 16, left: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.getBrandGradient(),
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.onBackToHome != null) {
                      widget.onBackToHome!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1.2),
                    ),
                    child: const Icon(PhosphorIconsRegular.arrowRight,
                        color: Colors.white, size: 20),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.2),
                  ),
                  child: const Icon(PhosphorIconsFill.chatsCircle,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.teacherLiveChat ?? "محادثة المدرس المباشرة",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedTeacher != null
                            ? AppLocalizations.of(context)?.talkingToTeacher((_selectedTeacher!['name'] ?? 'المدرس').toString()) ?? "تتحدث مع: ${_selectedTeacher!['name'] ?? 'المدرس'}"
                            : AppLocalizations.of(context)?.askTeacherWillReply ?? "اسأل وسيقوم المدرس بالرد عليك",
                        style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _handleRefresh,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: const Icon(PhosphorIconsRegular.arrowClockwise,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build Teacher Selector Header ────────────────────────────────────

  Widget _buildTeacherSelector(bool isDark) {
    if (_isLoadingTeachers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_teachersError != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(_teachersError!,
            style: GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
      );
    }

    if (_teachers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
            AppLocalizations.of(context)?.noTeachersAvailable ??
                AppLocalizations.of(context)?.noTeachersAvailableNow ?? "لا يوجد مدرسون متاحون حالياً",
            style:
                GoogleFonts.cairo(color: AppColors.getTextHintColor(isDark))),
      );
    }

    if (_teachers.length == 1) {
      return const SizedBox.shrink();
    }

    // Multiple teachers -> pill selector bar
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getCardBorderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.usersThree,
                  size: 16, color: AppColors.sky(isDark)),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)?.selectTeacherToChat ?? "اختر المدرس للمحادثة:",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextSecondaryColor(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _teachers.map((teacher) {
                final bool isSelected =
                    _selectedTeacher?['_id'] == teacher['_id'];
                return GestureDetector(
                  onTap: () {
                    if (_selectedTeacher?['_id'] != teacher['_id']) {
                      setState(() {
                        _selectedTeacher = teacher;
                        _messages.clear();
                      });
                      _fetchMessages(clear: true);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sky(isDark)
                          : AppColors.getCircleBackgroundColor(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.sky(isDark)
                            : AppColors.getCardBorderColor(isDark),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsFill.userCircle,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextColor(isDark),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          teacher['name'] ?? AppLocalizations.of(context)?.teacherLabel ?? "مدرس",
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.getTextColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build message item ──────────────────────────────────────────────

  Widget _buildMessageItem(Map<String, dynamic> msg, bool isDark) {
    final String senderModel = msg['senderModel'] ?? '';
    final bool isMine =
        senderModel == 'Student' || _getSenderId(msg) == _currentUserId;
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
        margin: const EdgeInsets.only(bottom: 12),
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
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? (isFailed
                              ? Colors.red.shade300
                              : (isTemp
                                  ? Colors.orange.shade300
                                  : AppColors.sky(isDark)))
                          : AppColors.getInputBackgroundColor(isDark),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
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
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  senderName,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isMine
                        ? AppColors.sky(isDark)
                        : AppColors.greenStatus(isDark),
                    fontWeight: FontWeight.w700,
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

  // ─── Build Main Widget ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (widget.onBackToHome != null) {
          widget.onBackToHome!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        body: Column(
        children: <Widget>[
          _buildHeader(isDark),
          _buildTeacherSelector(isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _messages.isEmpty && !_isLoadingMessages && _loadFailed
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
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
                            onPressed: _handleRefresh,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.of(context)?.retryBtn ?? "إعادة المحاولة",
                                style: GoogleFonts.cairo()),
                          ),
                        ],
                      ),
                    )
                  : _messages.isEmpty && !_isLoadingMessages
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                PhosphorIconsFill.chatsCircle,
                                size: 56,
                                color: AppColors.sky(isDark).withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context)?.noMessagesWithTeacher ?? "لا توجد رسائل مع المدرس بعد",
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppColors.getTextSecondaryColor(isDark),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppLocalizations.of(context)?.writeQuestionTeacherReply ?? "اكتب سؤالك أو استفسارك وسيقوم المدرس بالرد عليك!",
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
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
                              horizontal: 16, vertical: 12),
                          itemCount:
                              _messages.length + (_isLoadingMessages ? 1 : 0),
                          itemBuilder: (BuildContext ctx, int idx) {
                            if (idx == _messages.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            return _buildMessageItem(_messages[idx], isDark);
                          },
                        ),
            ),
          ),

          // Reply Banner Preview
          if (_replyToId != null && _replyToMessage != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.getCardBackgroundColor(isDark),
                border: Border(
                  top: BorderSide(color: AppColors.sky(isDark), width: 2),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(PhosphorIconsRegular.arrowBendUpLeft,
                      size: 16, color: AppColors.sky(isDark)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)?.replyingToMessage ?? "الرد على رسالة:",
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sky(isDark),
                          ),
                        ),
                        Text(
                          _replyToMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _replyToId = null;
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Bottom Input Bar (padded above _CustomBottomNavBar)
          Builder(
            builder: (context) {
              final double bottomPadding =
                  MediaQuery.of(context).viewInsets.bottom > 0 ? 12.0 : 16.0;
              return Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: bottomPadding,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(isDark),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.getCardBorderColor(isDark),
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextColor(isDark),
                            fontSize: 14),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)?.writeMessageToTeacher ?? "اكتب رسالتك للمدرس...",
                          hintStyle: GoogleFonts.cairo(
                              color: AppColors.getTextHintColor(isDark),
                              fontSize: 13),
                          filled: true,
                          fillColor:
                              AppColors.getInputBackgroundColor(isDark),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AppColors.getCardBorderColor(isDark),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: AppColors.getCardBorderColor(isDark),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _isSending ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                            : const Icon(
                                PhosphorIconsFill.paperPlaneRight,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
}

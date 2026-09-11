import 'package:flutter/material.dart';

class Level {
  final String code;
  final String label;
  final int order;
  final List<String> linkedDepartments;

  Level({
    required this.code,
    required this.label,
    required this.order,
    required this.linkedDepartments,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        'order': order,
        'linkedDepartments': linkedDepartments,
      };

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      code: json['code'] ?? '',
      label: json['label'] ?? '',
      order: json['order'] ?? 0,
      linkedDepartments: List<String>.from(json['linkedDepartments'] ?? []),
    );
  }
}

class Department {
  final String code;
  final String label;
  final int order;

  Department({
    required this.code,
    required this.label,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
        'order': order,
      };

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      code: json['code'] ?? '',
      label: json['label'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class CombinedLevel {
  final String value;
  final String label;
  final String levelCode;
  final String departmentCode;

  CombinedLevel({
    required this.value,
    required this.label,
    required this.levelCode,
    required this.departmentCode,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'levelCode': levelCode,
        'departmentCode': departmentCode,
      };

  factory CombinedLevel.fromJson(Map<String, dynamic> json) {
    return CombinedLevel(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      levelCode: json['levelCode'] ?? '',
      departmentCode: json['departmentCode'] ?? '',
    );
  }
}

class AppColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color error;

  AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.error,
  });

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Map<String, dynamic> toJson() => {
        'primary': _colorToHex(primary),
        'secondary': _colorToHex(secondary),
        'background': _colorToHex(background),
        'surface': _colorToHex(surface),
        'textPrimary': _colorToHex(textPrimary),
        'textSecondary': _colorToHex(textSecondary),
        'success': _colorToHex(success),
        'error': _colorToHex(error),
      };

  factory AppColors.fromJson(Map<String, dynamic> json) {
    return AppColors(
      primary: _parseColor(json['primary'] ?? '#1A37F7'),
      secondary: _parseColor(json['secondary'] ?? '#1A37F7'),
      background: _parseColor(json['background'] ?? '#F5F5F5'),
      surface: _parseColor(json['surface'] ?? '#FFFFFF'),
      textPrimary: _parseColor(json['textPrimary'] ?? '#212529'),
      textSecondary: _parseColor(json['textSecondary'] ?? '#6C757D'),
      success: _parseColor(json['success'] ?? '#28A745'),
      error: _parseColor(json['error'] ?? '#DC3545'),
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }
}

class ContactEntry {
  final String id;
  final String displayName;
  final String value;

  ContactEntry({
    required this.id,
    required this.displayName,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        '_id': id,
        'displayName': displayName,
        'value': value,
      };

  factory ContactEntry.fromJson(Map<String, dynamic> json) {
    return ContactEntry(
      id: json['_id']?.toString() ?? '',
      displayName: json['displayName'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class ContactInfo {
  final List<ContactEntry> whatsapp;
  final List<ContactEntry> facebook;
  final List<ContactEntry> techSupport;

  ContactInfo({
    this.whatsapp = const [],
    this.facebook = const [],
    this.techSupport = const [],
  });

  bool get isEmpty =>
      whatsapp.isEmpty && facebook.isEmpty && techSupport.isEmpty;

  Map<String, dynamic> toJson() => {
        'whatsapp': whatsapp.map((e) => e.toJson()).toList(),
        'facebook': facebook.map((e) => e.toJson()).toList(),
        'techSupport': techSupport.map((e) => e.toJson()).toList(),
      };

  static List<ContactEntry> _parseList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => ContactEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      whatsapp: _parseList(json['whatsapp']),
      facebook: _parseList(json['facebook']),
      techSupport: _parseList(json['techSupport']),
    );
  }
}

class OverlayIconDisplay {
  final bool whatsapp;
  final bool facebook;
  final bool techSupport;

  OverlayIconDisplay({
    this.whatsapp = false,
    this.facebook = false,
    this.techSupport = false,
  });

  Map<String, dynamic> toJson() => {
        'whatsapp': whatsapp,
        'facebook': facebook,
        'techSupport': techSupport,
      };

  factory OverlayIconDisplay.fromJson(Map<String, dynamic> json) {
    return OverlayIconDisplay(
      whatsapp: json['whatsapp'] ?? false,
      facebook: json['facebook'] ?? false,
      techSupport: json['techSupport'] ?? false,
    );
  }
}

class FawaterakConfig {
  final bool enabled;

  FawaterakConfig({
    this.enabled = false,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
      };

  factory FawaterakConfig.fromJson(Map<String, dynamic> json) {
    return FawaterakConfig(
      enabled: json['enabled'] ?? false,
    );
  }
}

class CustomRegistrationField {
  final String id;
  final String label;
  final String type; // 'text' | 'select'
  final List<String> options;
  final int? maxLength;
  final bool required;

  CustomRegistrationField({
    required this.id,
    required this.label,
    required this.type,
    this.options = const [],
    this.maxLength,
    this.required = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type,
        'options': options,
        'maxLength': maxLength,
        'required': required,
      };

  factory CustomRegistrationField.fromJson(Map<String, dynamic> json) {
    return CustomRegistrationField(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      options: List<String>.from(json['options'] ?? []),
      maxLength: json['maxLength'] is int
          ? json['maxLength']
          : (json['maxLength'] != null
              ? int.tryParse(json['maxLength'].toString())
              : null),
      required: json['required'] ?? false,
    );
  }
}

class CompanySettingsModel {
  final List<Level> levels;
  final List<Department> departments;
  final List<CombinedLevel> combinedLevels;
  final bool useCustomLevels;
  final bool useCustomDepartments;
  final bool requireParentPhone;
  final bool requireStudentVerify;
  final bool enableOfflinePdf;
  final bool enableOfflineVideo;
  final bool enableOfflineCourses;
  final int offlineCoursesDaysLimit;
  final AppColors appColors;
  final String companyId;
  final String? teacherTitle;
  final ContactInfo contactInfo;
  final OverlayIconDisplay overlayIconDisplay;
  final bool useNestedLevels;
  final FawaterakConfig fawaterakConfig;
  final String purchaseWhatsAppNumber;
  final List<CustomRegistrationField> customRegistrationFields;

  CompanySettingsModel({
    required this.levels,
    required this.departments,
    required this.combinedLevels,
    required this.useCustomLevels,
    required this.useCustomDepartments,
    required this.requireParentPhone,
    required this.requireStudentVerify,
    required this.enableOfflinePdf,
    required this.enableOfflineVideo,
    required this.enableOfflineCourses,
    required this.offlineCoursesDaysLimit,
    required this.appColors,
    required this.companyId,
    this.teacherTitle,
    required this.contactInfo,
    required this.overlayIconDisplay,
    required this.useNestedLevels,
    required this.fawaterakConfig,
    this.purchaseWhatsAppNumber = '',
    this.customRegistrationFields = const [],
  });

  Map<String, dynamic> toJson() => {
        'levels': levels.map((l) => l.toJson()).toList(),
        'departments': departments.map((d) => d.toJson()).toList(),
        'combinedLevels': combinedLevels.map((c) => c.toJson()).toList(),
        'useCustomLevels': useCustomLevels,
        'useCustomDepartments': useCustomDepartments,
        'requireParentPhone': requireParentPhone,
        'requireStudentVerify': requireStudentVerify,
        'enableOfflinePdf': enableOfflinePdf,
        'enableOfflineVideo': enableOfflineVideo,
        'enableOfflineCourses': enableOfflineCourses,
        'offlineCoursesDaysLimit': offlineCoursesDaysLimit,
        'appColors': appColors.toJson(),
        'companyId': companyId,
        'teacherTitle': teacherTitle,
        'contactInfo': contactInfo.toJson(),
        'overlayIconDisplay': overlayIconDisplay.toJson(),
        'useNestedLevels': useNestedLevels,
        'fawaterakConfig': fawaterakConfig.toJson(),
        'purchaseWhatsAppNumber': purchaseWhatsAppNumber,
        'customRegistrationFields':
            customRegistrationFields.map((f) => f.toJson()).toList(),
      };

  factory CompanySettingsModel.fromJson(Map<String, dynamic> json) {
    return CompanySettingsModel(
      levels:
          (json['levels'] as List?)?.map((l) => Level.fromJson(l)).toList() ??
              [],
      departments: (json['departments'] as List?)
              ?.map((d) => Department.fromJson(d))
              .toList() ??
          [],
      combinedLevels: (json['combinedLevels'] as List?)
              ?.map((c) => CombinedLevel.fromJson(c))
              .toList() ??
          [],
      useCustomLevels: json['useCustomLevels'] ?? false,
      useCustomDepartments: json['useCustomDepartments'] ?? false,
      requireParentPhone: json['requireParentPhone'] ?? false,
      requireStudentVerify: json['requireStudentVerify'] ?? false,
      enableOfflinePdf: json['enableOfflinePdf'] ?? false,
      enableOfflineVideo: json['enableOfflineVideo'] ?? false,
      enableOfflineCourses: json['enableOfflineCourses'] ?? false,
      offlineCoursesDaysLimit: json['offlineCoursesDaysLimit'] ?? 7,
      appColors: AppColors.fromJson(json['appColors'] ?? {}),
      companyId: json['companyId'] ?? '',
      teacherTitle: json['teacherTitle'],
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
      overlayIconDisplay:
          OverlayIconDisplay.fromJson(json['overlayIconDisplay'] ?? {}),
      useNestedLevels: json['useNestedLevels'] ?? false,
      fawaterakConfig: FawaterakConfig.fromJson(json['fawaterakConfig'] ?? {}),
      purchaseWhatsAppNumber: json['purchaseWhatsAppNumber'] ?? '',
      customRegistrationFields: (json['customRegistrationFields'] as List?)
              ?.map((f) => CustomRegistrationField.fromJson(f))
              .toList() ??
          [],
    );
  }
}


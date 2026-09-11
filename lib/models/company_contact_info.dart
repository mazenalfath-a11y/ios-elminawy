class ContactEntry {
  final String id;
  final String displayName;
  final String value;

  ContactEntry(
      {required this.id, required this.displayName, required this.value});

  factory ContactEntry.fromJson(Map<String, dynamic> json) => ContactEntry(
        id: json["_id"]?.toString() ?? "",
        displayName: json["displayName"]?.toString() ?? "",
        value: json["value"]?.toString() ?? "",
      );
}

class CompanyContactInfo {
  final List<ContactEntry> whatsapp;
  final List<ContactEntry> facebook;
  final List<ContactEntry> techSupport;

  CompanyContactInfo({
    required this.whatsapp,
    required this.facebook,
    required this.techSupport,
  });

  factory CompanyContactInfo.fromJson(Map<String, dynamic>? json) {
    List<ContactEntry> parse(dynamic raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ContactEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ContactEntry>[];

    return CompanyContactInfo(
      whatsapp: parse(json?["whatsapp"]),
      facebook: parse(json?["facebook"]),
      techSupport: parse(json?["techSupport"]),
    );
  }

  bool get isEmpty =>
      whatsapp.isEmpty && facebook.isEmpty && techSupport.isEmpty;
}

class OverlayIconDisplay {
  final bool whatsapp;
  final bool facebook;
  final bool techSupport;

  OverlayIconDisplay({
    required this.whatsapp,
    required this.facebook,
    required this.techSupport,
  });

  factory OverlayIconDisplay.fromJson(Map<String, dynamic>? json) =>
      OverlayIconDisplay(
        whatsapp: json?["whatsapp"] == true,
        facebook: json?["facebook"] == true,
        techSupport: json?["techSupport"] == true,
      );

  bool get anyEnabled => whatsapp || facebook || techSupport;
}

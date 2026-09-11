class Category {
  final String id;
  final String name;
  final String? photo;
  final String? parentId;
  final List<Category>? children;
  final int? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.photo,
    this.parentId,
    this.children,
    this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      photo: json['photo'],
      price: json['price'] != null
          ? int.tryParse(json['price'].toString())
          : (json['Price'] != null
              ? int.tryParse(json['Price'].toString())
              : (json['coursePrice'] != null
                  ? int.tryParse(json['coursePrice'].toString())
                  : null)),
      parentId:
          json['parent'] is String ? json['parent'] : json['parent']?['_id'],
      children: json['children'] != null
          ? (json['children'] as List)
              .map((child) => Category.fromJson(child))
              .toList()
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'photo': photo,
      'price': price,
      'parent': parentId,
      'children': children?.map((child) => child.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class Shop {
  final String code;
  final String name;
  final String ownerName;
  final String category;

  Shop({
    required this.code,
    required this.name,
    required this.ownerName,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'owner_name': ownerName,
      'category': category,
    };
  }

  static Shop fromMap(Map<String, dynamic> map) {
    return Shop(
      code: map['code'],
      name: map['name'],
      ownerName: map['owner_name'],
      category: map['category'],
    );
  }
} 
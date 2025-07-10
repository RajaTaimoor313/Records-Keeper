class Shop {
  final String code;
  final String name;
  final String ownerName;
  final String category;
  final String? address;
  final String? area;
  final String? phone;
  final double previousBalance;

  Shop({
    required this.code,
    required this.name,
    required this.ownerName,
    required this.category,
    this.address,
    this.area,
    this.phone,
    this.previousBalance = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'owner_name': ownerName,
      'category': category,
      'address': address,
      'area': area,
      'phone': phone,
      'previousBalance': previousBalance,
    };
  }

  static Shop fromMap(Map<String, dynamic> map) {
    return Shop(
      code: map['code'],
      name: map['name'],
      ownerName: map['owner_name'],
      category: map['category'],
      address: map['address'],
      area: map['area'],
      phone: map['phone'],
      previousBalance: (map['previousBalance'] ?? 0) is int
          ? (map['previousBalance'] ?? 0).toDouble()
          : (map['previousBalance'] ?? 0) as double,
    );
  }
}

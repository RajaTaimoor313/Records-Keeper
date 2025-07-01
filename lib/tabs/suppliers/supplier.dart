class Supplier {
  final int? id;
  final String name;
  final String fatherName;
  final String address;
  final String cnic;
  final String phone;
  final String type; // 'Supplier' or 'Order Booker'

  Supplier({
    this.id,
    required this.name,
    required this.fatherName,
    required this.address,
    required this.cnic,
    required this.phone,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'fatherName': fatherName,
      'address': address,
      'cnic': cnic,
      'phone': phone,
      'type': type,
    };
  }

  static Supplier fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      address: map['address'] ?? '',
      cnic: map['cnic'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? 'Supplier',
    );
  }
}

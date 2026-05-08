class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
  });

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'created_at': createdAt,
    };

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }
}

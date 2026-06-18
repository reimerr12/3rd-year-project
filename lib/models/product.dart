class Product {
  final String id;
  final String sellerId;
  final String title;
  final String? description;
  final String category; //
  final double price;
  final String unit;
  final int stock;
  final List<String> images;
  final String? division;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
    required this.images,
    this.division,
    required this.isActive,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      sellerId: map['seller_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'other',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      stock: map['stock'] ?? 0,
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      division: map['division'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'seller_id': sellerId,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'unit': unit,
        'stock': stock,
        'images': images,
        'division': division,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  Product copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? unit,
    int? stock,
    List<String>? images,
    String? division,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      Product(
        id: id ?? this.id,
        sellerId: sellerId ?? this.sellerId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        price: price ?? this.price,
        unit: unit ?? this.unit,
        stock: stock ?? this.stock,
        images: images ?? this.images,
        division: division ?? this.division,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );

  /// First image or null
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  /// Stock helper
  bool get inStock => stock > 0;

  /// Bangla category label
  String get categoryBn {
    switch (category) {
      case 'crop':
        return 'ফসল';
      case 'fertilizer':
        return 'সার';
      case 'insecticide':
        return 'কীটনাশক';
      case 'tool':
        return 'সরঞ্জাম';
      default:
        return 'অন্যান্য';
    }
  }

  @override
  String toString() => 'Product(id: $id, title: $title, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          other.id == id &&
          other.sellerId == sellerId &&
          other.title == title &&
          other.category == category &&
          other.price == price;

  @override
  int get hashCode =>
      id.hashCode ^
      sellerId.hashCode ^
      title.hashCode ^
      category.hashCode ^
      price.hashCode;
}

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final int quantity;
  final double total;
  final String status; // pending,confirmed,shipped,delivered,cancelled
  final String? paymentMethod; // bkash,sslcommerz,cash
  final String? deliveryAddress;
  final String? notes;
  final DateTime? paidAt;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.deliveryAddress,
    this.notes,
    this.paidAt,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      buyerId: map['buyer_id'] ?? '',
      sellerId: map['seller_id'] ?? '',
      productId: map['product_id'] ?? '',
      quantity: map['quantity'] ?? 1,
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['payment_method'],
      deliveryAddress: map['delivery_address'],
      notes: map['notes'],
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at']) : null,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'product_id': productId,
        'quantity': quantity,
        'total': total,
        'status': status,
        'payment_method': paymentMethod,
        'delivery_address': deliveryAddress,
        'notes': notes,
        'paid_at': paidAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  /// Bangla status label
  String get statusBn {
    switch (status) {
      case 'pending':
        return 'অপেক্ষমাণ';
      case 'confirmed':
        return 'নিশ্চিত';
      case 'shipped':
        return 'পাঠানো হয়েছে';
      case 'delivered':
        return 'পৌঁছে গেছে';
      case 'cancelled':
        return 'বাতিল';
      default:
        return status;
    }
  }

  @override
  String toString() => 'Order(id: $id, status: $status, total: $total)';
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String? note;
  final String? orderNumber;
  final double? discount;
  final String? discountCode;
  final String? discountSource;
  final List<StatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.note,
    this.orderNumber,
    this.discount,
    this.discountCode,
    this.discountSource,
    required this.statusHistory,
    required this.createdAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      note: json['note'],
      orderNumber: json['orderNumber'],
      discount: (json['discount'] ?? 0).toDouble(),
      discountCode: json['discountCode'],
      discountSource: json['discountSource'],
      statusHistory: (json['statusHistory'] as List<dynamic>? ?? [])
          .map((item) => StatusHistory.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt']) : null,
    );
  }
}

class OrderItem {
  final String productId;
  final int quantity;
  final double price;
  final String? name;
  final double? total;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
    this.name,
    this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] is Map ? json['productId']['_id'] : (json['productId'] ?? ''),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      name: json['name'],
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String? note;

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }
} 
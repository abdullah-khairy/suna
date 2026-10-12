import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  earning,     // دخل من إتمام خدمة
  withdrawal,  // سحب رصيد لحساب بنكي أو كاش
  deposit,     // إيداع أو شحن المحفظة
  commission,  // خصم عمولة التطبيق
}

extension TransactionTypeExtension on TransactionType {
  String get titleAr {
    switch (this) {
      case TransactionType.earning:
        return 'أجر خدمة مكتملة';
      case TransactionType.withdrawal:
        return 'سحب رصيد';
      case TransactionType.deposit:
        return 'شحن محفظة';
      case TransactionType.commission:
        return 'عمولة التطبيق';
    }
  }

  bool get isPositive =>
      this == TransactionType.earning || this == TransactionType.deposit;
}

class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String title;
  final String? relatedRequestId;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.title,
    this.relatedRequestId,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WalletTransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.earning,
      ),
      title: data['title'] ?? '',
      relatedRequestId: data['relatedRequestId'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'title': title,
      'relatedRequestId': relatedRequestId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

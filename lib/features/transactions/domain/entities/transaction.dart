/// Model transaksi keuangan — entitas inti aplikasi.
///
/// amount selalu > 0. Tipe (income/expense) menentukan apakah
/// nilai ini menambah atau mengurangi saldo.
library; // Transaction domain entity with API serialization.

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get apiValue => name; // 'income' atau 'expense'

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;

  String get label => isIncome ? 'Pendapatan' : 'Pengeluaran';
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final DateTime transactionDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.transactionDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: double.parse(json['amount'].toString()),
      categoryId:
          json['category_id'] as String? ?? json['category']['id'] as String,
      categoryName:
          json['category_name'] as String? ??
          json['category']['name'] as String,
      categoryIcon:
          json['category_icon'] as String? ??
          json['category']?['icon'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'amount': amount,
      'category_id': categoryId,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    DateTime? transactionDate,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Wrapper untuk paginated response dari API.
class TransactionListResponse {
  final List<Transaction> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const TransactionListResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  /// Backend membalas envelope datar: `{data, total, page, limit}`
  /// (bukan `{meta:{...}}`). total_pages dihitung dari total/limit.
  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = ((json['data'] as List<dynamic>?) ?? const [])
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();

    final page = (json['page'] as num?)?.toInt() ?? 1;
    final limit = (json['limit'] as num?)?.toInt() ?? dataList.length;
    final total = (json['total'] as num?)?.toInt() ?? dataList.length;
    final totalPages = limit > 0 ? (total + limit - 1) ~/ limit : 1;

    return TransactionListResponse(
      data: dataList,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }
}

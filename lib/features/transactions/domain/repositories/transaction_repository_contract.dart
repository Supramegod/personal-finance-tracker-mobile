import '../entities/transaction.dart';

abstract interface class TransactionRepositoryContract {
  Future<TransactionListResponse> list({
    int page,
    int limit,
    TransactionType? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? search,
  });
  Future<Transaction> create(Transaction transaction);
  Future<Transaction> update(String id, Transaction transaction);
  Future<void> delete(String id);
}

import 'dart:async'; // Import async để sử dụng Stream
import 'package:rxdart/rxdart.dart'; // Import RxDart để combine streams
import '../models/statistics_data.dart'; // Import CombinedStatisticsData
import '../models/transaction_model.dart'; // Import TransactionModel
import '../models/category_model.dart'; // Import CategoryModel
import '../models/wallet_model.dart'; // Import WalletModel
import 'transaction_service.dart'; // Import TransactionService
import 'wallet_service.dart'; // Import WalletService

/// Service kết hợp nhiều Firestore streams một cách hiệu quả
/// Loại bỏ nested StreamBuilders và cải thiện performance
/// Sử dụng RxDart để combine 3 streams thành 1 stream duy nhất
class QueryCombinerService {
  // Singleton pattern - chỉ có 1 instance duy nhất
  static final QueryCombinerService _instance =
      QueryCombinerService._internal();
  factory QueryCombinerService() =>
      _instance; // Factory trả về instance duy nhất
  QueryCombinerService._internal(); // Private constructor

  final TransactionService _transactionService =
      TransactionService(); // Instance TransactionService
  final WalletService _walletService =
      WalletService(); // Instance WalletService

  // Cache combined streams theo userId để tránh tạo lại nhiều lần
  final Map<String, Stream<CombinedStatisticsData>> _statisticsStreamCache = {};

  /// Lấy dữ liệu thống kê kết hợp (transactions, categories, wallets)
  /// Thay thế 3 nested StreamBuilders bằng 1 stream duy nhất
  /// Return: Stream chứa CombinedStatisticsData
  Stream<CombinedStatisticsData> getStatisticsData(String userId) {
    // Trả về cached stream nếu đã tồn tại (tránh tạo lại)
    if (_statisticsStreamCache.containsKey(userId)) {
      return _statisticsStreamCache[userId]!;
    }

    // Tạo combined stream sử dụng RxDart's CombineLatest3
    // Kết hợp 3 streams: transactions, categories, wallets
    final combinedStream =
        CombineLatestStream.combine3<
              List<TransactionModel>,
              List<CategoryModel>,
              List<WalletModel>,
              CombinedStatisticsData
            >(
              _transactionService.getTransactions(
                userId,
              ), // Stream 1: Transactions
              _transactionService.getCategories(), // Stream 2: Categories
              _walletService.getWallets(userId), // Stream 3: Wallets
              (transactions, categories, wallets) {
                // Combiner function: Kết hợp 3 lists thành CombinedStatisticsData
                return CombinedStatisticsData(
                  transactions: transactions,
                  categories: categories,
                  wallets: wallets,
                );
              },
            )
            .asBroadcastStream(); // Chuyển thành broadcast stream để nhiều listeners có thể sử dụng

    // Cache stream để tái sử dụng
    _statisticsStreamCache[userId] = combinedStream;

    return combinedStream;
  }

  /// Xóa cache cho một user cụ thể (hữu ích khi user đăng xuất)
  void clearCache(String userId) {
    _statisticsStreamCache.remove(userId);
  }

  /// Xóa tất cả caches
  void clearAllCaches() {
    _statisticsStreamCache.clear();
  }
}

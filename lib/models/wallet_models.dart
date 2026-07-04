// ignore_for_file: invalid_annotation_target
import 'package:json_annotation/json_annotation.dart';

part 'wallet_models.g.dart';

// ─── RefundRequest ────────────────────────────────────────────────────────────

@JsonSerializable()
class RefundRequest {
  final String id;
  final String bookingId;
  final String userId;
  final int refundAmount;
  final String status; // PENDING | APPROVED | REJECTED
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedByStaffId;
  final String? reason;
  final String? movieTitle;
  final String? seatCodes;

  const RefundRequest({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.refundAmount,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedByStaffId,
    this.reason,
    this.movieTitle,
    this.seatCodes,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) =>
      _$RefundRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RefundRequestToJson(this);

  String get statusLabel => switch (status) {
        'PENDING' => 'Đang chờ duyệt',
        'APPROVED' => 'Đã duyệt',
        'REJECTED' => 'Bị từ chối',
        _ => status,
      };
}

// ─── WalletTransaction ────────────────────────────────────────────────────────

@JsonSerializable()
class WalletTransaction {
  final String id;
  final String type; // CREDIT | DEBIT
  final int amount;
  final String description;
  final String? refId;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.refId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  bool get isCredit => type == 'CREDIT';
}

// ─── WalletInfo ───────────────────────────────────────────────────────────────

@JsonSerializable()
class WalletInfo {
  final String walletId;
  final String userId;
  final int balance;
  final List<WalletTransaction> transactions;

  const WalletInfo({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.transactions,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) =>
      _$WalletInfoFromJson(json);
  Map<String, dynamic> toJson() => _$WalletInfoToJson(this);
}

// ─── WithdrawalRequest ────────────────────────────────────────────────────────

@JsonSerializable()
class WithdrawalRequest {
  final String id;
  final String userId;
  final int amount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String status; // PENDING | PROCESSING | COMPLETED | REJECTED
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedByStaffId;
  final String? note;
  final String? userName;

  const WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedByStaffId,
    this.note,
    this.userName,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalRequestFromJson(json);
  Map<String, dynamic> toJson() => _$WithdrawalRequestToJson(this);

  String get statusLabel => switch (status) {
        'PENDING' => 'Đang xử lý',
        'PROCESSING' => 'Đang chuyển khoản',
        'COMPLETED' => 'Đã hoàn thành',
        'REJECTED' => 'Bị từ chối',
        _ => status,
      };
}

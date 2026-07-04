// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundRequest _$RefundRequestFromJson(Map<String, dynamic> json) =>
    RefundRequest(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      refundAmount: (json['refundAmount'] as num).toInt(),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      processedByStaffId: json['processedByStaffId'] as String?,
      reason: json['reason'] as String?,
      movieTitle: json['movieTitle'] as String?,
      seatCodes: json['seatCodes'] as String?,
    );

Map<String, dynamic> _$RefundRequestToJson(RefundRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'userId': instance.userId,
      'refundAmount': instance.refundAmount,
      'status': instance.status,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'processedByStaffId': instance.processedByStaffId,
      'reason': instance.reason,
      'movieTitle': instance.movieTitle,
      'seatCodes': instance.seatCodes,
    };

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    WalletTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String,
      refId: json['refId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WalletTransactionToJson(WalletTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'refId': instance.refId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

WalletInfo _$WalletInfoFromJson(Map<String, dynamic> json) => WalletInfo(
  walletId: json['walletId'] as String,
  userId: json['userId'] as String,
  balance: (json['balance'] as num).toInt(),
  transactions: (json['transactions'] as List<dynamic>)
      .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WalletInfoToJson(WalletInfo instance) =>
    <String, dynamic>{
      'walletId': instance.walletId,
      'userId': instance.userId,
      'balance': instance.balance,
      'transactions': instance.transactions,
    };

WithdrawalRequest _$WithdrawalRequestFromJson(Map<String, dynamic> json) =>
    WithdrawalRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toInt(),
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountHolder: json['accountHolder'] as String,
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      processedByStaffId: json['processedByStaffId'] as String?,
      note: json['note'] as String?,
      userName: json['userName'] as String?,
    );

Map<String, dynamic> _$WithdrawalRequestToJson(WithdrawalRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'amount': instance.amount,
      'bankName': instance.bankName,
      'accountNumber': instance.accountNumber,
      'accountHolder': instance.accountHolder,
      'status': instance.status,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'processedByStaffId': instance.processedByStaffId,
      'note': instance.note,
      'userName': instance.userName,
    };

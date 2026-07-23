import '../../gold/models/gold_purchase_model.dart';
import '../../loans/models/loan_models.dart';

class CustomerPaymentUpdate {
  final int? id;
  final int personId;
  final int loanId;
  final String paymentDate;
  final double interestAmount;
  final double principalAmount;
  final double? remainingBalance;
  final String paymentType;
  final String? referenceNumber;
  final String? file;
  final String? note;

  CustomerPaymentUpdate({
    this.id,
    required this.personId,
    required this.loanId,
    required this.paymentDate,
    required this.interestAmount,
    required this.principalAmount,
    this.remainingBalance,
    required this.paymentType,
    this.referenceNumber,
    this.file,
    this.note,
  });

  factory CustomerPaymentUpdate.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentUpdate(
      id: json['id'],
      personId: json['personId'] ?? 0,
      loanId: json['loanId'] ?? 0,
      paymentDate: json['paymentDate'] ?? '',
      interestAmount: _toDouble(json['interestAmount']) ?? 0.0,
      principalAmount: _toDouble(json['principalAmount']) ?? 0.0,
      remainingBalance: _toDouble(json['remainingBalance']),
      paymentType: json['paymentTYpe'] ?? json['paymentType'] ?? '',
      referenceNumber: json['referenceNUmber'] ?? json['referenceNumber'],
      file: json['file'],
      note: json['note'],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class CustomerLoan {
  final int id;
  final int personId;
  final String loanPeriodType;
  final int loanPeriod;
  final String loanDate;
  final double principalAmount;
  final double interestRate;
  final String interestPaymentPeriodType;
  final int interestPaymentPeriod;
  final String? agreementImage;
  final double totalPaidAmount;
  final double pendingAmount;
  final String status;
  final String note;
  final int? remainingMonths;

  CustomerLoan({
    required this.id,
    required this.personId,
    required this.loanPeriodType,
    required this.loanPeriod,
    required this.loanDate,
    required this.principalAmount,
    required this.interestRate,
    required this.interestPaymentPeriodType,
    required this.interestPaymentPeriod,
    this.agreementImage,
    required this.totalPaidAmount,
    required this.pendingAmount,
    required this.status,
    required this.note,
    this.remainingMonths,
  });

  factory CustomerLoan.fromJson(Map<String, dynamic> json) {
    return CustomerLoan(
      id: json['id'] ?? 0,
      personId: json['personId'] ?? 0,
      loanPeriodType: json['loanPeriodType'] ?? '',
      loanPeriod: json['loanPeriod'] ?? 0,
      loanDate: json['loanDate'] ?? '',
      principalAmount: _toDouble(json['principalAmount']) ?? 0.0,
      interestRate: _toDouble(json['interestRate']) ?? 0.0,
      interestPaymentPeriodType: json['interestPaymentPeriodType'] ?? '',
      interestPaymentPeriod: json['interestPaymentPeriod'] ?? 0,
      agreementImage: json['agreementImage'],
      totalPaidAmount: _toDouble(json['totalPaidAmount']) ?? 0.0,
      pendingAmount: _toDouble(json['pendingAmount']) ?? 0.0,
      status: json['status'] ?? '',
      note: json['note'] ?? '',
      remainingMonths: json['remainingMonths'],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class Customer {
  final int? id;
  final String name;
  final String phoneNumber;
  final int? createdBy;
  final String? createdByName;
  final String? createdAt;

  // Stats / Bento Box Summaries
  final double? totalPurchase;
  final int? purchaseTransactionsCount;
  final double? totalSell;
  final int? sellTransactionsCount;
  final double? totalDue;
  final int? duePaymentsCount;

  // Sell History Headers
  final double? totalGoldSellWeight;
  final int? goldSellTransactionsCount;
  final double? totalReceivedAmount;
  final String? lastSellDate;

  // History Lists
  final List<GoldPurchase> purchaseHistory;
  final List<GoldPurchase> sellHistory;
  final List<CustomerLoan> loans;
  final List<CustomerPaymentUpdate> paymentUpdates;
  final List<PersonDetails> persons;
  final List<LoanDue> dues;

  Customer({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.totalPurchase,
    this.purchaseTransactionsCount,
    this.totalSell,
    this.sellTransactionsCount,
    this.totalDue,
    this.duePaymentsCount,
    this.totalGoldSellWeight,
    this.goldSellTransactionsCount,
    this.totalReceivedAmount,
    this.lastSellDate,
    this.purchaseHistory = const [],
    this.sellHistory = const [],
    this.loans = const [],
    this.paymentUpdates = const [],
    this.persons = const [],
    this.dues = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Parse name: match "customerName" first as returned by the API
    final parsedName = json['customerName'] ?? json['name'] ?? json['partyName'] ?? '';
    final parsedPhone = json['phoneNumber'] ?? json['partyPhoneNumber'] ?? '';

    // Parse purchaseHistory list from either "purchases" or "purchaseHistory"
    final List<GoldPurchase> purchases = [];
    final rawPurchases = json['purchases'] ?? json['purchaseHistory'];
    final rawParties = json['parties'] is List ? json['parties'] as List : [];

    if (rawPurchases != null && rawPurchases is List) {
      for (final item in rawPurchases) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        if (itemMap['party'] == null && itemMap['partyId'] != null) {
          final matchedParty = rawParties.firstWhere(
            (p) => p is Map && p['id'] == itemMap['partyId'],
            orElse: () => null,
          );
          if (matchedParty != null) {
            itemMap['party'] = Map<String, dynamic>.from(matchedParty);
          }
        }
        purchases.add(GoldPurchase.fromJson(itemMap));
      }
    }

    // Parse sellHistory list from either "sales" or "sellHistory"
    final List<GoldPurchase> sales = [];
    final rawSales = json['sales'] ?? json['sellHistory'];
    if (rawSales != null && rawSales is List) {
      for (final item in rawSales) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        if (itemMap['party'] == null && itemMap['partyId'] != null) {
          final matchedParty = rawParties.firstWhere(
            (p) => p is Map && p['id'] == itemMap['partyId'],
            orElse: () => null,
          );
          if (matchedParty != null) {
            itemMap['party'] = Map<String, dynamic>.from(matchedParty);
          }
        }
        if (itemMap['saleParty'] == null && itemMap['salePartyId'] != null) {
          final matchedSaleParty = rawParties.firstWhere(
            (p) => p is Map && p['id'] == itemMap['salePartyId'],
            orElse: () => null,
          );
          if (matchedSaleParty != null) {
            itemMap['saleParty'] = Map<String, dynamic>.from(matchedSaleParty);
          }
        }
        sales.add(GoldPurchase.fromJson(itemMap));
      }
    }

    // Parse loans list from "loans"
    final List<CustomerLoan> parsedLoans = [];
    final rawLoans = json['loans'];
    if (rawLoans != null && rawLoans is List) {
      for (final item in rawLoans) {
        parsedLoans.add(CustomerLoan.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    // Parse paymentUpdates list from "paymentUpdates"
    final List<CustomerPaymentUpdate> parsedPaymentUpdates = [];
    final rawPayments = json['paymentUpdates'];
    if (rawPayments != null && rawPayments is List) {
      for (final item in rawPayments) {
        parsedPaymentUpdates.add(CustomerPaymentUpdate.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    // Parse persons list from "persons"
    final List<PersonDetails> parsedPersons = [];
    final rawPersons = json['persons'];
    if (rawPersons != null && rawPersons is List) {
      for (final item in rawPersons) {
        parsedPersons.add(PersonDetails.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    // Parse dues list from "dues" or "duePayments"
    final List<LoanDue> parsedDues = [];
    final rawDues = json['dues'] ?? json['duePayments'];
    if (rawDues != null && rawDues is List) {
      for (final item in rawDues) {
        parsedDues.add(LoanDue.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    // Fallback: If no top-level dues are found, collect them from the nested loans list
    if (parsedDues.isEmpty && rawLoans != null && rawLoans is List) {
      for (final loanItem in rawLoans) {
        if (loanItem is Map) {
          final loanDues = loanItem['dues'];
          final int loanId = loanItem['id'] ?? 0;
          final int personId = loanItem['personId'] ?? 0;

          if (loanDues != null && loanDues is List) {
            for (final item in loanDues) {
              if (item is Map) {
                final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
                itemMap['loanId'] ??= loanId;
                itemMap['personId'] ??= personId;
                itemMap['personName'] ??= parsedName;

                parsedDues.add(LoanDue.fromJson(itemMap));
              }
            }
          }
        }
      }
    }


    // If stats are not returned by the backend, dynamically compute them from history
    double computedPurchase = 0.0;
    for (final p in purchases) {
      computedPurchase += p.grandTotal ?? p.totalAmount ?? p.amount ?? 0.0;
    }

    double computedSell = 0.0;
    for (final s in sales) {
      computedSell += s.saleAmount ?? 0.0;
    }

    double computedDue = computedPurchase - computedSell;
    if (computedDue < 0) computedDue = 0.0;

    double computedGoldSellWeight = 0.0;
    for (final s in sales) {
      computedGoldSellWeight += s.totalGrossWeight ?? 0.0;
    }

    // Map stats from backend keys
    final double? totalPurchaseVal = _toDouble(json['totalPurchaseAmount']) ?? _toDouble(json['totalPurchase']);
    final int? purchaseCountVal = json['totalPurchaseCount'] ?? json['purchaseTransactionsCount'];
    
    final double? totalSaleVal = _toDouble(json['totalSaleAmount']) ?? _toDouble(json['totalSell']);
    final int? saleCountVal = json['totalSaleCount'] ?? json['sellTransactionsCount'];

    int? apiDueCount = json['totalDueCount'];
    if (apiDueCount == null && json['persons'] is List && (json['persons'] as List).isNotEmpty) {
      final firstPerson = (json['persons'] as List)[0];
      if (firstPerson is Map) {
        apiDueCount = firstPerson['totalDueCount'];
      }
    }

    final double? totalDueVal = _toDouble(json['totalLoanDue']) ?? _toDouble(json['totalDue']);
    final int? dueCountVal = apiDueCount ?? json['totalLoanCount'] ?? json['duePaymentsCount'];

    return Customer(
      id: json['id'],
      name: parsedName,
      phoneNumber: parsedPhone,
      createdBy: json['createdBy'],
      createdByName: json['createdByName'] ?? json['createdByUserName'],
      createdAt: json['createdDate'] ?? json['createdAt'] ?? json['purchaseDate'],
      totalPurchase: totalPurchaseVal ?? computedPurchase,
      purchaseTransactionsCount: purchaseCountVal ?? purchases.length,
      totalSell: totalSaleVal ?? computedSell,
      sellTransactionsCount: saleCountVal ?? sales.length,
      totalDue: totalDueVal ?? computedDue,
      duePaymentsCount: dueCountVal ?? (computedDue > 0 ? 1 : 0),
      totalGoldSellWeight: _toDouble(json['totalGoldSellWeight']) ?? computedGoldSellWeight,
      goldSellTransactionsCount: json['goldSellTransactionsCount'] ?? sales.length,
      totalReceivedAmount: _toDouble(json['totalReceivedAmount']) ?? computedSell,
      lastSellDate: json['lastSellDate'] ?? (sales.isNotEmpty ? sales.first.saleDate : null),
      purchaseHistory: purchases,
      sellHistory: sales,
      loans: parsedLoans,
      paymentUpdates: parsedPaymentUpdates,
      persons: parsedPersons,
      dues: parsedDues,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

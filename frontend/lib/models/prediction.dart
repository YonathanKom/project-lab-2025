import 'package:intl/intl.dart';

enum PredictionReason {
  frequentlyBought,
  householdFavorite,
  recentlyPurchased,
  seasonal,
  complementary;

  String get displayName {
    switch (this) {
      case PredictionReason.frequentlyBought:
        return 'Frequently Bought';
      case PredictionReason.householdFavorite:
        return 'Household Favorite';
      case PredictionReason.recentlyPurchased:
        return 'Due for Replenishment';
      case PredictionReason.seasonal:
        return 'Seasonal Item';
      case PredictionReason.complementary:
        return 'Goes Well With';
    }
  }

  static PredictionReason fromString(String value) {
    switch (value) {
      case 'frequently_bought':
        return PredictionReason.frequentlyBought;
      case 'household_favorite':
        return PredictionReason.householdFavorite;
      case 'recently_purchased':
        return PredictionReason.recentlyPurchased;
      case 'seasonal':
        return PredictionReason.seasonal;
      case 'complementary':
        return PredictionReason.complementary;
      default:
        return PredictionReason.frequentlyBought;
    }
  }
}

class ItemPrediction {
  final String? itemCode;
  final String itemName;
  final double confidenceScore;
  final PredictionReason reason;
  final String reasonDetail;
  final DateTime? lastPurchased;
  final int purchaseCount;
  final double avgQuantity;
  final int suggestedQuantity;
  final double? currentPrice;
  final String? storeName;
  final String? chainName;

  ItemPrediction({
    this.itemCode,
    required this.itemName,
    required this.confidenceScore,
    required this.reason,
    required this.reasonDetail,
    this.lastPurchased,
    required this.purchaseCount,
    required this.avgQuantity,
    required this.suggestedQuantity,
    this.currentPrice,
    this.storeName,
    this.chainName,
  });

  factory ItemPrediction.fromJson(Map<String, dynamic> json) {
    return ItemPrediction(
      itemCode: json['item_code'],
      itemName: json['item_name'],
      confidenceScore: json['confidence_score'].toDouble(),
      reason: PredictionReason.fromString(json['reason']),
      reasonDetail: json['reason_detail'],
      lastPurchased: json['last_purchased'] != null
          ? DateTime.parse(json['last_purchased'])
          : null,
      purchaseCount: json['purchase_count'],
      avgQuantity: json['avg_quantity'].toDouble(),
      suggestedQuantity: json['suggested_quantity'],
      currentPrice: json['current_price']?.toDouble(),
      storeName: json['store_name'],
      chainName: json['chain_name'],
    );
  }

  String get priceDisplay {
    if (currentPrice == null) return '';
    return '₪${currentPrice!.toStringAsFixed(2)}';
  }

  String get storeDisplay {
    if (chainName == null) return '';
    return storeName != null ? '$chainName - $storeName' : chainName!;
  }

  String get lastPurchasedDisplay {
    if (lastPurchased == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastPurchased!);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} weeks ago';
    } else {
      return DateFormat('MMM d').format(lastPurchased!);
    }
  }

  Map<String, dynamic> toShoppingItemData() {
    return {
      'name': itemName,
      'quantity': suggestedQuantity,
      'item_code': itemCode,
      'price': currentPrice,
    };
  }
}

class PredictionsResponse {
  final int? shoppingListId;
  final List<ItemPrediction> predictions;
  final DateTime generatedAt;

  PredictionsResponse({
    this.shoppingListId,
    required this.predictions,
    required this.generatedAt,
  });

  factory PredictionsResponse.fromJson(Map<String, dynamic> json) {
    return PredictionsResponse(
      shoppingListId: json['shopping_list_id'],
      predictions: (json['predictions'] as List)
          .map((e) => ItemPrediction.fromJson(e))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}

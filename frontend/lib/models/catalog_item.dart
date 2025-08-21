class CatalogItem {
  final String itemCode;
  final int itemType;
  final String name;
  final String? manufacturerName;
  final String? manufactureCountry;
  final String? manufacturerDescription;
  final String? unitQty;
  final double? quantity;
  final String? unitOfMeasure;
  final bool isWeighted;
  final double? qtyInPackage;
  final bool allowDiscount;
  final double? currentPrice;
  final String? storeName;
  final String? chainName;
  final DateTime? priceUpdateDate;

  CatalogItem({
    required this.itemCode,
    required this.itemType,
    required this.name,
    this.manufacturerName,
    this.manufactureCountry,
    this.manufacturerDescription,
    this.unitQty,
    this.quantity,
    this.unitOfMeasure,
    required this.isWeighted,
    this.qtyInPackage,
    required this.allowDiscount,
    this.currentPrice,
    this.storeName,
    this.chainName,
    this.priceUpdateDate,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      itemCode: json['item_code'],
      itemType: json['item_type'],
      name: json['name'],
      manufacturerName: json['manufacturer_name'],
      manufactureCountry: json['manufacture_country'],
      manufacturerDescription: json['manufacturer_description'],
      unitQty: json['unit_qty'],
      quantity: json['quantity']?.toDouble(),
      unitOfMeasure: json['unit_of_measure'],
      isWeighted: json['is_weighted'] ?? false,
      qtyInPackage: json['qty_in_package']?.toDouble(),
      allowDiscount: json['allow_discount'] ?? true,
      currentPrice: json['current_price']?.toDouble(),
      storeName: json['store_name'],
      chainName: json['chain_name'],
      priceUpdateDate: json['price_update_date'] != null
          ? DateTime.parse(json['price_update_date'])
          : null,
    );
  }

  String get displayName {
    return name;
  }

  String get priceInfo {
    if (currentPrice == null) return 'Price not available';

    final price = '₪${currentPrice!.toStringAsFixed(2)}';
    if (storeName != null && chainName != null) {
      return '$price at $chainName - $storeName';
    } else if (chainName != null) {
      return '$price at $chainName';
    }
    return price;
  }
}

class Chain {
  final String chainId;
  final String name;
  final String? subChainId;

  Chain({
    required this.chainId,
    required this.name,
    this.subChainId,
  });

  factory Chain.fromJson(Map<String, dynamic> json) {
    return Chain(
      chainId: json['chain_id'],
      name: json['name'],
      subChainId: json['sub_chain_id'],
    );
  }
}

class Store {
  final int id;
  final String storeId;
  final String chainId;
  final String? name;
  final String? address;
  final String? city;
  final String? bikoretNo;
  final Chain? chain;

  Store({
    required this.id,
    required this.storeId,
    required this.chainId,
    this.name,
    this.address,
    this.city,
    this.bikoretNo,
    this.chain,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      storeId: json['store_id'],
      chainId: json['chain_id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      bikoretNo: json['bikoret_no'],
      chain: json['chain'] != null ? Chain.fromJson(json['chain']) : null,
    );
  }

  String get displayName {
    final parts = <String>[];

    if (chain != null) {
      parts.add(chain!.name);
    }

    if (name != null && name!.isNotEmpty) {
      parts.add(name!);
    }

    if (city != null && city!.isNotEmpty) {
      parts.add('($city)');
    } else if (address != null && address!.isNotEmpty) {
      parts.add('($address)');
    }

    return parts.join(' - ');
  }
}

class PriceInfo {
  final int storeId;
  final double price;
  final double? unitPrice;
  final int itemStatus;
  final DateTime priceUpdateDate;

  PriceInfo({
    required this.storeId,
    required this.price,
    this.unitPrice,
    required this.itemStatus,
    required this.priceUpdateDate,
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) {
    return PriceInfo(
      storeId: json['store_id'],
      price: json['price'].toDouble(),
      unitPrice: json['unit_price']?.toDouble(),
      itemStatus: json['item_status'],
      priceUpdateDate: DateTime.parse(json['price_update_date']),
    );
  }
}

class PriceComparison {
  final CatalogItem item;
  final List<PriceInfo> prices;
  final List<Store> stores;

  PriceComparison({
    required this.item,
    required this.prices,
    required this.stores,
  });

  factory PriceComparison.fromJson(Map<String, dynamic> json) {
    return PriceComparison(
      item: CatalogItem.fromJson(json['item']),
      prices: (json['prices'] as List)
          .map((price) => PriceInfo.fromJson(price))
          .toList(),
      stores: (json['stores'] as List)
          .map((store) => Store.fromJson(store))
          .toList(),
    );
  }

  double? get lowestPrice {
    if (prices.isEmpty) return null;
    return prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double? get highestPrice {
    if (prices.isEmpty) return null;
    return prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  double? get averagePrice {
    if (prices.isEmpty) return null;
    final sum = prices.fold<double>(0, (sum, p) => sum + p.price);
    return sum / prices.length;
  }
}

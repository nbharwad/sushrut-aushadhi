import 'package:cloud_firestore/cloud_firestore.dart';

class LabPackageModel {
  final String id;
  final String name;
  final String shortDescription;
  final String category;
  final String sampleType;
  final String iconName;
  final double price;
  final double originalPrice;
  final int tatHours;
  final int fastingHours;
  final int sortOrder;
  final int testCount;
  final bool fastingRequired;
  final bool active;
  final bool popular;
  final List<String> testIds;
  final List<String> testNames;
  final List<String> preparationSteps;
  final List<String> parameters;
  final DateTime createdAt;
  final DateTime updatedAt;

  LabPackageModel({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.category,
    required this.sampleType,
    required this.iconName,
    required this.price,
    required this.originalPrice,
    required this.tatHours,
    required this.fastingHours,
    required this.sortOrder,
    required this.testCount,
    required this.fastingRequired,
    required this.active,
    required this.popular,
    required this.testIds,
    required this.testNames,
    required this.preparationSteps,
    required this.parameters,
    required this.createdAt,
    required this.updatedAt,
  });

  double get discountPercent =>
      originalPrice > price && originalPrice > 0
          ? ((originalPrice - price) / originalPrice * 100).roundToDouble()
          : 0;

  bool get hasDiscount => originalPrice > price;

  String get tatDisplay {
    if (tatHours < 24) return '${tatHours}h';
    final days = tatHours ~/ 24;
    return '$days day${days > 1 ? 's' : ''}';
  }

  factory LabPackageModel.fromFirestore(Map<String, dynamic> data, String id) {
    int toInt(dynamic value, [int defaultVal = 0]) {
      if (value == null) return defaultVal;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultVal;
      return defaultVal;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    List<String> toStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e?.toString() ?? '').toList();
      return [];
    }

    return LabPackageModel(
      id: id,
      name: data['name']?.toString() ?? '',
      shortDescription: data['shortDescription']?.toString() ?? '',
      category: data['category']?.toString() ?? 'popular',
      sampleType: data['sampleType']?.toString() ?? 'Blood',
      iconName: data['iconName']?.toString() ?? 'biotech',
      price: toDouble(data['price']),
      originalPrice: toDouble(data['originalPrice']),
      tatHours: toInt(data['tatHours'], 24),
      fastingHours: toInt(data['fastingHours']),
      sortOrder: toInt(data['sortOrder']),
      testCount: toInt(data['testCount']),
      fastingRequired: data['fastingRequired'] ?? false,
      active: data['active'] ?? true,
      popular: data['popular'] ?? false,
      testIds: toStringList(data['testIds']),
      testNames: toStringList(data['testNames']),
      preparationSteps: toStringList(data['preparationSteps']),
      parameters: toStringList(data['parameters']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'category': category,
      'sampleType': sampleType,
      'iconName': iconName,
      'price': price,
      'originalPrice': originalPrice,
      'tatHours': tatHours,
      'fastingHours': fastingHours,
      'sortOrder': sortOrder,
      'testCount': testCount,
      'fastingRequired': fastingRequired,
      'active': active,
      'popular': popular,
      'testIds': testIds,
      'testNames': testNames,
      'preparationSteps': preparationSteps,
      'parameters': parameters,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LabPackageModel copyWith({
    String? id,
    String? name,
    String? shortDescription,
    String? category,
    String? sampleType,
    String? iconName,
    double? price,
    double? originalPrice,
    int? tatHours,
    int? fastingHours,
    int? sortOrder,
    int? testCount,
    bool? fastingRequired,
    bool? active,
    bool? popular,
    List<String>? testIds,
    List<String>? testNames,
    List<String>? preparationSteps,
    List<String>? parameters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabPackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      sampleType: sampleType ?? this.sampleType,
      iconName: iconName ?? this.iconName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      tatHours: tatHours ?? this.tatHours,
      fastingHours: fastingHours ?? this.fastingHours,
      sortOrder: sortOrder ?? this.sortOrder,
      testCount: testCount ?? this.testCount,
      fastingRequired: fastingRequired ?? this.fastingRequired,
      active: active ?? this.active,
      popular: popular ?? this.popular,
      testIds: testIds ?? this.testIds,
      testNames: testNames ?? this.testNames,
      preparationSteps: preparationSteps ?? this.preparationSteps,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

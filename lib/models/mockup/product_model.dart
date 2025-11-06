import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductResponse {
  final List<Product> products;
  final int total;
  final int offset;
  final int limit;

  ProductResponse({
    required this.products,
    required this.total,
    required this.offset,
    required this.limit,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductResponseToJson(this);
}

@JsonSerializable()
class Product {
  final int id;
  final int? main_category_id;
  final String? type;
  final String? type_name;
  final String? title;
  final String? brand;
  final String? model;
  final String? image;
  final List<Variant>? variants;
  final String? description;
  final int? variant_count;
  final String? currency;
  final List<ProductFile>? files;
  final List<ProductOption>? options;
  final bool? is_discontinued;
  final double? avg_fulfillment_time;
  final List<Technique>? techniques;
  final String? origin_country;

  Product({
    required this.id,
    this.main_category_id,
    this.type,
    this.type_name,
    this.title,
    this.brand,
    this.model,
    this.image,
    this.variants,
    this.description,
    this.variant_count,
    this.currency,
    this.files,
    this.options,
    this.is_discontinued,
    this.avg_fulfillment_time,
    this.techniques,
    this.origin_country,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable()
class Variant {
  final int id;
  final int? product_id;
  final String? name;
  final String? size;
  final String? color;
  final String? color_code;
  final String? color_code2;
  final String?
  retail_price; // Changed from double? to String? since API returns string
  final String? currency;
  final String? image;
  final bool? in_stock;
  final Map<String, dynamic>? availability_regions;
  final List<AvailabilityStatus>? availability_status;
  final List<Material>? material;

  Variant({
    required this.id,
    this.product_id,
    this.name,
    this.size,
    this.color,
    this.color_code,
    this.color_code2,
    this.retail_price,
    this.currency,
    this.image,
    this.in_stock,
    this.availability_regions,
    this.availability_status,
    this.material,
  });

  factory Variant.fromJson(Map<String, dynamic> json) =>
      _$VariantFromJson(json);

  Map<String, dynamic> toJson() => _$VariantToJson(this);
}

@JsonSerializable()
class SyncProduct {
  final int id;
  final String? title;
  final int? sync_product_id;
  final String? thumbnail_url;
  final List<SyncVariant>? variants;

  SyncProduct({
    required this.id,
    this.title,
    this.sync_product_id,
    this.thumbnail_url,
    this.variants,
  });

  factory SyncProduct.fromJson(Map<String, dynamic> json) =>
      _$SyncProductFromJson(json);

  Map<String, dynamic> toJson() => _$SyncProductToJson(this);
}

@JsonSerializable()
class SyncVariant {
  final int id;
  final String? name;
  final String? size;
  final String? color;
  final String? color_code;
  final String? retail_price; // Changed from double? to String?
  final String? currency;
  final String? image;
  final bool? in_stock;

  SyncVariant({
    required this.id,
    this.name,
    this.size,
    this.color,
    this.color_code,
    this.retail_price,
    this.currency,
    this.image,
    this.in_stock,
  });

  factory SyncVariant.fromJson(Map<String, dynamic> json) =>
      _$SyncVariantFromJson(json);

  Map<String, dynamic> toJson() => _$SyncVariantToJson(this);
}

@JsonSerializable()
class ProductFile {
  final String id;
  final String? type;
  final String? title;
  final String? additional_price;
  final List<FileOption>? options;

  ProductFile({
    required this.id,
    this.type,
    this.title,
    this.additional_price,
    this.options,
  });

  factory ProductFile.fromJson(Map<String, dynamic> json) =>
      _$ProductFileFromJson(json);

  Map<String, dynamic> toJson() => _$ProductFileToJson(this);
}

@JsonSerializable()
class FileOption {
  final String id;
  final String? type;
  final String? title;
  final dynamic additional_price;

  FileOption({required this.id, this.type, this.title, this.additional_price});

  factory FileOption.fromJson(Map<String, dynamic> json) =>
      _$FileOptionFromJson(json);

  Map<String, dynamic> toJson() => _$FileOptionToJson(this);
}

@JsonSerializable()
class ProductOption {
  final String id;
  final String? title;
  final String? type;
  final dynamic values;
  final String? additional_price;
  final Map<String, dynamic>? additional_price_breakdown;

  ProductOption({
    required this.id,
    this.title,
    this.type,
    this.values,
    this.additional_price,
    this.additional_price_breakdown,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionFromJson(json);

  Map<String, dynamic> toJson() => _$ProductOptionToJson(this);
}

@JsonSerializable()
class Technique {
  final String key;
  final String? display_name;
  final bool? is_default;

  Technique({required this.key, this.display_name, this.is_default});

  factory Technique.fromJson(Map<String, dynamic> json) =>
      _$TechniqueFromJson(json);

  Map<String, dynamic> toJson() => _$TechniqueToJson(this);
}

@JsonSerializable()
class AvailabilityStatus {
  final String region;
  final String status;

  AvailabilityStatus({required this.region, required this.status});

  factory AvailabilityStatus.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityStatusFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityStatusToJson(this);
}

@JsonSerializable()
class Material {
  final String name;
  final int? percentage;

  Material({required this.name, this.percentage});

  factory Material.fromJson(Map<String, dynamic> json) =>
      _$MaterialFromJson(json);

  Map<String, dynamic> toJson() => _$MaterialToJson(this);
}

@JsonSerializable()
class StoreProductResponse {
  final List<SyncProduct> result;
  final int total;
  final int offset;
  final int limit;

  StoreProductResponse({
    required this.result,
    required this.total,
    required this.offset,
    required this.limit,
  });

  factory StoreProductResponse.fromJson(Map<String, dynamic> json) =>
      _$StoreProductResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StoreProductResponseToJson(this);
}

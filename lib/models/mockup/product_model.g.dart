// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductResponse _$ProductResponseFromJson(Map<String, dynamic> json) =>
    ProductResponse(
      products: (json['products'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$ProductResponseToJson(ProductResponse instance) =>
    <String, dynamic>{
      'products': instance.products,
      'total': instance.total,
      'offset': instance.offset,
      'limit': instance.limit,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['id'] as num).toInt(),
  main_category_id: (json['main_category_id'] as num?)?.toInt(),
  type: json['type'] as String?,
  type_name: json['type_name'] as String?,
  title: json['title'] as String?,
  brand: json['brand'] as String?,
  model: json['model'] as String?,
  image: json['image'] as String?,
  variants: (json['variants'] as List<dynamic>?)
      ?.map((e) => Variant.fromJson(e as Map<String, dynamic>))
      .toList(),
  description: json['description'] as String?,
  variant_count: (json['variant_count'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  files: (json['files'] as List<dynamic>?)
      ?.map((e) => ProductFile.fromJson(e as Map<String, dynamic>))
      .toList(),
  options: (json['options'] as List<dynamic>?)
      ?.map((e) => ProductOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  is_discontinued: json['is_discontinued'] as bool?,
  avg_fulfillment_time: (json['avg_fulfillment_time'] as num?)?.toDouble(),
  techniques: (json['techniques'] as List<dynamic>?)
      ?.map((e) => Technique.fromJson(e as Map<String, dynamic>))
      .toList(),
  origin_country: json['origin_country'] as String?,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'main_category_id': instance.main_category_id,
  'type': instance.type,
  'type_name': instance.type_name,
  'title': instance.title,
  'brand': instance.brand,
  'model': instance.model,
  'image': instance.image,
  'variants': instance.variants,
  'description': instance.description,
  'variant_count': instance.variant_count,
  'currency': instance.currency,
  'files': instance.files,
  'options': instance.options,
  'is_discontinued': instance.is_discontinued,
  'avg_fulfillment_time': instance.avg_fulfillment_time,
  'techniques': instance.techniques,
  'origin_country': instance.origin_country,
};

Variant _$VariantFromJson(Map<String, dynamic> json) => Variant(
  id: (json['id'] as num).toInt(),
  product_id: (json['product_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  size: json['size'] as String?,
  color: json['color'] as String?,
  color_code: json['color_code'] as String?,
  color_code2: json['color_code2'] as String?,
  retail_price: json['retail_price'] as String?,
  currency: json['currency'] as String?,
  image: json['image'] as String?,
  in_stock: json['in_stock'] as bool?,
  availability_regions: json['availability_regions'] as Map<String, dynamic>?,
  availability_status: (json['availability_status'] as List<dynamic>?)
      ?.map((e) => AvailabilityStatus.fromJson(e as Map<String, dynamic>))
      .toList(),
  material: (json['material'] as List<dynamic>?)
      ?.map((e) => Material.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VariantToJson(Variant instance) => <String, dynamic>{
  'id': instance.id,
  'product_id': instance.product_id,
  'name': instance.name,
  'size': instance.size,
  'color': instance.color,
  'color_code': instance.color_code,
  'color_code2': instance.color_code2,
  'retail_price': instance.retail_price,
  'currency': instance.currency,
  'image': instance.image,
  'in_stock': instance.in_stock,
  'availability_regions': instance.availability_regions,
  'availability_status': instance.availability_status,
  'material': instance.material,
};

SyncProduct _$SyncProductFromJson(Map<String, dynamic> json) => SyncProduct(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String?,
  sync_product_id: (json['sync_product_id'] as num?)?.toInt(),
  thumbnail_url: json['thumbnail_url'] as String?,
  variants: (json['variants'] as List<dynamic>?)
      ?.map((e) => SyncVariant.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SyncProductToJson(SyncProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'sync_product_id': instance.sync_product_id,
      'thumbnail_url': instance.thumbnail_url,
      'variants': instance.variants,
    };

SyncVariant _$SyncVariantFromJson(Map<String, dynamic> json) => SyncVariant(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  size: json['size'] as String?,
  color: json['color'] as String?,
  color_code: json['color_code'] as String?,
  retail_price: json['retail_price'] as String?,
  currency: json['currency'] as String?,
  image: json['image'] as String?,
  in_stock: json['in_stock'] as bool?,
);

Map<String, dynamic> _$SyncVariantToJson(SyncVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
      'color': instance.color,
      'color_code': instance.color_code,
      'retail_price': instance.retail_price,
      'currency': instance.currency,
      'image': instance.image,
      'in_stock': instance.in_stock,
    };

ProductFile _$ProductFileFromJson(Map<String, dynamic> json) => ProductFile(
  id: json['id'] as String,
  type: json['type'] as String?,
  title: json['title'] as String?,
  additional_price: json['additional_price'] as String?,
  options: (json['options'] as List<dynamic>?)
      ?.map((e) => FileOption.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProductFileToJson(ProductFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'additional_price': instance.additional_price,
      'options': instance.options,
    };

FileOption _$FileOptionFromJson(Map<String, dynamic> json) => FileOption(
  id: json['id'] as String,
  type: json['type'] as String?,
  title: json['title'] as String?,
  additional_price: json['additional_price'],
);

Map<String, dynamic> _$FileOptionToJson(FileOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'additional_price': instance.additional_price,
    };

ProductOption _$ProductOptionFromJson(Map<String, dynamic> json) =>
    ProductOption(
      id: json['id'] as String,
      title: json['title'] as String?,
      type: json['type'] as String?,
      values: json['values'],
      additional_price: json['additional_price'] as String?,
      additional_price_breakdown:
          json['additional_price_breakdown'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProductOptionToJson(ProductOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'values': instance.values,
      'additional_price': instance.additional_price,
      'additional_price_breakdown': instance.additional_price_breakdown,
    };

Technique _$TechniqueFromJson(Map<String, dynamic> json) => Technique(
  key: json['key'] as String,
  display_name: json['display_name'] as String?,
  is_default: json['is_default'] as bool?,
);

Map<String, dynamic> _$TechniqueToJson(Technique instance) => <String, dynamic>{
  'key': instance.key,
  'display_name': instance.display_name,
  'is_default': instance.is_default,
};

AvailabilityStatus _$AvailabilityStatusFromJson(Map<String, dynamic> json) =>
    AvailabilityStatus(
      region: json['region'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$AvailabilityStatusToJson(AvailabilityStatus instance) =>
    <String, dynamic>{'region': instance.region, 'status': instance.status};

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
  name: json['name'] as String,
  percentage: (json['percentage'] as num?)?.toInt(),
);

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
  'name': instance.name,
  'percentage': instance.percentage,
};

StoreProductResponse _$StoreProductResponseFromJson(
  Map<String, dynamic> json,
) => StoreProductResponse(
  result: (json['result'] as List<dynamic>)
      .map((e) => SyncProduct.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  offset: (json['offset'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$StoreProductResponseToJson(
  StoreProductResponse instance,
) => <String, dynamic>{
  'result': instance.result,
  'total': instance.total,
  'offset': instance.offset,
  'limit': instance.limit,
};

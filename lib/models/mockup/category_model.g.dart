// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: (json['id'] as num).toInt(),
      parent_id: (json['parent_id'] as num?)?.toInt(),
      image_url: json['image_url'] as String?,
      size: json['size'] as String?,
      title: json['title'] as String,
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent_id': instance.parent_id,
      'image_url': instance.image_url,
      'size': instance.size,
      'title': instance.title,
    };

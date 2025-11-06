import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel {
  final int id;
  final int? parent_id;
  final String? image_url;
  final String? size;
  final String title;

  CategoryModel({
    required this.id,
    this.parent_id,
    this.image_url,
    this.size,
    required this.title,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}

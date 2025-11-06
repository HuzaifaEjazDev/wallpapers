// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printfile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrintfileResponse _$PrintfileResponseFromJson(Map<String, dynamic> json) =>
    PrintfileResponse(
      code: (json['code'] as num).toInt(),
      result: PrintfileResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PrintfileResponseToJson(PrintfileResponse instance) =>
    <String, dynamic>{'code': instance.code, 'result': instance.result};

PrintfileResult _$PrintfileResultFromJson(Map<String, dynamic> json) =>
    PrintfileResult(
      product_id: (json['product_id'] as num).toInt(),
      available_placements: Map<String, String>.from(
        json['available_placements'] as Map,
      ),
      printfiles: (json['printfiles'] as List<dynamic>)
          .map((e) => Printfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      variant_printfiles: (json['variant_printfiles'] as List<dynamic>)
          .map((e) => VariantPrintfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      option_groups: (json['option_groups'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PrintfileResultToJson(PrintfileResult instance) =>
    <String, dynamic>{
      'product_id': instance.product_id,
      'available_placements': instance.available_placements,
      'printfiles': instance.printfiles,
      'variant_printfiles': instance.variant_printfiles,
      'option_groups': instance.option_groups,
      'options': instance.options,
    };

Printfile _$PrintfileFromJson(Map<String, dynamic> json) => Printfile(
  printfile_id: (json['printfile_id'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  dpi: (json['dpi'] as num).toInt(),
  fill_mode: json['fill_mode'] as String,
  can_rotate: json['can_rotate'] as bool,
);

Map<String, dynamic> _$PrintfileToJson(Printfile instance) => <String, dynamic>{
  'printfile_id': instance.printfile_id,
  'width': instance.width,
  'height': instance.height,
  'dpi': instance.dpi,
  'fill_mode': instance.fill_mode,
  'can_rotate': instance.can_rotate,
};

VariantPrintfile _$VariantPrintfileFromJson(Map<String, dynamic> json) =>
    VariantPrintfile(
      variant_id: (json['variant_id'] as num).toInt(),
      placements: Map<String, int>.from(json['placements'] as Map),
    );

Map<String, dynamic> _$VariantPrintfileToJson(VariantPrintfile instance) =>
    <String, dynamic>{
      'variant_id': instance.variant_id,
      'placements': instance.placements,
    };

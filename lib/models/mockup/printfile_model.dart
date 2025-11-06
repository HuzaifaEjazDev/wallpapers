import 'package:json_annotation/json_annotation.dart';

part 'printfile_model.g.dart';

@JsonSerializable()
class PrintfileResponse {
  final int code;
  final PrintfileResult result;

  PrintfileResponse({required this.code, required this.result});

  factory PrintfileResponse.fromJson(Map<String, dynamic> json) =>
      _$PrintfileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PrintfileResponseToJson(this);
}

@JsonSerializable()
class PrintfileResult {
  final int product_id;
  final Map<String, String> available_placements;
  final List<Printfile> printfiles;
  final List<VariantPrintfile> variant_printfiles;
  final List<String> option_groups;
  final List<String> options;

  PrintfileResult({
    required this.product_id,
    required this.available_placements,
    required this.printfiles,
    required this.variant_printfiles,
    required this.option_groups,
    required this.options,
  });

  factory PrintfileResult.fromJson(Map<String, dynamic> json) =>
      _$PrintfileResultFromJson(json);

  Map<String, dynamic> toJson() => _$PrintfileResultToJson(this);
}

@JsonSerializable()
class Printfile {
  final int printfile_id;
  final int width;
  final int height;
  final int dpi;
  final String fill_mode;
  final bool can_rotate;

  Printfile({
    required this.printfile_id,
    required this.width,
    required this.height,
    required this.dpi,
    required this.fill_mode,
    required this.can_rotate,
  });

  factory Printfile.fromJson(Map<String, dynamic> json) =>
      _$PrintfileFromJson(json);

  Map<String, dynamic> toJson() => _$PrintfileToJson(this);
}

@JsonSerializable()
class VariantPrintfile {
  final int variant_id;
  final Map<String, int> placements;

  VariantPrintfile({required this.variant_id, required this.placements});

  factory VariantPrintfile.fromJson(Map<String, dynamic> json) =>
      _$VariantPrintfileFromJson(json);

  Map<String, dynamic> toJson() => _$VariantPrintfileToJson(this);
}

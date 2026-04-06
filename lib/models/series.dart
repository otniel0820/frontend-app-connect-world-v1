import 'package:freezed_annotation/freezed_annotation.dart';

part 'series.freezed.dart';
part 'series.g.dart';

@freezed
class Series with _$Series {
  const factory Series({
    required String id,
    required String title,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    String? genre,
    String? releaseYear,
    double? rating,
    int? seasons,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
}

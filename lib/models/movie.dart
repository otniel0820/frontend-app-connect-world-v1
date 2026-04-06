import 'package:freezed_annotation/freezed_annotation.dart';

part 'movie.freezed.dart';
part 'movie.g.dart';

@freezed
class Movie with _$Movie {
  const factory Movie({
    required String id,
    required String title,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    String? genre,
    String? releaseYear,
    double? rating,
    int? durationMinutes,
  }) = _Movie;

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
}

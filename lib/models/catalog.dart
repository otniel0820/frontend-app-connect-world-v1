import 'package:freezed_annotation/freezed_annotation.dart';

import 'channel.dart';
import 'movie.dart';
import 'series.dart';

part 'catalog.freezed.dart';
part 'catalog.g.dart';

@freezed
class Catalog with _$Catalog {
  const factory Catalog({
    @Default([]) List<Channel> channels,
    @Default([]) List<Movie> movies,
    @Default([]) List<Series> series,
    @Default([]) List<Movie> featured,
  }) = _Catalog;

  factory Catalog.fromJson(Map<String, dynamic> json) => _$CatalogFromJson(json);
}

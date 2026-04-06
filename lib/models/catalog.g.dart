// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CatalogImpl _$$CatalogImplFromJson(Map<String, dynamic> json) =>
    _$CatalogImpl(
      channels: (json['channels'] as List<dynamic>?)
              ?.map((e) => Channel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      movies: (json['movies'] as List<dynamic>?)
              ?.map((e) => Movie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      series: (json['series'] as List<dynamic>?)
              ?.map((e) => Series.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      featured: (json['featured'] as List<dynamic>?)
              ?.map((e) => Movie.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CatalogImplToJson(_$CatalogImpl instance) =>
    <String, dynamic>{
      'channels': instance.channels,
      'movies': instance.movies,
      'series': instance.series,
      'featured': instance.featured,
    };

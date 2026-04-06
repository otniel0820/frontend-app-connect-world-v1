// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MovieImpl _$$MovieImplFromJson(Map<String, dynamic> json) => _$MovieImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String?,
      backdropUrl: json['backdropUrl'] as String?,
      overview: json['overview'] as String?,
      genre: json['genre'] as String?,
      releaseYear: json['releaseYear'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$MovieImplToJson(_$MovieImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'posterUrl': instance.posterUrl,
      'backdropUrl': instance.backdropUrl,
      'overview': instance.overview,
      'genre': instance.genre,
      'releaseYear': instance.releaseYear,
      'rating': instance.rating,
      'durationMinutes': instance.durationMinutes,
    };

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Series _$SeriesFromJson(Map<String, dynamic> json) {
  return _Series.fromJson(json);
}

/// @nodoc
mixin _$Series {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get posterUrl => throw _privateConstructorUsedError;
  String? get backdropUrl => throw _privateConstructorUsedError;
  String? get overview => throw _privateConstructorUsedError;
  String? get genre => throw _privateConstructorUsedError;
  String? get releaseYear => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  int? get seasons => throw _privateConstructorUsedError;

  /// Serializes this Series to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeriesCopyWith<Series> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeriesCopyWith<$Res> {
  factory $SeriesCopyWith(Series value, $Res Function(Series) then) =
      _$SeriesCopyWithImpl<$Res, Series>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? posterUrl,
      String? backdropUrl,
      String? overview,
      String? genre,
      String? releaseYear,
      double? rating,
      int? seasons});
}

/// @nodoc
class _$SeriesCopyWithImpl<$Res, $Val extends Series>
    implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? posterUrl = freezed,
    Object? backdropUrl = freezed,
    Object? overview = freezed,
    Object? genre = freezed,
    Object? releaseYear = freezed,
    Object? rating = freezed,
    Object? seasons = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      posterUrl: freezed == posterUrl
          ? _value.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      backdropUrl: freezed == backdropUrl
          ? _value.backdropUrl
          : backdropUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      overview: freezed == overview
          ? _value.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String?,
      genre: freezed == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseYear: freezed == releaseYear
          ? _value.releaseYear
          : releaseYear // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      seasons: freezed == seasons
          ? _value.seasons
          : seasons // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SeriesImplCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$$SeriesImplCopyWith(
          _$SeriesImpl value, $Res Function(_$SeriesImpl) then) =
      __$$SeriesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? posterUrl,
      String? backdropUrl,
      String? overview,
      String? genre,
      String? releaseYear,
      double? rating,
      int? seasons});
}

/// @nodoc
class __$$SeriesImplCopyWithImpl<$Res>
    extends _$SeriesCopyWithImpl<$Res, _$SeriesImpl>
    implements _$$SeriesImplCopyWith<$Res> {
  __$$SeriesImplCopyWithImpl(
      _$SeriesImpl _value, $Res Function(_$SeriesImpl) _then)
      : super(_value, _then);

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? posterUrl = freezed,
    Object? backdropUrl = freezed,
    Object? overview = freezed,
    Object? genre = freezed,
    Object? releaseYear = freezed,
    Object? rating = freezed,
    Object? seasons = freezed,
  }) {
    return _then(_$SeriesImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      posterUrl: freezed == posterUrl
          ? _value.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      backdropUrl: freezed == backdropUrl
          ? _value.backdropUrl
          : backdropUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      overview: freezed == overview
          ? _value.overview
          : overview // ignore: cast_nullable_to_non_nullable
              as String?,
      genre: freezed == genre
          ? _value.genre
          : genre // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseYear: freezed == releaseYear
          ? _value.releaseYear
          : releaseYear // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      seasons: freezed == seasons
          ? _value.seasons
          : seasons // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SeriesImpl implements _Series {
  const _$SeriesImpl(
      {required this.id,
      required this.title,
      this.posterUrl,
      this.backdropUrl,
      this.overview,
      this.genre,
      this.releaseYear,
      this.rating,
      this.seasons});

  factory _$SeriesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeriesImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? posterUrl;
  @override
  final String? backdropUrl;
  @override
  final String? overview;
  @override
  final String? genre;
  @override
  final String? releaseYear;
  @override
  final double? rating;
  @override
  final int? seasons;

  @override
  String toString() {
    return 'Series(id: $id, title: $title, posterUrl: $posterUrl, backdropUrl: $backdropUrl, overview: $overview, genre: $genre, releaseYear: $releaseYear, rating: $rating, seasons: $seasons)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeriesImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.backdropUrl, backdropUrl) ||
                other.backdropUrl == backdropUrl) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.genre, genre) || other.genre == genre) &&
            (identical(other.releaseYear, releaseYear) ||
                other.releaseYear == releaseYear) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.seasons, seasons) || other.seasons == seasons));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, posterUrl,
      backdropUrl, overview, genre, releaseYear, rating, seasons);

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeriesImplCopyWith<_$SeriesImpl> get copyWith =>
      __$$SeriesImplCopyWithImpl<_$SeriesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeriesImplToJson(
      this,
    );
  }
}

abstract class _Series implements Series {
  const factory _Series(
      {required final String id,
      required final String title,
      final String? posterUrl,
      final String? backdropUrl,
      final String? overview,
      final String? genre,
      final String? releaseYear,
      final double? rating,
      final int? seasons}) = _$SeriesImpl;

  factory _Series.fromJson(Map<String, dynamic> json) = _$SeriesImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get posterUrl;
  @override
  String? get backdropUrl;
  @override
  String? get overview;
  @override
  String? get genre;
  @override
  String? get releaseYear;
  @override
  double? get rating;
  @override
  int? get seasons;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeriesImplCopyWith<_$SeriesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

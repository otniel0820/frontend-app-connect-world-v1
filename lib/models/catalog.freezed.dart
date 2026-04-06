// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Catalog _$CatalogFromJson(Map<String, dynamic> json) {
  return _Catalog.fromJson(json);
}

/// @nodoc
mixin _$Catalog {
  List<Channel> get channels => throw _privateConstructorUsedError;
  List<Movie> get movies => throw _privateConstructorUsedError;
  List<Series> get series => throw _privateConstructorUsedError;
  List<Movie> get featured => throw _privateConstructorUsedError;

  /// Serializes this Catalog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Catalog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CatalogCopyWith<Catalog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CatalogCopyWith<$Res> {
  factory $CatalogCopyWith(Catalog value, $Res Function(Catalog) then) =
      _$CatalogCopyWithImpl<$Res, Catalog>;
  @useResult
  $Res call(
      {List<Channel> channels,
      List<Movie> movies,
      List<Series> series,
      List<Movie> featured});
}

/// @nodoc
class _$CatalogCopyWithImpl<$Res, $Val extends Catalog>
    implements $CatalogCopyWith<$Res> {
  _$CatalogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Catalog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channels = null,
    Object? movies = null,
    Object? series = null,
    Object? featured = null,
  }) {
    return _then(_value.copyWith(
      channels: null == channels
          ? _value.channels
          : channels // ignore: cast_nullable_to_non_nullable
              as List<Channel>,
      movies: null == movies
          ? _value.movies
          : movies // ignore: cast_nullable_to_non_nullable
              as List<Movie>,
      series: null == series
          ? _value.series
          : series // ignore: cast_nullable_to_non_nullable
              as List<Series>,
      featured: null == featured
          ? _value.featured
          : featured // ignore: cast_nullable_to_non_nullable
              as List<Movie>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CatalogImplCopyWith<$Res> implements $CatalogCopyWith<$Res> {
  factory _$$CatalogImplCopyWith(
          _$CatalogImpl value, $Res Function(_$CatalogImpl) then) =
      __$$CatalogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Channel> channels,
      List<Movie> movies,
      List<Series> series,
      List<Movie> featured});
}

/// @nodoc
class __$$CatalogImplCopyWithImpl<$Res>
    extends _$CatalogCopyWithImpl<$Res, _$CatalogImpl>
    implements _$$CatalogImplCopyWith<$Res> {
  __$$CatalogImplCopyWithImpl(
      _$CatalogImpl _value, $Res Function(_$CatalogImpl) _then)
      : super(_value, _then);

  /// Create a copy of Catalog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channels = null,
    Object? movies = null,
    Object? series = null,
    Object? featured = null,
  }) {
    return _then(_$CatalogImpl(
      channels: null == channels
          ? _value._channels
          : channels // ignore: cast_nullable_to_non_nullable
              as List<Channel>,
      movies: null == movies
          ? _value._movies
          : movies // ignore: cast_nullable_to_non_nullable
              as List<Movie>,
      series: null == series
          ? _value._series
          : series // ignore: cast_nullable_to_non_nullable
              as List<Series>,
      featured: null == featured
          ? _value._featured
          : featured // ignore: cast_nullable_to_non_nullable
              as List<Movie>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CatalogImpl implements _Catalog {
  const _$CatalogImpl(
      {final List<Channel> channels = const [],
      final List<Movie> movies = const [],
      final List<Series> series = const [],
      final List<Movie> featured = const []})
      : _channels = channels,
        _movies = movies,
        _series = series,
        _featured = featured;

  factory _$CatalogImpl.fromJson(Map<String, dynamic> json) =>
      _$$CatalogImplFromJson(json);

  final List<Channel> _channels;
  @override
  @JsonKey()
  List<Channel> get channels {
    if (_channels is EqualUnmodifiableListView) return _channels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_channels);
  }

  final List<Movie> _movies;
  @override
  @JsonKey()
  List<Movie> get movies {
    if (_movies is EqualUnmodifiableListView) return _movies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_movies);
  }

  final List<Series> _series;
  @override
  @JsonKey()
  List<Series> get series {
    if (_series is EqualUnmodifiableListView) return _series;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_series);
  }

  final List<Movie> _featured;
  @override
  @JsonKey()
  List<Movie> get featured {
    if (_featured is EqualUnmodifiableListView) return _featured;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_featured);
  }

  @override
  String toString() {
    return 'Catalog(channels: $channels, movies: $movies, series: $series, featured: $featured)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CatalogImpl &&
            const DeepCollectionEquality().equals(other._channels, _channels) &&
            const DeepCollectionEquality().equals(other._movies, _movies) &&
            const DeepCollectionEquality().equals(other._series, _series) &&
            const DeepCollectionEquality().equals(other._featured, _featured));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_channels),
      const DeepCollectionEquality().hash(_movies),
      const DeepCollectionEquality().hash(_series),
      const DeepCollectionEquality().hash(_featured));

  /// Create a copy of Catalog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CatalogImplCopyWith<_$CatalogImpl> get copyWith =>
      __$$CatalogImplCopyWithImpl<_$CatalogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CatalogImplToJson(
      this,
    );
  }
}

abstract class _Catalog implements Catalog {
  const factory _Catalog(
      {final List<Channel> channels,
      final List<Movie> movies,
      final List<Series> series,
      final List<Movie> featured}) = _$CatalogImpl;

  factory _Catalog.fromJson(Map<String, dynamic> json) = _$CatalogImpl.fromJson;

  @override
  List<Channel> get channels;
  @override
  List<Movie> get movies;
  @override
  List<Series> get series;
  @override
  List<Movie> get featured;

  /// Create a copy of Catalog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CatalogImplCopyWith<_$CatalogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

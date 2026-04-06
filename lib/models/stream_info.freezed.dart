// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StreamInfo _$StreamInfoFromJson(Map<String, dynamic> json) {
  return _StreamInfo.fromJson(json);
}

/// @nodoc
mixin _$StreamInfo {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;

  /// Serializes this StreamInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StreamInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StreamInfoCopyWith<StreamInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamInfoCopyWith<$Res> {
  factory $StreamInfoCopyWith(
          StreamInfo value, $Res Function(StreamInfo) then) =
      _$StreamInfoCopyWithImpl<$Res, StreamInfo>;
  @useResult
  $Res call({String id, String url, String? title, String? type});
}

/// @nodoc
class _$StreamInfoCopyWithImpl<$Res, $Val extends StreamInfo>
    implements $StreamInfoCopyWith<$Res> {
  _$StreamInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StreamInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? title = freezed,
    Object? type = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StreamInfoImplCopyWith<$Res>
    implements $StreamInfoCopyWith<$Res> {
  factory _$$StreamInfoImplCopyWith(
          _$StreamInfoImpl value, $Res Function(_$StreamInfoImpl) then) =
      __$$StreamInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String url, String? title, String? type});
}

/// @nodoc
class __$$StreamInfoImplCopyWithImpl<$Res>
    extends _$StreamInfoCopyWithImpl<$Res, _$StreamInfoImpl>
    implements _$$StreamInfoImplCopyWith<$Res> {
  __$$StreamInfoImplCopyWithImpl(
      _$StreamInfoImpl _value, $Res Function(_$StreamInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of StreamInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? title = freezed,
    Object? type = freezed,
  }) {
    return _then(_$StreamInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StreamInfoImpl implements _StreamInfo {
  const _$StreamInfoImpl(
      {required this.id, required this.url, this.title, this.type});

  factory _$StreamInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StreamInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final String? title;
  @override
  final String? type;

  @override
  String toString() {
    return 'StreamInfo(id: $id, url: $url, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StreamInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, url, title, type);

  /// Create a copy of StreamInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StreamInfoImplCopyWith<_$StreamInfoImpl> get copyWith =>
      __$$StreamInfoImplCopyWithImpl<_$StreamInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StreamInfoImplToJson(
      this,
    );
  }
}

abstract class _StreamInfo implements StreamInfo {
  const factory _StreamInfo(
      {required final String id,
      required final String url,
      final String? title,
      final String? type}) = _$StreamInfoImpl;

  factory _StreamInfo.fromJson(Map<String, dynamic> json) =
      _$StreamInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get url;
  @override
  String? get title;
  @override
  String? get type;

  /// Create a copy of StreamInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StreamInfoImplCopyWith<_$StreamInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

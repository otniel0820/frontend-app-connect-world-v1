// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'epg_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EpgItem _$EpgItemFromJson(Map<String, dynamic> json) {
  return _EpgItem.fromJson(json);
}

/// @nodoc
mixin _$EpgItem {
  String get channelId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get start => throw _privateConstructorUsedError;
  DateTime get stop => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this EpgItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EpgItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpgItemCopyWith<EpgItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpgItemCopyWith<$Res> {
  factory $EpgItemCopyWith(EpgItem value, $Res Function(EpgItem) then) =
      _$EpgItemCopyWithImpl<$Res, EpgItem>;
  @useResult
  $Res call(
      {String channelId,
      String title,
      DateTime start,
      DateTime stop,
      String? description});
}

/// @nodoc
class _$EpgItemCopyWithImpl<$Res, $Val extends EpgItem>
    implements $EpgItemCopyWith<$Res> {
  _$EpgItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpgItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? title = null,
    Object? start = null,
    Object? stop = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      channelId: null == channelId
          ? _value.channelId
          : channelId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stop: null == stop
          ? _value.stop
          : stop // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EpgItemImplCopyWith<$Res> implements $EpgItemCopyWith<$Res> {
  factory _$$EpgItemImplCopyWith(
          _$EpgItemImpl value, $Res Function(_$EpgItemImpl) then) =
      __$$EpgItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String channelId,
      String title,
      DateTime start,
      DateTime stop,
      String? description});
}

/// @nodoc
class __$$EpgItemImplCopyWithImpl<$Res>
    extends _$EpgItemCopyWithImpl<$Res, _$EpgItemImpl>
    implements _$$EpgItemImplCopyWith<$Res> {
  __$$EpgItemImplCopyWithImpl(
      _$EpgItemImpl _value, $Res Function(_$EpgItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of EpgItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? title = null,
    Object? start = null,
    Object? stop = null,
    Object? description = freezed,
  }) {
    return _then(_$EpgItemImpl(
      channelId: null == channelId
          ? _value.channelId
          : channelId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stop: null == stop
          ? _value.stop
          : stop // ignore: cast_nullable_to_non_nullable
              as DateTime,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EpgItemImpl implements _EpgItem {
  const _$EpgItemImpl(
      {required this.channelId,
      required this.title,
      required this.start,
      required this.stop,
      this.description});

  factory _$EpgItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpgItemImplFromJson(json);

  @override
  final String channelId;
  @override
  final String title;
  @override
  final DateTime start;
  @override
  final DateTime stop;
  @override
  final String? description;

  @override
  String toString() {
    return 'EpgItem(channelId: $channelId, title: $title, start: $start, stop: $stop, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpgItemImpl &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.stop, stop) || other.stop == stop) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, channelId, title, start, stop, description);

  /// Create a copy of EpgItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpgItemImplCopyWith<_$EpgItemImpl> get copyWith =>
      __$$EpgItemImplCopyWithImpl<_$EpgItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpgItemImplToJson(
      this,
    );
  }
}

abstract class _EpgItem implements EpgItem {
  const factory _EpgItem(
      {required final String channelId,
      required final String title,
      required final DateTime start,
      required final DateTime stop,
      final String? description}) = _$EpgItemImpl;

  factory _EpgItem.fromJson(Map<String, dynamic> json) = _$EpgItemImpl.fromJson;

  @override
  String get channelId;
  @override
  String get title;
  @override
  DateTime get start;
  @override
  DateTime get stop;
  @override
  String? get description;

  /// Create a copy of EpgItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpgItemImplCopyWith<_$EpgItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
